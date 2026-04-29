import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/app_colors.dart';
import '../models/website_model.dart';
import '../generated/app_localizations.dart';
import 'add_order_screen.dart';

class WebsiteViewScreen extends StatefulWidget {
  final Website website;

  const WebsiteViewScreen({super.key, required this.website});

  @override
  State<WebsiteViewScreen> createState() => _WebsiteViewScreenState();
}

class _WebsiteViewScreenState extends State<WebsiteViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  String _currentUrl = '';
  final GlobalKey _webViewKey = GlobalKey();
  Timer? _hideUiTimer;

  // JS that hides purchase CTAs, cookie banners and "get the app" banners on
  // any website. Runs on page load + on DOM mutations so it also catches
  // banners injected late (common on SPAs like SHEIN / Amazon / Zara).
  static const String _hideUiScript = r'''
(function(){
  if (window.__veloxHideInstalled) { try { window.__veloxHideUI && window.__veloxHideUI(); } catch(e){} return; }
  window.__veloxHideInstalled = true;

  var BUY_RX    = /^\s*(add to (cart|bag|basket|wishlist)|add to my list|buy now|buy it now|buy|order now|place order|pre[- ]?order|proceed to checkout|checkout|shop now|continue to checkout|purchase|add to trolley)\s*$/i;
  var COOKIE_RX = /^(accept( all)?( cookies)?|agree|i agree|got it|allow all|accept and close|ok|continue without accepting)\s*$/i;
  var APP_RX    = /^(open( in)? app|open in the app|get the app|download (the )?app|continue in app|use app|open in shein|continue in browser|try the app)\s*$/i;

  var CSS_HIDE_SELECTORS = [
    // Cookie / consent banners (generic + common vendors)
    '[id*="cookie" i]','[class*="cookie" i]',
    '[id*="consent" i]','[class*="consent" i]',
    '[id*="gdpr" i]','[class*="gdpr" i]',
    '[aria-label*="cookie" i]','[aria-label*="consent" i]',
    '#onetrust-banner-sdk','#onetrust-consent-sdk','.onetrust-pc-dark-filter',
    '.cc-banner','.cc-window','.truste_box_overlay','.truste_overlay',
    '#CybotCookiebotDialog','#CybotCookiebotDialogBodyUnderlay',
    '.osano-cm-window','.osano-cm-dialog',
    '.evidon-banner','.evidon-barrier',
    '#qc-cmp2-container','#qc-cmp2-main',
    '#didomi-host','.didomi-popup-container','.didomi-notice-banner',
    // Smart-app banners / "open in app"
    '[class*="smart-banner" i]','[id*="smart-banner" i]',
    '[class*="smartbanner" i]','[id*="smartbanner" i]',
    '[class*="app-banner" i]','[id*="app-banner" i]',
    '[class*="download-app" i]','[class*="get-the-app" i]','[class*="getapp" i]',
    '[class*="open-in-app" i]','[id*="open-in-app" i]',
    '[class*="openApp" i]','[id*="openApp" i]',
    '[class*="app-download" i]','[id*="app-download" i]',
    '.branch-banner-is-active','.branch-banner',
    // SHEIN-specific deep links / CTAs
    '[class*="j-fixed-app" i]','[class*="j-bottom-app" i]','[class*="app-entrance" i]',
    '[class*="BCouponEntry" i]','[class*="c-app-download" i]',
    '[data-track*="openapp" i]','[data-track*="open_app" i]',
    // Common bottom/top CTA bars for buy/cart on SHEIN / Amazon / Noon / Zara
    '[class*="j-sticky" i][class*="cart" i]','[class*="sticky" i][class*="buy" i]',
    '[class*="add-to-cart" i]','[id*="add-to-cart" i]',
    '[class*="addToCart" i]','[id*="addToCart" i]',
    '[class*="buy-now" i]','[id*="buy-now" i]',
    '[class*="checkout" i][class*="btn" i]','[id*="checkout-button" i]',
    '[class*="product-intro__add" i]','[class*="j-add-cart" i]',
    '.cart-bar','.j-buy-bar','.buy-bar','.product-detail__add-to-cart',
    '#add-to-cart-button','#buy-now-button','#buybox','#buybox-container'
  ];

  function injectCSS(){
    if (document.getElementById('velox-hide-style')) return;
    var s = document.createElement('style');
    s.id = 'velox-hide-style';
    var rules = CSS_HIDE_SELECTORS.map(function(sel){
      return sel + '{display:none !important; visibility:hidden !important; opacity:0 !important; pointer-events:none !important; height:0 !important; max-height:0 !important; overflow:hidden !important;}';
    }).join(' ');
    // Extra: stop body scroll-lock used by cookie modals
    rules += ' html, body { overflow: auto !important; position: static !important; }';
    s.appendChild(document.createTextNode(rules));
    (document.head || document.documentElement).appendChild(s);
  }

  function hideByText(){
    var nodes = document.querySelectorAll('button, a, [role="button"], [role="link"], input[type="button"], input[type="submit"]');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (!el || el.__veloxChecked) continue;
      el.__veloxChecked = 1;
      var txt = '';
      try { txt = (el.innerText || el.textContent || el.value || el.getAttribute('aria-label') || '').trim(); } catch(e){}
      if (!txt || txt.length > 64) continue;
      var match = BUY_RX.test(txt) || COOKIE_RX.test(txt) || APP_RX.test(txt);
      if (!match) continue;
      try {
        el.style.setProperty('display','none','important');
        // Also hide a fixed/sticky container wrapping the CTA (common pattern)
        var p = el.parentElement, hops = 0;
        while (p && hops < 5) {
          var cs = window.getComputedStyle(p);
          if (cs && (cs.position === 'fixed' || cs.position === 'sticky')) {
            p.style.setProperty('display','none','important');
            break;
          }
          p = p.parentElement; hops++;
        }
      } catch(e){}
    }
  }

  function hideUI(){
    try { injectCSS(); } catch(e){}
    try { hideByText(); } catch(e){}
  }

  window.__veloxHideUI = hideUI;
  hideUI();

  // Re-run periodically for SPAs that inject banners after navigation
  var runs = 0;
  var iv = setInterval(function(){ hideUI(); runs++; if (runs > 40) clearInterval(iv); }, 400);

  // Observe DOM for dynamically-added banners
  try {
    var mo = new MutationObserver(function(){ hideUI(); });
    mo.observe(document.documentElement, { childList: true, subtree: true });
  } catch(e){}
})();
''';

  // Generic product extractor: works on any site via OG tags, JSON-LD Product
  // schema, Twitter Card, microdata itemprop, and largest-image fallback.
  // Also keeps SHEIN-specific globals as the highest priority.
  static const String _extractScript = r'''
(function() {
  var d = { url: '', name: '', image: '', sn: '' };

  // ── URL resolution ────────────────────────────────────────────────────
  // SPAs (SHEIN, noon, Zara, etc.) frequently show a category / store URL
  // in the address bar while rendering product content — the real product
  // URL is exposed only via canonical / og:url / JSON-LD, or embedded in
  // an anchor / data attribute on the page. We try a waterfall of sources
  // and pick the first one that looks like a product URL.
  var SHEIN_P_RX = /-p-(\d{5,})/;
  // Noon product URLs look like: /<region>-<lang>/<slug>/ZABC123XYZ/p/
  var NOON_P_RX  = /\/([ZN][A-Z0-9]{8,})\/p(?:\/|\?|$)/;
  var HOST       = (window.location.hostname || '').toLowerCase();

  function looksLikeProduct(u) {
    if (!u || typeof u !== 'string') return false;
    if (SHEIN_P_RX.test(u)) return true;
    if (NOON_P_RX.test(u))  return true;
    // Generic hint: most product pages end with something like /p/ or .html
    // with a numeric id — we leave those to the server-side extractor and
    // only trust them here as a fallback.
    return false;
  }

  var urlCandidates = [];
  urlCandidates.push(window.location.href);
  try { var can = document.querySelector('link[rel="canonical"]'); if (can && can.href) urlCandidates.push(can.href); } catch(e){}
  try { var ogu = document.querySelector('meta[property="og:url"]'); if (ogu) urlCandidates.push(ogu.getAttribute('content') || ''); } catch(e){}
  try { var twu = document.querySelector('meta[name="twitter:url"]'); if (twu) urlCandidates.push(twu.getAttribute('content') || ''); } catch(e){}

  // Noon-specific: Next.js state often carries the product URL even when
  // the address bar is stuck on a category. Look for any string inside
  // __NEXT_DATA__ that matches the noon product URL pattern.
  if (HOST.indexOf('noon.com') !== -1) {
    try {
      var nd = document.getElementById('__NEXT_DATA__');
      if (nd && nd.textContent) {
        var ndText = nd.textContent;
        var m = ndText.match(/https?:\/\/[^"\s]+\/[ZN][A-Z0-9]{8,}\/p\/?[^"\s]*/);
        if (m) urlCandidates.push(m[0]);
      }
    } catch(e){}
    // Any anchor that links to a product page counts too — but ONLY the
    // primary one (first hit) since category pages contain many.
    try {
      var a = document.querySelector('a[href*="/p/"]');
      if (a && a.href) urlCandidates.push(a.href);
    } catch(e){}
  }

  for (var ui = 0; ui < urlCandidates.length; ui++) {
    var u = urlCandidates[ui];
    if (looksLikeProduct(u)) { d.url = u; break; }
  }
  if (!d.url) d.url = window.location.href;

  // ── SHEIN JS globals (highest priority) ───────────────────────────────
  var sources = [];
  try { if (window.productIntroData && window.productIntroData.detail) sources.push(window.productIntroData.detail); } catch(e){}
  try { if (window.gbRawData) sources.push(window.gbRawData); } catch(e){}
  try { if (window.SaPageInfo && window.SaPageInfo.page_param) sources.push(window.SaPageInfo.page_param); } catch(e){}
  for (var s=0; s<sources.length; s++) {
    var src = sources[s];
    if (!d.name && src.goods_name) d.name = src.goods_name;
    if (!d.sn   && src.goods_sn)   d.sn   = src.goods_sn;
    if (!d.image && src.goods_img) d.image = src.goods_img;
    if (d.name && d.sn && d.image) break;
  }

  // ── JSON-LD Product schema ───────────────────────────────────────────
  try {
    var ldScripts = document.querySelectorAll('script[type="application/ld+json"]');
    function visit(node){
      if (!node || typeof node !== 'object') return;
      var t = node['@type'];
      var isProduct = (t === 'Product') || (Array.isArray(t) && t.indexOf('Product') !== -1);
      if (isProduct) {
        if (!d.name && node.name) d.name = String(node.name);
        if (!d.sn && (node.sku || node.mpn || node.productID)) d.sn = String(node.sku || node.mpn || node.productID);
        if (!d.image && node.image) {
          var img = node.image;
          if (Array.isArray(img)) img = img[0];
          if (img && typeof img === 'object') img = img.url || img['@id'] || '';
          if (typeof img === 'string') d.image = img;
        }
      }
      if (node['@graph']) node['@graph'].forEach(visit);
    }
    for (var li=0; li<ldScripts.length; li++) {
      try {
        var parsed = JSON.parse(ldScripts[li].textContent || ldScripts[li].innerText || '{}');
        if (Array.isArray(parsed)) parsed.forEach(visit); else visit(parsed);
        if (d.name && d.image && d.sn) break;
      } catch(e){}
    }
  } catch(e){}

  // ── Open Graph / Twitter / standard meta ─────────────────────────────
  try {
    if (!d.image) {
      var m = document.querySelector('meta[property="og:image:secure_url"]')
            || document.querySelector('meta[property="og:image"]')
            || document.querySelector('meta[name="og:image"]')
            || document.querySelector('meta[name="twitter:image"]')
            || document.querySelector('meta[name="twitter:image:src"]');
      if (m) d.image = m.getAttribute('content') || '';
    }
    if (!d.name) {
      var t = document.querySelector('meta[property="og:title"]')
            || document.querySelector('meta[name="twitter:title"]');
      if (t) d.name = (t.getAttribute('content')||'').replace(/\s*[\|\-–—]\s*(SHEIN|Amazon|Noon|Zara|H&M|Trendyol|AliExpress|Mango|ASOS).*$/i,'').trim();
    }
  } catch(e){}

  // ── Microdata itemprop ───────────────────────────────────────────────
  try {
    if (!d.name) { var nEl = document.querySelector('[itemprop="name"]'); if (nEl) d.name = (nEl.getAttribute('content') || nEl.innerText || '').trim(); }
    if (!d.image) { var iEl = document.querySelector('[itemprop="image"]'); if (iEl) d.image = iEl.getAttribute('content') || iEl.getAttribute('src') || ''; }
    if (!d.sn) { var sEl = document.querySelector('[itemprop="sku"],[itemprop="productID"],[itemprop="mpn"]'); if (sEl) d.sn = (sEl.getAttribute('content') || sEl.innerText || '').trim(); }
  } catch(e){}

  // ── DOM fallbacks ─────────────────────────────────────────────────────
  try {
    if (!d.name) {
      var h = document.querySelector('h1');
      if (h) d.name = (h.innerText || h.textContent || '').trim();
    }
    if (!d.name) d.name = (document.title || '').trim();

    if (!d.image) {
      var imgs = document.querySelectorAll('.product-intro__main-pic img, .swiper-slide img, .j-expose__product-intro__main-img img, .product-image img, .product__image img, [class*="product" i] img, [class*="gallery" i] img');
      for (var ii=0; ii<imgs.length; ii++) {
        var src2 = imgs[ii].currentSrc || imgs[ii].src || imgs[ii].getAttribute('data-src') || imgs[ii].getAttribute('data-original') || '';
        if (src2 && !src2.startsWith('data:')) { d.image = src2; break; }
      }
    }

    // Largest visible image on page as ultimate fallback
    if (!d.image) {
      var best = null, bestArea = 0;
      var all = document.querySelectorAll('img');
      for (var k=0; k<all.length; k++) {
        var im = all[k];
        var w = im.naturalWidth || im.width || 0;
        var hgt = im.naturalHeight || im.height || 0;
        if (w < 180 || hgt < 180) continue;
        var src3 = im.currentSrc || im.src || im.getAttribute('data-src') || '';
        if (!src3 || src3.indexOf('data:') === 0) continue;
        var area = w * hgt;
        if (area > bestArea) { bestArea = area; best = src3; }
      }
      if (best) d.image = best;
    }
  } catch(e){}

  // Normalize protocol-relative URLs
  if (d.image && d.image.indexOf('//') === 0) d.image = 'https:' + d.image;
  // Resolve relative URLs
  try {
    if (d.image && d.image.indexOf('http') !== 0 && d.image.indexOf('data:') !== 0) {
      d.image = new URL(d.image, window.location.href).href;
    }
  } catch(e){}

  return JSON.stringify(d);
})()
''';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.website.link;
    _initWebView();
  }

  @override
  void dispose() {
    _hideUiTimer?.cancel();
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8F2DA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
            // Start hiding as soon as the page starts rendering
            if (progress > 30) {
              _injectHideUi();
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            _injectHideUi();
          },
          onPageFinished: (String url) async {
            String resolvedUrl = url;
            try {
              final jsUrl = await _controller.currentUrl();
              if (jsUrl != null && jsUrl.isNotEmpty) resolvedUrl = jsUrl;
            } catch (_) {}
            setState(() {
              _isLoading = false;
              _currentUrl = resolvedUrl;
            });
            _injectHideUi();
            // Re-inject a few times for SPAs where route changes without full reload
            _hideUiTimer?.cancel();
            var count = 0;
            _hideUiTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
              _injectHideUi();
              count++;
              if (count > 8) t.cancel();
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.website.link));
  }

  Future<void> _injectHideUi() async {
    try {
      await _controller.runJavaScript(_hideUiScript);
    } catch (_) {}
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  Future<void> _refresh() async {
    await _controller.reload();
  }

  /// Captures the current WebView as a PNG and returns the file, or null on
  /// failure. Used as a fallback when the page has no extractable image.
  Future<File?> _captureScreenshotToFile() async {
    try {
      final boundary = _webViewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // Wait a frame to ensure the WebView has painted its latest content.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      if (bytes.isEmpty) return null;
      final tempDir = await Directory.systemTemp.createTemp('velox_ss');
      final file = File(
          '${tempDir.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Screenshot capture error: $e');
      return null;
    }
  }

  Future<void> _orderCurrentPage() async {
    String url = _currentUrl;
    String name = '';
    String imageUrl = '';
    String serial = '';

    try {
      final jsResult = await _controller.runJavaScriptReturningResult(_extractScript);

      final raw = jsResult.toString();
      final jsonStr = raw.startsWith('"') ? jsonDecode(raw) : raw;
      final data = jsonDecode(jsonStr as String) as Map<String, dynamic>;

      final extractedUrl = data['url']?.toString() ?? '';
      if (extractedUrl.isNotEmpty && extractedUrl.startsWith('http')) url = extractedUrl;
      name     = data['name']?.toString()  ?? '';
      imageUrl = data['image']?.toString() ?? '';
      serial   = data['sn']?.toString()    ?? '';
    } catch (e) {
      debugPrint('WebView JS extraction error: $e');
    }

    // Fallback: if the page didn't expose a usable image, screenshot the
    // WebView so the user still has something to send with the order.
    File? screenshotFile;
    if (imageUrl.isEmpty) {
      screenshotFile = await _captureScreenshotToFile();
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrderScreen(
          initialUrl: url,
          initialName: name.isNotEmpty ? name : null,
          initialImageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          initialSerial: serial.isNotEmpty ? serial : null,
          initialImageFile: screenshotFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _controller.setBackgroundColor(isDark ? AppColors.background : const Color(0xFFF8F2DA));

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.website.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
            ),
            if (_currentUrl.isNotEmpty)
              Text(
                _currentUrl,
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home_outlined, size: 22, color: context.textPrimaryColor),
            tooltip: 'Home',
            onPressed: () => _controller.loadRequest(Uri.parse(widget.website.link)),
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 22, color: context.textPrimaryColor),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _isLoading
              ? LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: context.surfaceColor,
                  color: AppColors.primary,
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: RepaintBoundary(
        key: _webViewKey,
        child: WebViewWidget(controller: _controller),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
          top: 8,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, size: 20, color: context.textPrimaryColor),
              onPressed: _goBack,
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 20, color: context.textPrimaryColor),
              onPressed: _goForward,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _orderCurrentPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: context.textPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(Icons.add_shopping_cart, size: 20, color: context.textPrimaryColor),
                label: Text(
                  l10n.order,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
