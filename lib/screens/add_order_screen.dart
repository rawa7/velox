import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/web_scraper_service.dart';
import '../models/user_model.dart';
import '../models/cart_item_model.dart';
import '../generated/app_localizations.dart';

class AddOrderScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialName;
  final String? initialSerial;
  final String? initialImageUrl;
  /// Optional pre-downloaded image file to use as the product image (e.g. a
  /// WebView screenshot captured when the site exposed no extractable image).
  final File? initialImageFile;

  const AddOrderScreen({
    super.key,
    this.initialUrl,
    this.initialName,
    this.initialSerial,
    this.initialImageUrl,
    this.initialImageFile,
  });

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  User? _user;

  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  final _singlePriceController = TextEditingController();
  final _sizeTextController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetchingProduct = false;
  File? _mainImage;
  
  // Cart Items (only used when SHEIN cart extracted)
  List<CartItem> _cartItems = [];
  bool _showCartItems = false;

  // Single product (when not SHEIN cart): one whole item + product image
  String _singleItemName = '';
  String _singleSerial = '';
  int _singleQty = 1;
  double _singlePrice = 0.0;
  String? _singleProductImageUrl;

  /// Extracts the first http/https URL from [text], stripping any leading junk.
  String _extractUrl(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    return match != null ? match.group(0)! : text;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
    _urlController.addListener(() {
      final raw = _urlController.text;
      // Only process if the text contains a URL but doesn't start with http
      if (raw.contains('http') && !raw.trimLeft().startsWith('http')) {
        final extracted = _extractUrl(raw);
        if (extracted != raw) {
          _urlController.value = _urlController.value.copyWith(
            text: extracted,
            selection: TextSelection.collapsed(offset: extracted.length),
          );
        }
      }
    });
    // Pre-populate from WebView extraction if provided
    if (widget.initialName != null ||
        widget.initialSerial != null ||
        widget.initialImageUrl != null ||
        widget.initialImageFile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialProductData();
      });
    }
  }

  void _applyInitialProductData() {
    if (!mounted) return;
    setState(() {
      _showCartItems = false;
      final codeNameParts = <String>[];
      if (widget.initialSerial != null && widget.initialSerial!.isNotEmpty) {
        codeNameParts.add(widget.initialSerial!);
      }
      if (widget.initialName != null && widget.initialName!.isNotEmpty) {
        codeNameParts.add(widget.initialName!);
      }
      _singleItemName = codeNameParts.join(' · ');
      _singleSerial = '';
      if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
        _singleProductImageUrl = widget.initialImageUrl;
      }
      // If a pre-downloaded file (e.g. a WebView screenshot) was passed,
      // use it directly as the main image.
      if (widget.initialImageFile != null) {
        _mainImage = widget.initialImageFile;
      }
    });
    // Download the remote image to a file for submission, only if we don't
    // already have a local file from the caller.
    if (widget.initialImageFile == null &&
        widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      _downloadImageToFile(widget.initialImageUrl!);
    }
  }

  Future<void> _downloadImageToFile(String imageUrl) async {
    try {
      final imageResponse = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Referer': 'https://www.shein.com/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        },
      );
      if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
        final tempDir = await Directory.systemTemp.createTemp('velox');
        final file = File('${tempDir.path}/product_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(imageResponse.bodyBytes);
        if (mounted) setState(() => _mainImage = file);
      }
    } catch (e) {
      debugPrint('Image download error: $e');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _notesController.dispose();
    _singlePriceController.dispose();
    _sizeTextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _user = await StorageService.getUser();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Returns true if the given URL looks like a SHEIN link.
  bool _isSheinLink(String url) {
    return url.trim().toLowerCase().contains('shein');
  }

  /// Returns true if the given URL looks like a noon.com link.
  bool _isNoonLink(String url) {
    final u = url.trim().toLowerCase();
    return u.contains('noon.com');
  }

  /// Returns true if the noon URL is a real *product* page URL (has a
  /// SKU segment and `/p/` marker), as opposed to the category / store
  /// homepage URLs that noon's mobile web often shows in the address bar.
  ///
  /// Noon product URLs look like:
  ///   https://www.noon.com/uae-en/<slug>/ZEAC849D301D69FA6C298Z/p/?shareId=...
  ///   https://www.noon.com/saudi-en/<slug>/N70133551V/p/
  ///
  /// Non-product URLs we want to reject:
  ///   https://www.noon.com/uae-en/noon-supermarket/        (store)
  ///   https://www.noon.com/uae-en/                         (homepage)
  ///   https://www.noon.com/uae-en/fashion/                 (category)
  bool _isNoonProductUrl(String url) {
    if (!_isNoonLink(url)) return false;
    final u = url.trim();
    // Noon SKUs are uppercase alphanumerics starting with Z or N and are at
    // least 10 chars long. They're followed by `/p/` or `/p?...`.
    final sku = RegExp(r'/([ZN][A-Z0-9]{8,})/p(?:/|\?|$)');
    return sku.hasMatch(u);
  }

  /// Returns true if the URL is clearly a SHEIN *cart* share (multiple
  /// items), as opposed to a single-product share. These links come from
  /// SHEIN's "Share my cart" feature and should never be collapsed into a
  /// single-product extraction, because the share landing page also lists
  /// unrelated recommendations whose IDs would otherwise be mistaken for
  /// the user's item.
  bool _isSheinCartShareLink(String url) {
    final u = url.trim().toLowerCase();
    return u.contains('sharejump/appjump') ||
        u.contains('api-shein.shein.com/h5/sharejump') ||
        u.contains('shein.com/h5/share') ||
        u.contains('shein.com/share');
  }

  /// Called when user wants to extract from the pasted link. Shows SHEIN options or runs single-product extraction.
  /// Auto-extraction:
  /// - SHEIN link → try full cart first; if no items found, fall back to single product
  /// - Any other link → use web scraper directly
  Future<void> _onExtractFromLink() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a product or cart link first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSheinLink(url)) {
      await _autoExtractShein(url);
    } else {
      await _extractSingleProductWithScraper();
    }
  }

  /// Try SHEIN cart first; if empty/fails, fall back to single product.
  /// For URLs that are *clearly* cart shares we never fall back to the
  /// single-product API, because it would otherwise return an unrelated
  /// recommendation from the share landing page.
  Future<void> _autoExtractShein(String url) async {
    setState(() => _isFetchingProduct = true);

    final isCartShareUrl = _isSheinCartShareLink(url);
    bool serverFlaggedCartShare = false;

    // ── Step 1: try cart ────────────────────────────────────────────────
    try {
      final cartResult = await ApiService.extractSheinCart(url);
      if (!mounted) return;

      if (cartResult['is_cart_share'] == true) {
        serverFlaggedCartShare = true;
      }

      final items = cartResult['items'] as List<dynamic>? ?? [];
      if (cartResult['success'] == true && items.isNotEmpty) {
        // Cart succeeded → use cart flow
        final cartItemsList = items
            .map((item) => CartItem.fromSheinJson(item as Map<String, dynamic>))
            .where((item) => item.isValid)
            .toList();

        if (cartItemsList.isNotEmpty) {
          setState(() {
            _cartItems = cartItemsList;
            _showCartItems = true;
            _isFetchingProduct = false;
          });

          // Download first item image for submission
          final firstImageUrl = _cartItems.first.imageUrl;
          if (firstImageUrl != null && firstImageUrl.isNotEmpty) {
            try {
              final imgResp = await http.get(
                Uri.parse(firstImageUrl),
                headers: {
                  'Referer': 'https://www.shein.com/',
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                },
              );
              if (imgResp.statusCode == 200 && imgResp.bodyBytes.isNotEmpty) {
                final tempDir = await Directory.systemTemp.createTemp('velox');
                final file = File('${tempDir.path}/shein_${DateTime.now().millisecondsSinceEpoch}.jpg');
                await file.writeAsBytes(imgResp.bodyBytes);
                if (mounted) setState(() => _mainImage = file);
              }
            } catch (_) {}
          }

          if (mounted) {
            final loc = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.cartItemsExtracted(cartItemsList.length)),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return;
        }
      }
    } catch (_) {}

    // ── Step 2: cart empty/failed ───────────────────────────────────────
    if (!mounted) return;

    // If the link is clearly a cart share, do NOT fall back to the
    // single-product API — it would return an unrelated recommendation
    // (SHEIN's share page shows "You may also like" products that are not
    // the user's cart contents). Show a cart-specific hint instead.
    if (isCartShareUrl || serverFlaggedCartShare) {
      setState(() => _isFetchingProduct = false);
      _showManualEntryHint(
        message: "We couldn't read the items in this SHEIN cart share. "
            "Open the link in SHEIN and paste individual product links here, "
            "or add the items manually.",
      );
      return;
    }

    // Not a cart share → fall back to single product as before.
    setState(() => _isFetchingProduct = false);
    await _extractSingleProductWithScraper();
  }

  /// Shown when auto-extraction fails for any reason. Keeps the user in the
  /// form, prompts them to add the product photo manually, and reveals the
  /// single-item entry card so they can fill details in by hand.
  void _showManualEntryHint({String? message}) {
    if (!mounted) return;

    // Reveal the single-item entry card so the user can enter details by hand.
    // Anything the user already typed (qty, color, picked image) is preserved.
    setState(() => _showCartItems = false);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message ??
                    "Couldn't read this page. Please add the product image and continue.",
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Single product only. Site-specific APIs win when we have them
  /// (SHEIN → shein1product.php, noon → noon_product.php); everything else
  /// goes through the universal server-side extractor, then the in-app
  /// scraper as a last resort.
  Future<void> _extractSingleProductWithScraper() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isFetchingProduct = true);

    try {
      String? imageUrl;
      String title = '';
      String serial = '';
      double price = 0.0;

      // Route to the SHEIN-specific API for every SHEIN link variant
      // (shein.com, shein.cn, shein.top, m.shein.com, share.shein.com,
      //  api-shein.shein.com, etc.) — same check used for the cart path.
      final isShein = _isSheinLink(url);
      final isNoon  = !isShein && _isNoonLink(url);

      if (isShein) {
        // Use the dedicated SHEIN single-product API
        final result = await ApiService.extractSheinSingleProduct(url);
        if (!mounted) return;

        if (result['success'] != true) {
          // If the server detected this is a cart-share URL (multiple items)
          // show a cart-specific hint. Otherwise show the generic SHEIN hint.
          final isCartShare = result['is_cart_share'] == true ||
              _isSheinCartShareLink(url);

          _showManualEntryHint(
            message: isCartShare
                ? "We couldn't read the items in this SHEIN cart share. "
                    "Open the link in SHEIN and paste individual product links "
                    "here, or add the items manually."
                : "SHEIN couldn't read this link. Please add the product "
                    "image and continue, or paste the full product URL.",
          );
          setState(() => _isFetchingProduct = false);
          return;
        }

        title   = result['name']?.toString() ?? '';
        serial  = result['good_sn']?.toString() ?? '';
        price   = (result['price'] as num?)?.toDouble() ?? 0.0;
        imageUrl = result['image']?.toString();
        if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;
      } else if (isNoon) {
        // Noon's mobile web often shows category/store URLs like
        //   https://www.noon.com/uae-en/noon-supermarket/
        // in the address bar even when the user is looking at a product.
        // Those URLs don't contain a SKU and can't be resolved. Tell the
        // user to use the Share button on the product page instead of
        // copying the address bar.
        if (!_isNoonProductUrl(url)) {
          _showManualEntryHint(
            message: "That noon link doesn't include a product ID. "
                "On the noon page, tap the Share icon and copy the link from "
                "there — then paste it here.",
          );
          setState(() => _isFetchingProduct = false);
          return;
        }

        // Use the dedicated noon.com single-product API (RapidAPI noon6).
        final result = await ApiService.extractNoonProduct(url);
        if (!mounted) return;

        if (result['success'] != true) {
          final needsShare = result['needs_share_url'] == true;
          _showManualEntryHint(
            message: needsShare
                ? "That noon link doesn't include a product ID. "
                    "On the noon page, tap the Share icon and copy the link "
                    "from there — then paste it here."
                : "Noon couldn't read this link. Please open the product "
                    "on noon, tap Share, and paste the link from there.",
          );
          setState(() => _isFetchingProduct = false);
          return;
        }

        title   = result['name']?.toString() ?? '';
        serial  = result['good_sn']?.toString() ?? '';
        price   = (result['price'] as num?)?.toDouble() ?? 0.0;
        imageUrl = result['image']?.toString();
        if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;

        // If noon didn't return a usable image, try the images list
        if ((imageUrl == null || imageUrl.isEmpty) &&
            result['images'] is List && (result['images'] as List).isNotEmpty) {
          imageUrl = (result['images'] as List).first.toString();
        }
      } else {
        // Other sites: try the server-side universal extractor first
        // (handles Zara, H&M, Trendyol, Amazon, Mango, ASOS, AliExpress, etc.),
        // then fall back to the in-app web scraper.
        final serverResult = await ApiService.extractGenericProduct(url);

        Map<String, dynamic>? data;
        if (serverResult['success'] == true) {
          data = {
            'title': serverResult['name'],
            'price': serverResult['price'],
            'images': serverResult['images'] ?? const <String>[],
            'good_sn': serverResult['good_sn'],
            'sku': serverResult['sku'],
          };
        } else {
          // Fall back to the on-device scraper
          final fallback = await WebScraperService.fetchProductDetails(url);
          if (!mounted) return;

          if (fallback['success'] == true) {
            data = fallback['data'] as Map<String, dynamic>?;
          } else {
            // Auto-extraction failed for this site. Instead of showing a red
            // error, guide the user to add the product image and details
            // manually and keep the form usable.
            _showManualEntryHint();
            setState(() => _isFetchingProduct = false);
            return;
          }
        }

        if (data == null) {
          _showManualEntryHint();
          setState(() => _isFetchingProduct = false);
          return;
        }

        final images = data['images'] as List<dynamic>?;
        imageUrl = (images != null && images.isNotEmpty) ? images.first.toString() : null;
        title   = data['title']?.toString() ?? '';
        final priceRaw = data['price'];
        price   = (priceRaw is num) ? priceRaw.toDouble() : (double.tryParse(priceRaw?.toString() ?? '') ?? 0.0);
        serial  = data['good_sn']?.toString() ?? data['sku']?.toString() ?? '';
      }

      setState(() {
        _showCartItems = false;
        final codeNameParts = <String>[];
        if (serial.isNotEmpty) codeNameParts.add(serial);
        if (title.isNotEmpty) codeNameParts.add(title);
        _singleItemName = codeNameParts.join(' · ');
        _singleSerial = '';
        _singleQty = 1;
        _singlePrice = price;
        _singleProductImageUrl = imageUrl;
        _mainImage = null;
        _singlePriceController.text = price > 0 ? price.toStringAsFixed(2) : '';
      });

      // Download product image to file for submission
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final pageForReferer = isShein
              ? 'https://www.shein.com/'
              : isNoon
                  ? 'https://www.noon.com/'
                  : WebScraperService.normalizeProductUrl(url);
          final imageResponse = await http.get(
            Uri.parse(imageUrl),
            headers: {
              'Referer': pageForReferer,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
            },
          );
          if (imageResponse.statusCode == 200 && imageResponse.bodyBytes.isNotEmpty) {
            final tempDir = await Directory.systemTemp.createTemp('velox');
            final file = File('${tempDir.path}/product_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await file.writeAsBytes(imageResponse.bodyBytes);
            if (mounted) setState(() => _mainImage = file);
          } else {
            debugPrint('Image download failed: HTTP ${imageResponse.statusCode} for $imageUrl');
          }
        } catch (e) {
          debugPrint('Image download error: $e for $imageUrl');
          // keep _mainImage null; user can pick from gallery
        }
      }

      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.productDetailsExtracted),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
      if (mounted) {
        _showManualEntryHint();
      }
    }

    if (mounted) {
      setState(() => _isFetchingProduct = false);
    }
  }

  // Kept for any direct call sites; delegates to the auto-extract flow.
  Future<void> _extractSheinCart() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await _autoExtractShein(url);
  }

  void _addCartItem() {
    setState(() {
      _cartItems.add(CartItem());
      _showCartItems = true;
    });
  }

  void _removeCartItem(int index) {
    if (_cartItems.length > 1) {
      setState(() {
        _cartItems.removeAt(index);
      });
    }
  }

  Future<void> _pickImageForItem(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _cartItems[index] = _cartItems[index].copyWith(
          localImage: File(pickedFile.path),
        );
      });
    }
  }

  Future<void> _pickMainImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _mainImage = File(pickedFile.path);
      });
    }
  }

  double get _totalItemPrice => _cartItems.totalPrice;

  Future<void> _submitOrder() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequired)),
      );
      return;
    }

    final isSingleProduct = !_showCartItems;
    File? imageToSubmit;
    int qty;
    double price;
    String orderNote = _notesController.text;

    if (isSingleProduct) {
      if (_mainImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectImage)),
        );
        return;
      }
      imageToSubmit = _mainImage;
      qty = _singleQty;
      price = _singlePrice;
      // Item code/name goes in the note; color is sent in the API `color` field for the DB column.
      if (_singleItemName.isNotEmpty) {
        final itemDesc = '$_singleItemName x$qty';
        orderNote = orderNote.isEmpty ? itemDesc : '$orderNote\n$itemDesc';
      }
    } else {
      final hasValidItems = _cartItems.any((item) => item.isValid);
      if (_mainImage == null && !hasValidItems) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectImage)),
        );
        return;
      }
      imageToSubmit = _mainImage ?? (_cartItems.isNotEmpty ? _cartItems.first.localImage : null);
      if (imageToSubmit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectImage)),
        );
        return;
      }
      qty = 1; // SHEIN cart: each sub-item carries its own qty in item_details
      price = _totalItemPrice;
      if (_cartItems.isNotEmpty && _cartItems.any((item) => item.isValid)) {
        final itemsNote = _cartItems
            .where((item) => item.isValid)
            .map((item) => '${item.serialNumber.isNotEmpty ? "[${item.serialNumber}] " : ""}${item.itemName} x${item.quantity} @ ${item.price.toStringAsFixed(2)}')
            .join('\n');
        orderNote = orderNote.isEmpty ? itemsNote : '$orderNote\n\n--- Items ---\n$itemsNote';
      }
    }

    setState(() => _isLoading = true);

    try {
      // Build sub_items payload for SHEIN cart orders
      List<Map<String, dynamic>>? subItems;
      if (!isSingleProduct && _cartItems.any((item) => item.isValid)) {
        subItems = _cartItems
            .where((item) => item.isValid)
            .map((item) => {
                  'item_code': item.itemName,
                  'serial': item.serialNumber,
                  'image': item.imageUrl ?? '',
                  'qty': item.quantity,
                  'price': item.price,
                  'size': item.size ?? '',
                })
            .toList();
      }

      final response = await ApiService.addOrder(
        customerId: _user!.id,
        link: _urlController.text,
        size: _sizeTextController.text.trim().isEmpty ? 'N/A' : _sizeTextController.text.trim(),
        qty: qty,
        imageFile: imageToSubmit!,
        price: price > 0 ? price : null,
        color: isSingleProduct && _singleSerial.trim().isNotEmpty
            ? _singleSerial.trim()
            : null,
        note: orderNote.isNotEmpty ? orderNote : null,
        subItems: subItems,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.orderSubmitted),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          // If pushed as a route (from Home/Store/etc) pop normally.
          // If embedded as a bottom-nav tab, just reset the form.
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          } else {
            _resetForm();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? l10n.errorSubmittingOrder),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Resets all form fields back to initial state (used when screen is a tab, not a pushed route).
  void _resetForm() {
    setState(() {
      _urlController.clear();
      _notesController.clear();
      _singlePriceController.clear();
      _sizeTextController.clear();
      _mainImage = null;
      _cartItems = [];
      _showCartItems = false;
      _singleItemName = '';
      _singleSerial = '';
      _singleQty = 1;
      _singlePrice = 0.0;
      _singleProductImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Text(l10n.newOrder, style: TextStyle(color: context.textPrimaryColor)),
        actions: [
          if (_showCartItems && _cartItems.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.orderItemsSectionTitle(_cartItems.length),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && !mounted
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Directionality(
              // Force the entire form to LTR so all inputs behave left-to-right.
              // Arabic text in item names still renders correctly via BiDi.
              textDirection: TextDirection.ltr,
              child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product URL Section
                    _buildSectionTitle(l10n.productLink),
                    _buildTextField(
                      controller: _urlController,
                      hint: l10n.pasteProductLink,
                      keyboardType: TextInputType.url,
                      suffixIcon: _isFetchingProduct
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search, color: AppColors.primary),
                              onPressed: _onExtractFromLink,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 6),
                      child: Text(
                        l10n.productLinkHelper,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Single "Extract from link" button (`dataExtraction` is the same feature in ARB for reuse)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isFetchingProduct ? null : _onExtractFromLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: context.textPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: _isFetchingProduct
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.textPrimaryColor,
                                ),
                              )
                            : Icon(Icons.link, size: 20, color: context.textPrimaryColor),
                        label: Text(
                          _isFetchingProduct
                              ? l10n.extractingFromLink
                              : l10n.extractFromLink,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SHEIN cart: show Cart Items. Otherwise: single product (image + details).
                    if (_showCartItems) ...[
                      _buildCartItemsSection(l10n),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildSectionTitle(l10n.productImage),
                      _buildMainImagePicker(l10n),
                      const SizedBox(height: 16),
                      _buildSingleProductFields(l10n),
                      const SizedBox(height: 24),
                    ],

                    // Size — hidden for SHEIN cart (each item has its own size field)
                    if (!_showCartItems) ...[
                      _buildSectionTitle(l10n.selectSize),
                      _buildTextField(
                        controller: _sizeTextController,
                        hint: l10n.sizeHintExample,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Notes (allow RTL for Arabic input)
                    _buildSectionTitle(l10n.note),
                    _buildTextField(
                      controller: _notesController,
                      hint: l10n.enterNote,
                      maxLines: 3,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: context.textPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: context.textPrimaryColor)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, color: context.textPrimaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.submit,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            ),
    );
  }

  Widget _buildCartItemsSection(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Cart Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_cartItems.length})',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                // Clear all button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _cartItems = [];
                      _showCartItems = false;
                      _mainImage = null;
                    });
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Clear all'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: context.borderColor, height: 1),
          
          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Add each product from the cart. Item Price will be calculated automatically.',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          
          // Cart Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartItems.length,
            separatorBuilder: (_, __) => Divider(color: context.borderColor, height: 1),
            itemBuilder: (context, index) => _buildCartItemCard(index, l10n),
          ),
          
        ],
      ),
    );
  }

  Widget _buildSingleProductFields(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.productDetails,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSmallTextField(
            hint: l10n.itemCodeOrName,
            value: _singleItemName,
            onChanged: (value) => setState(() => _singleItemName = value),
          ),
          const SizedBox(height: 10),
          _buildSmallTextField(
            hint: l10n.color,
            value: _singleSerial,
            onChanged: (value) => setState(() => _singleSerial = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty', style: TextStyle(fontSize: 11, color: context.textSecondaryColor)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildQtyButton(Icons.remove, () {
                          if (_singleQty > 1) setState(() => _singleQty--);
                        }),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              border: Border.symmetric(horizontal: BorderSide(color: context.borderColor)),
                            ),
                            child: Text(
                              '$_singleQty',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                            ),
                          ),
                        ),
                        _buildQtyButton(Icons.add, () => setState(() => _singleQty++)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(int index, AppLocalizations l10n) {
    final item = _cartItems[index];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item number
          Text(
            'Item ${index + 1}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Image and main fields row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              GestureDetector(
                onTap: () => _pickImageForItem(index),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: item.hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.localImage != null
                              ? Image.file(item.localImage!, fit: BoxFit.cover)
                              : Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_outlined,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, 
                                color: context.textSecondaryColor, size: 24),
                            const SizedBox(height: 2),
                            Text('Photo', 
                                style: TextStyle(fontSize: 9, color: context.textSecondaryColor)),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Fields
              Expanded(
                child: Column(
                  children: [
                    // Item Name
                    _buildSmallTextField(
                      hint: l10n.itemCodeOrName,
                      value: item.itemName,
                      onChanged: (value) {
                        setState(() {
                          _cartItems[index] = item.copyWith(itemName: value);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
              // Quantity row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Qty', style: TextStyle(fontSize: 11, color: context.textSecondaryColor)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildQtyButton(Icons.remove, () {
                            if (item.quantity > 1) {
                              setState(() {
                                _cartItems[index] = item.copyWith(quantity: item.quantity - 1);
                              });
                            }
                          }),
                          Container(
                            width: 44,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              border: Border.symmetric(horizontal: BorderSide(color: context.borderColor)),
                            ),
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                            ),
                          ),
                          _buildQtyButton(Icons.add, () {
                            setState(() {
                              _cartItems[index] = item.copyWith(quantity: item.quantity + 1);
                            });
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border.all(color: context.borderColor),
          borderRadius: icon == Icons.remove
              ? const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
        ),
        child: Icon(icon, size: 16, color: context.textSecondaryColor),
      ),
    );
  }

  Widget _buildSmallTextField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return _StableLtrTextField(
      hint: hint,
      value: value,
      onChanged: onChanged,
      textDirection: textDirection,
    );
  }

  Widget _buildMainImagePicker(AppLocalizations l10n) {
    final hasImage = _mainImage != null || (_singleProductImageUrl != null && _singleProductImageUrl!.isNotEmpty);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _mainImage != null
                      ? Image.file(_mainImage!, fit: BoxFit.cover)
                      : Image.network(
                          _singleProductImageUrl!,
                          fit: BoxFit.cover,
                          headers: const {
                            'Referer': 'https://www.shein.com/',
                            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                          },
                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined, color: context.textSecondaryColor, size: 48),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _mainImage = null;
                      _singleProductImageUrl = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickMainImage,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: context.textSecondaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.chooseFromGallery,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return Directionality(
      textDirection: textDirection,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textDirection: textDirection,
          textAlign: TextAlign.left,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textSecondaryColor),
            hintTextDirection: textDirection,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }

}

/// A text field that keeps its own [TextEditingController] alive across parent
/// rebuilds, so typing never causes the text to reset or reverse direction.
class _StableLtrTextField extends StatefulWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final TextDirection textDirection;

  const _StableLtrTextField({
    required this.hint,
    required this.value,
    required this.onChanged,
    this.textDirection = TextDirection.ltr,
  });

  @override
  State<_StableLtrTextField> createState() => _StableLtrTextFieldState();
}

class _StableLtrTextFieldState extends State<_StableLtrTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_StableLtrTextField old) {
    super.didUpdateWidget(old);
    // Only update the controller when the value changed from OUTSIDE
    // (e.g. auto-extracted from API), not while the user is typing.
    if (old.value != widget.value && _controller.text != widget.value) {
      final selection = _controller.selection;
      _controller.text = widget.value;
      // Restore cursor to end or previous position, whichever is valid.
      final end = widget.value.length;
      _controller.selection = selection.extentOffset <= end
          ? selection
          : TextSelection.collapsed(offset: end);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.textDirection,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        child: TextField(
          controller: _controller,
          textDirection: widget.textDirection,
          textAlign: TextAlign.left,
          style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 13),
            hintTextDirection: widget.textDirection,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            isDense: true,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
