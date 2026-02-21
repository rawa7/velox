import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.website.link;
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) async {
            // Resolve the real URL via JS in case of SPA routing
            String resolvedUrl = url;
            try {
              final jsUrl = await _controller.currentUrl();
              if (jsUrl != null && jsUrl.isNotEmpty) resolvedUrl = jsUrl;
            } catch (_) {}
            setState(() {
              _isLoading = false;
              _currentUrl = resolvedUrl;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.website.link));
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

  Future<void> _orderCurrentPage() async {
    // For SPAs like SHEIN, window.location.href reflects client-side navigation
    // while the Flutter NavigationDelegate callback may lag behind.
    String url = _currentUrl;
    String name = '';
    String imageUrl = '';
    String serial = '';

    try {
      final jsResult = await _controller.runJavaScriptReturningResult(r'''
        (function() {
          var d = { url: '', name: '', image: '', sn: '' };
          var pRx = /-p-(\d{5,})/;

          // ── URL ────────────────────────────────────────────────────────
          if (pRx.test(window.location.href)) d.url = window.location.href;
          if (!d.url) { try { var c = document.querySelector('link[rel="canonical"]'); if (c && pRx.test(c.href)) d.url = c.href; } catch(e){} }
          if (!d.url) { try { var links = document.querySelectorAll('a[href]'); for (var i=0;i<links.length;i++) { if (pRx.test(links[i].href)) { d.url = links[i].href; break; } } } catch(e){} }
          if (!d.url) d.url = window.location.href;

          // ── Product data from SHEIN JS globals ─────────────────────────
          var sources = [];
          try { if (window.productIntroData && window.productIntroData.detail) sources.push(window.productIntroData.detail); } catch(e){}
          try { if (window.gbRawData) sources.push(window.gbRawData); } catch(e){}
          try { if (window.SaPageInfo && window.SaPageInfo.page_param) sources.push(window.SaPageInfo.page_param); } catch(e){}

          for (var s=0; s<sources.length; s++) {
            var src = sources[s];
            if (!d.name && src.goods_name) d.name = src.goods_name;
            if (!d.sn   && src.goods_sn)   d.sn   = src.goods_sn;
            if (!d.image && src.goods_img)  d.image = src.goods_img;
            if (d.name && d.sn && d.image) break;
          }

          // ── Fallback: og: meta tags ─────────────────────────────────────
          try {
            if (!d.image) { var m=document.querySelector('meta[property="og:image"]'); if(m) d.image = m.getAttribute('content')||''; }
            if (!d.name)  { var t=document.querySelector('meta[property="og:title"]');  if(t) d.name  = (t.getAttribute('content')||'').replace(/\s*[\|\-]\s*SHEIN.*$/i,'').trim(); }
          } catch(e){}

          // ── Fallback: DOM elements ──────────────────────────────────────
          try {
            if (!d.name) { var h=document.querySelector('h1'); if(h) d.name=h.innerText.trim(); }
            if (!d.image) {
              var imgs = document.querySelectorAll('.product-intro__main-pic img, .swiper-slide img, .j-expose__product-intro__main-img img');
              for (var ii=0;ii<imgs.length;ii++) { var src2=imgs[ii].src||imgs[ii].getAttribute('data-src')||''; if (src2.includes('ltwebstatic')) { d.image=src2; break; } }
            }
          } catch(e){}

          // Normalize protocol-relative image URL
          if (d.image && d.image.indexOf('//') === 0) d.image = 'https:' + d.image;

          return JSON.stringify(d);
        })()
      ''');

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

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrderScreen(
          initialUrl: url,
          initialName: name.isNotEmpty ? name : null,
          initialImageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          initialSerial: serial.isNotEmpty ? serial : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.website.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_currentUrl.isNotEmpty)
              Text(
                _currentUrl,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        // Home + Refresh moved to top-right
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 22),
            color: AppColors.textPrimary,
            tooltip: 'Home',
            onPressed: () => _controller.loadRequest(Uri.parse(widget.website.link)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            color: AppColors.textPrimary,
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _isLoading
              ? LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: AppColors.surface,
                  color: AppColors.primary,
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
          top: 8,
          left: 16,
          right: 16,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              color: AppColors.textPrimary,
              onPressed: _goBack,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              color: AppColors.textPrimary,
              onPressed: _goForward,
            ),
            const SizedBox(width: 8),
            // Order button fills remaining width
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _orderCurrentPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(
                  l10n.order,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
