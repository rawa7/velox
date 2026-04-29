import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class WebScraperService {
  /// Normalizes pasted input into a full HTTPS URL for scraping.
  /// Handles path-only Trendyol product slugs (e.g. `name-p-898899085`).
  static String normalizeProductUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    if (s.startsWith('http://') || s.startsWith('https://')) {
      return s;
    }

    // Trendyol product slug: contains "-p-" + numeric id, single path segment
    if (RegExp(r'-p-\d+').hasMatch(s) &&
        !s.contains(' ') &&
        !s.contains('/') &&
        s.length > 8) {
      return 'https://www.trendyol.com/$s';
    }

    if (s.startsWith('//')) {
      return 'https:$s';
    }

    // Path starting with / on known hosts (paste without domain)
    if (s.startsWith('/') && RegExp(r'-p-\d+').hasMatch(s)) {
      return 'https://www.trendyol.com$s';
    }

    return 'https://$s';
  }

  static Future<Map<String, dynamic>> fetchProductDetails(String url) async {
    try {
      url = normalizeProductUrl(url);
      if (url.isEmpty) {
        return {'success': false, 'message': 'Please enter a product link.'};
      }

      // Convert mobile URLs to desktop for better scraping
      url = _convertToDesktopUrl(url);

      final uri = Uri.parse(url);
      
      // Make HTTP request with better headers
      // Do not request Brotli: package:http does not decode "br", and using
      // response.body would UTF-8-decode compressed bytes → FormatException.
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to load page. Status: ${response.statusCode}',
        };
      }

      // Parse HTML
      final document = html_parser.parse(response.body);

      // Extract product details
      final productData = _extractProductData(document, url);

      if (productData['images'].isEmpty) {
        return {
          'success': false,
          'message': 'Could not find product details on this page.',
        };
      }

      return {
        'success': true,
        'data': productData,
        'message': 'Product details fetched successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching product: ${e.toString()}',
      };
    }
  }

  static String _convertToDesktopUrl(String url) {
    // Convert SHEIN mobile to desktop
    if (url.contains('m.shein.com')) {
      url = url.replaceAll('m.shein.com', 'www.shein.com');
    }
    
    // Remove mobile parameters
    if (url.contains('?')) {
      final uri = Uri.parse(url);
      final cleanParams = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        // Keep essential parameters only
        if (!key.contains('mobile') && !key.contains('src_') && !key.contains('page_')) {
          cleanParams[key] = value;
        }
      });
      if (cleanParams.isNotEmpty) {
        url = uri.replace(queryParameters: cleanParams).toString();
      } else {
        url = '${uri.scheme}://${uri.host}${uri.path}';
      }
    }
    
    return url;
  }

  static Map<String, dynamic> _extractProductData(Document document, String baseUrl) {
    Map<String, dynamic> data = {
      'title': null,
      'price': null,
      'currency': null,
      'images': <String>[],
      'description': null,
      'color': null,
      'size': null,
      'good_sn': null,
      'sku': null,
    };

    // Detect site type for specialized extraction
    final siteType = _detectSiteType(baseUrl);

    // Extract from Open Graph meta tags (most reliable)
    data['title'] = _getMetaContent(document, 'og:title') ?? 
                    _getMetaContent(document, 'twitter:title');
    
    data['description'] = _getMetaContent(document, 'og:description') ?? 
                          _getMetaContent(document, 'twitter:description');

    // Extract images from Open Graph
    String? ogImage = _getMetaContent(document, 'og:image') ??
                      _getMetaContent(document, 'og:image:secure_url') ??
                      _getMetaContent(document, 'twitter:image');
    if (ogImage != null) {
      data['images'].add(_makeAbsoluteUrl(ogImage, baseUrl));
    }

    // Extract price from Open Graph or schema
    data['price'] = _getMetaContent(document, 'og:price:amount') ?? 
                    _getMetaContent(document, 'product:price:amount');
    
    data['currency'] = _getMetaContent(document, 'og:price:currency') ?? 
                       _getMetaContent(document, 'product:price:currency');

    // Try to extract from JSON-LD schema (most reliable across major retailers)
    final jsonLdData = _extractJsonLdData(document);
    if (jsonLdData != null) {
      data['title'] = data['title'] ?? jsonLdData['name'];
      data['description'] = data['description'] ?? jsonLdData['description'];
      data['sku'] = data['sku'] ??
          jsonLdData['sku'] ??
          jsonLdData['mpn'] ??
          jsonLdData['productID'];
      data['good_sn'] = data['good_sn'] ?? data['sku'];
      data['color'] = data['color'] ?? jsonLdData['color'];

      final offers = jsonLdData['offers'];
      void readOffer(Map offer) {
        data['price'] = data['price'] ??
            offer['price'] ??
            offer['lowPrice'] ??
            offer['highPrice'];
        data['currency'] = data['currency'] ?? offer['priceCurrency'];
        final ps = offer['priceSpecification'];
        if (data['price'] == null && ps is Map) {
          data['price'] = ps['price'];
          data['currency'] = data['currency'] ?? ps['priceCurrency'];
        }
      }
      if (offers is Map) {
        readOffer(offers);
      } else if (offers is List) {
        for (final o in offers) {
          if (o is Map) {
            readOffer(o);
            if (data['price'] != null) break;
          }
        }
      }

      final img = jsonLdData['image'];
      if (img is String && img.isNotEmpty) {
        data['images'].add(_makeAbsoluteUrl(img, baseUrl));
      } else if (img is List) {
        for (var i in img) {
          if (i is String && i.isNotEmpty) {
            data['images'].add(_makeAbsoluteUrl(i, baseUrl));
          } else if (i is Map && i['url'] is String) {
            data['images'].add(_makeAbsoluteUrl(i['url'], baseUrl));
          }
        }
      }
    }

    // Site-specific extraction
    if (siteType == 'shein') {
      _extractSheinData(document, baseUrl, data);
    } else if (siteType == 'zara') {
      _extractZaraData(document, baseUrl, data);
    } else if (siteType == 'trendyol') {
      _extractTrendyolData(document, baseUrl, data);
    } else if (siteType == 'mango') {
      _extractMangoData(document, baseUrl, data);
    } else if (siteType == 'noon') {
      _extractNoonData(document, baseUrl, data);
    } else if (siteType == 'hm') {
      _extractHmData(document, baseUrl, data);
    } else if (siteType == 'aliexpress') {
      _extractAliExpressData(document, baseUrl, data);
    }

    // Fallback: Try common product image selectors
    if (data['images'].isEmpty) {
      _extractProductImages(document, baseUrl, data);
    }

    // Fallback: Try common price selectors
    if (data['price'] == null) {
      _extractPrice(document, data);
    }

    // Fallback: Try to get title from page title or h1
    if (data['title'] == null) {
      data['title'] = document.querySelector('h1')?.text.trim() ?? 
                      document.querySelector('title')?.text.trim();
    }

    // Extract color if available
    _extractColor(document, data);

    // Extract size if available
    _extractSize(document, data);

    return data;
  }

  static String _detectSiteType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('shein.com')) return 'shein';
    if (lowerUrl.contains('zara.com')) return 'zara';
    if (lowerUrl.contains('trendyol.com')) return 'trendyol';
    if (lowerUrl.contains('mango.com')) return 'mango';
    if (lowerUrl.contains('amazon.')) return 'amazon';
    if (lowerUrl.contains('hm.com')) return 'hm';
    if (lowerUrl.contains('noon.')) return 'noon';
    if (lowerUrl.contains('namshi.')) return 'namshi';
    if (lowerUrl.contains('asos.')) return 'asos';
    if (lowerUrl.contains('aliexpress')) return 'aliexpress';
    return 'generic';
  }

  static void _extractSheinData(Document document, String baseUrl, Map<String, dynamic> data) {
    // SHEIN uses specific data attributes and classes
    
    // Try to find product data in script tags
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      
      // Look for product data in window objects
      if (text.contains('productIntroData') || text.contains('gbProductInfo') || text.contains('good_sn') || text.contains('goods_sn')) {
        // Try to extract good_sn / goods_sn (SHEIN product serial)
        if (data['good_sn'] == null) {
          final goodSnMatch = RegExp(r'"good_sn"[:\s]*"([^"]+)"').firstMatch(text);
          if (goodSnMatch != null) {
            data['good_sn'] = goodSnMatch.group(1);
          } else {
            final goodsSnMatch = RegExp(r'"goods_sn"[:\s]*"([^"]+)"').firstMatch(text);
            if (goodsSnMatch != null) {
              data['good_sn'] = goodsSnMatch.group(1);
            }
          }
        }
        if (data['sku'] == null && data['good_sn'] != null) {
          data['sku'] = data['good_sn'];
        }
        // Try to extract price
        final priceMatch = RegExp(r'"salePrice"[:\s]*\{[^}]*"amount"[:\s]*"?([0-9.]+)"?').firstMatch(text);
        if (priceMatch != null && data['price'] == null) {
          data['price'] = priceMatch.group(1);
        }
        
        // Try to extract currency
        final currencyMatch = RegExp(r'"code"[:\s]*"([A-Z]{3})"').firstMatch(text);
        if (currencyMatch != null && data['currency'] == null) {
          data['currency'] = currencyMatch.group(1);
        }
        
        // Try to extract images
        final imageMatches = RegExp(r'"origin_image"[:\s]*"([^"]+)"').allMatches(text);
        for (var match in imageMatches) {
          final img = match.group(1);
          if (img != null && !data['images'].contains(img)) {
            data['images'].add(img);
          }
        }
      }
    }
    
    // Fallback: Try data attributes
    final imgElements = document.querySelectorAll('[data-src*="shein"]');
    for (var img in imgElements) {
      final src = img.attributes['data-src'];
      if (src != null && !data['images'].contains(src)) {
        data['images'].add(src);
      }
    }
  }

  static void _extractTrendyolData(Document document, String baseUrl, Map<String, dynamic> data) {
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      if (!text.contains('dsmcdn.com') && !text.contains('trendyol')) continue;

      final imageMatches = RegExp(
        r'https://cdn\.dsmcdn\.com/[^"\s<>]+\.(?:jpg|jpeg|png|webp)',
        caseSensitive: false,
      ).allMatches(text);
      for (var m in imageMatches) {
        final img = m.group(0);
        if (img == null) continue;
        final clean = img.split('?').first;
        if (!data['images'].contains(clean)) {
          data['images'].add(clean);
        }
      }

      final idMatch = RegExp(r'"contentId"\s*:\s*(\d+)').firstMatch(text);
      if (idMatch != null && data['good_sn'] == null) {
        data['good_sn'] = idMatch.group(1);
        data['sku'] = data['good_sn'];
      }
    }
  }

  static void _extractMangoData(Document document, String baseUrl, Map<String, dynamic> data) {
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      if (!text.toLowerCase().contains('mango')) continue;
      final imageMatches = RegExp(
        r'https://[\w.-]*mango\.com/[^"\s<>]+\.(?:jpg|jpeg|png|webp)',
        caseSensitive: false,
      ).allMatches(text);
      for (var m in imageMatches) {
        final img = m.group(0);
        if (img == null) continue;
        final clean = img.split('?').first;
        if (!data['images'].contains(clean)) {
          data['images'].add(clean);
        }
      }
    }
  }

  static void _extractZaraData(Document document, String baseUrl, Map<String, dynamic> data) {
    // Zara product pages embed rich JSON in <script> blocks. The page also
    // serves OpenGraph meta tags which our generic extractor already reads.
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      if (text.isEmpty) continue;

      // Images live on static.zara.net/photos/...
      final imageMatches = RegExp(
        r'https?:\\?/\\?/static\.zara\.net/(?:photos|assets)/[^"\s<>]+?\.(?:jpg|jpeg|png|webp)',
        caseSensitive: false,
      ).allMatches(text);
      for (var match in imageMatches) {
        var img = match.group(0);
        if (img == null) continue;
        img = img.replaceAll(r'\/', '/');
        // Zara URLs may contain {width} template placeholders
        img = img.replaceAll(RegExp(r'\{width\}', caseSensitive: false), '1024');
        if (!data['images'].contains(img)) {
          data['images'].add(img);
        }
      }

      // Extract SKU/reference
      if (data['good_sn'] == null) {
        final refMatch = RegExp(r'"reference"\s*:\s*"([A-Z0-9/\-]+)"', caseSensitive: false).firstMatch(text);
        if (refMatch != null) {
          data['good_sn'] = refMatch.group(1);
          data['sku'] = data['sku'] ?? refMatch.group(1);
        }
      }

      // Price: Zara stores amounts in minor units (value * 100)
      if (data['price'] == null) {
        final priceMatch = RegExp(r'"price"\s*:\s*(\d{2,9})').firstMatch(text);
        if (priceMatch != null) {
          final raw = int.tryParse(priceMatch.group(1) ?? '');
          if (raw != null && raw > 0) {
            data['price'] = (raw / 100).toString();
          }
        }
      }
    }

    // Fallback: id derived from URL (/.../-p{digits}.html)
    if (data['good_sn'] == null) {
      final m = RegExp(r'-p(\d{6,})\.html', caseSensitive: false).firstMatch(baseUrl);
      if (m != null) {
        data['good_sn'] = m.group(1);
        data['sku'] = data['sku'] ?? m.group(1);
      }
    }

    // <picture>/<img> fallbacks
    final pictures = document.querySelectorAll('picture img, picture source');
    for (var img in pictures) {
      final src = img.attributes['src'] ??
          img.attributes['data-src'] ??
          img.attributes['srcset']?.split(',').first.trim().split(' ').first;
      if (src != null && src.contains('static.zara.net') && !data['images'].contains(src)) {
        data['images'].add(_makeAbsoluteUrl(src, baseUrl));
      }
    }
  }

  static void _extractNoonData(Document document, String baseUrl, Map<String, dynamic> data) {
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      if (text.isEmpty) continue;

      // Noon exposes product data in __NUXT__ state
      final imgListMatch = RegExp(r'"image_keys"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(text);
      if (imgListMatch != null) {
        final inner = imgListMatch.group(1) ?? '';
        final keys = RegExp(r'"([^"]+)"').allMatches(inner);
        for (var m in keys) {
          final key = m.group(1);
          if (key == null || key.isEmpty) continue;
          final img = 'https://f.nooncdn.com/p/$key.jpg';
          if (!data['images'].contains(img)) data['images'].add(img);
        }
      }

      if (data['good_sn'] == null) {
        final codeMatch = RegExp(r'"product_code"\s*:\s*"([^"]+)"').firstMatch(text);
        if (codeMatch != null) {
          data['good_sn'] = codeMatch.group(1);
          data['sku'] = codeMatch.group(1);
        }
      }

      if (data['price'] == null) {
        final priceMatch = RegExp(r'"sale_price"\s*:\s*([0-9.]+)').firstMatch(text);
        if (priceMatch != null) {
          data['price'] = priceMatch.group(1);
        }
      }
    }
  }

  static void _extractHmData(Document document, String baseUrl, Map<String, dynamic> data) {
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      if (text.isEmpty) continue;
      final imageMatches = RegExp(
        r'https?:\\?/\\?/(?:lp2|image)\.hm\.com/[^"\s<>]+\.(?:jpg|jpeg|png|webp)',
        caseSensitive: false,
      ).allMatches(text);
      for (var m in imageMatches) {
        var img = m.group(0);
        if (img == null) continue;
        img = img.replaceAll(r'\/', '/');
        if (!data['images'].contains(img)) data['images'].add(img);
      }
    }
  }

  static void _extractAliExpressData(Document document, String baseUrl, Map<String, dynamic> data) {
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      if (!text.contains('runParams') && !text.contains('imagePathList')) continue;
      final listMatch = RegExp(r'"imagePathList"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(text);
      if (listMatch != null) {
        final inner = listMatch.group(1) ?? '';
        final urls = RegExp(r'"(https?:\\?/\\?/[^"]+)"').allMatches(inner);
        for (var m in urls) {
          var url = m.group(1);
          if (url == null) continue;
          url = url.replaceAll(r'\/', '/');
          if (!data['images'].contains(url)) data['images'].add(url);
        }
      }
    }
  }

  static String? _getMetaContent(Document document, String property) {
    // Try property attribute first
    var element = document.querySelector('meta[property="$property"]');
    if (element != null) {
      return element.attributes['content'];
    }
    
    // Try name attribute
    element = document.querySelector('meta[name="$property"]');
    if (element != null) {
      return element.attributes['content'];
    }
    
    return null;
  }

  static Map<String, dynamic>? _extractJsonLdData(Document document) {
    Map<String, dynamic>? walk(dynamic node) {
      if (node is Map) {
        final type = node['@type'];
        bool isProduct = false;
        if (type is String && type.toLowerCase() == 'product') isProduct = true;
        if (type is List) {
          for (final t in type) {
            if (t is String && t.toLowerCase() == 'product') {
              isProduct = true;
              break;
            }
          }
        }
        if (isProduct) return Map<String, dynamic>.from(node);

        if (node['@graph'] is List) {
          for (final child in node['@graph']) {
            final r = walk(child);
            if (r != null) return r;
          }
        }
        for (final key in const ['mainEntity', 'itemListElement', 'subjectOf']) {
          if (node[key] != null) {
            final r = walk(node[key]);
            if (r != null) return r;
          }
        }
      } else if (node is List) {
        for (final child in node) {
          final r = walk(child);
          if (r != null) return r;
        }
      }
      return null;
    }

    try {
      final scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (var script in scripts) {
        final jsonText = script.text.trim();
        if (jsonText.isEmpty) continue;
        try {
          final jsonData = jsonDecode(jsonText);
          final found = walk(jsonData);
          if (found != null) return found;
        } catch (_) {
          // ignore malformed LD+JSON blocks
        }
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  static void _extractProductImages(Document document, String baseUrl, Map<String, dynamic> data) {
    // Common product image selectors for various e-commerce platforms
    final imageSelectors = [
      'img[src*="product"]',
      'img[src*="image"]',
      'img[data-src*="product"]',
      '.product-image img',
      '.product-gallery img',
      '[data-image-role="product-image"]',
      '.gallery-image img',
      '#product-image',
      '[data-testid="product-image"]',
      '.product-photo img',
      '.main-image img',
      '[itemprop="image"]',
      '.product-img img',
      'picture img',
      '[class*="ProductImage"] img',
      '[class*="product-photo"] img',
    ];

    for (var selector in imageSelectors) {
      final images = document.querySelectorAll(selector);
      for (var img in images) {
        String? src = img.attributes['src'] ??
            img.attributes['data-src'] ??
            img.attributes['data-lazy'] ??
            img.attributes['data-original'] ??
            img.attributes['data-zoom-image'];
        // <source srcset="url1 1x, url2 2x"> or plain srcset
        src ??= img.attributes['srcset']?.split(',').first.trim().split(' ').first;

        if (src == null || src.isEmpty) continue;
        if (src.startsWith('data:')) continue;
        final lower = src.toLowerCase();
        if (lower.contains('placeholder') ||
            lower.contains('loading') ||
            lower.contains('blank') ||
            lower.endsWith('.svg') ||
            lower.endsWith('.gif')) {
          continue;
        }

        final absoluteUrl = _makeAbsoluteUrl(src, baseUrl);
        // Accept image-like URLs: explicit extension OR path/query hints
        final pathOnly = absoluteUrl.split('?').first.toLowerCase();
        final looksLikeImage = pathOnly.endsWith('.jpg') ||
            pathOnly.endsWith('.jpeg') ||
            pathOnly.endsWith('.png') ||
            pathOnly.endsWith('.webp') ||
            pathOnly.endsWith('.avif') ||
            lower.contains('/image') ||
            lower.contains('/photos/') ||
            lower.contains('/product') ||
            lower.contains('cdn');
        if (!looksLikeImage) continue;
        if (data['images'].contains(absoluteUrl)) continue;
        data['images'].add(absoluteUrl);
        if (data['images'].length >= 6) break;
      }
      if (data['images'].isNotEmpty) break;
    }
  }

  static void _extractPrice(Document document, Map<String, dynamic> data) {
    // Common price selectors
    final priceSelectors = [
      '[data-price]',
      '[class*="price-sales"]',
      '[class*="price-now"]',
      '.price',
      '.product-price',
      '[itemprop="price"]',
      '.sale-price',
      '.current-price',
      '[data-testid="price"]',
      '.price-current',
      '#product-price',
      '[class*="Price"]',
      'span[class*="price"]',
    ];

    for (var selector in priceSelectors) {
      final priceElement = document.querySelector(selector);
      if (priceElement != null) {
        // First try data-price attribute
        final dataPrice = priceElement.attributes['data-price'];
        if (dataPrice != null && dataPrice.isNotEmpty) {
          data['price'] = dataPrice;
          continue;
        }
        
        final priceText = priceElement.text.trim();
        if (priceText.isEmpty) continue;
        
        // Extract numeric price (handle decimals and thousands separators)
        final priceMatch = RegExp(r'[\d,]+\.?\d*').firstMatch(priceText);
        if (priceMatch != null) {
          data['price'] = priceMatch.group(0)?.replaceAll(',', '');
          
          // Try to extract currency
          final currencyMatch = RegExp(r'[A-Z]{3}|\$|€|£|¥|₺|TL').firstMatch(priceText);
          if (currencyMatch != null) {
            final currencySymbol = currencyMatch.group(0);
            data['currency'] = _currencySymbolToCode(currencySymbol);
          }
          break;
        }
      }
    }
  }

  static void _extractColor(Document document, Map<String, dynamic> data) {
    final colorSelectors = [
      '.selected-color',
      '.color-name',
      '[data-attribute="color"]',
      '.product-color',
    ];

    for (var selector in colorSelectors) {
      final colorElement = document.querySelector(selector);
      if (colorElement != null) {
        data['color'] = colorElement.text.trim();
        break;
      }
    }
  }

  static void _extractSize(Document document, Map<String, dynamic> data) {
    final sizeSelectors = [
      '.selected-size',
      '.size-selected',
      '[data-attribute="size"]',
      '.product-size',
    ];

    for (var selector in sizeSelectors) {
      final sizeElement = document.querySelector(selector);
      if (sizeElement != null) {
        data['size'] = sizeElement.text.trim();
        break;
      }
    }
  }

  static String _makeAbsoluteUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    try {
      final base = Uri.parse(baseUrl);
      if (url.startsWith('//')) {
        return '${base.scheme}:$url';
      }
      if (url.startsWith('/')) {
        return '${base.scheme}://${base.host}$url';
      }
      return '${base.scheme}://${base.host}/${base.pathSegments.join('/')}/$url';
    } catch (e) {
      return url;
    }
  }

  static String? _currencySymbolToCode(String? symbol) {
    if (symbol == null) return null;
    
    final currencyMap = {
      '\$': 'USD',
      '€': 'EUR',
      '£': 'GBP',
      '¥': 'JPY',
      '₺': 'TRY',
      'TL': 'TRY',
      'USD': 'USD',
      'EUR': 'EUR',
      'GBP': 'GBP',
    };
    
    return currencyMap[symbol] ?? symbol;
  }

  // Download image from URL
  static Future<http.Response?> downloadImage(String imageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return response;
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }
}

