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
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
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

  void _orderCurrentPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrderScreen(initialUrl: _currentUrl),
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
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            IconButton(
              icon: const Icon(Icons.refresh, size: 22),
              color: AppColors.textPrimary,
              onPressed: _refresh,
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 22),
              color: AppColors.textPrimary,
              onPressed: () {
                _controller.loadRequest(Uri.parse(widget.website.link));
              },
            ),
            // Order button
            ElevatedButton.icon(
              onPressed: _orderCurrentPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text(l10n.order),
            ),
          ],
        ),
      ),
    );
  }
}
