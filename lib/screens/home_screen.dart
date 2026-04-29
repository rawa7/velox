import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/website_model.dart';
import '../models/banner_model.dart';
import '../models/shop_item_model.dart';
import '../generated/app_localizations.dart';
import '../constants/currency.dart';
import 'add_order_screen.dart';
import 'my_orders_screen.dart';
import 'website_view_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onNavigateToNewOrder,
    this.silverExperience = false,
  });

  /// When set (e.g. from MainNavigation), tapping "New Order" switches to the
  /// New Order tab instead of pushing a route. Null for Silver accounts.
  final VoidCallback? onNavigateToNewOrder;

  /// When true and there is no logged-in user, show silver-style home (shop
  /// grid, no external websites section) — used for guest "skip account".
  final bool silverExperience;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  List<Website> _websites = [];
  List<BannerItem> _banners = [];
  List<ShopItem> _shopItems = [];
  bool _isLoading = true;
  int _currentBannerIndex = 0;
  int _unreadNotificationCount = 0;
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;

  bool get _isSilver =>
      _user?.isSilverAccount ?? widget.silverExperience;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  void _startBannerSlideshow() {
    _bannerTimer?.cancel();
    if (_banners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.length <= 1) return;
      final next = (_currentBannerIndex + 1) % _banners.length;
      _bannerPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await StorageService.getUser();
      _user = user;

      if (_isSilver) {
        // Silver: load shop items instead of websites
        final shopResult = await ApiService.getShopItems(customerId: user?.id);
        if (shopResult['success'] == true) {
          final all = shopResult['data'] as List<ShopItem>;
          _shopItems = all.take(10).toList();
        }
      } else {
        // All other types: load external websites
        final websitesResult = await ApiService.getWebsites();
        if (websitesResult['success'] == true) {
          _websites = websitesResult['websites'] as List<Website>;
        }
      }

      // Promotional banners: non-silver only (silver sees app logo in banner area only).
      if (!_isSilver) {
        final bannersResult = await ApiService.getBanners(user?.id.toString() ?? '');
        if (bannersResult['success'] == true) {
          final bannersList = bannersResult['banners'] as List;
          _banners = bannersList.map((b) => BannerItem.fromJson(b)).toList();
        }
      } else {
        _banners = [];
      }

      if (user != null) {
        final notifResult = await ApiService.getNotifications(customerId: user.id);
        if (notifResult['success'] == true) {
          _unreadNotificationCount = notifResult['data'].unreadCount;
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _startBannerSlideshow();
    }
  }

  void _navigateToAddOrder() {
    if (widget.onNavigateToNewOrder != null) {
      widget.onNavigateToNewOrder!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddOrderScreen()),
      );
    }
  }

  void _navigateToMyOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
    );
  }

  void _openWebsite(Website website) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebsiteViewScreen(website: website),
      ),
    );
  }

  void _openShopItem(ShopItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(item: item),
      ),
    );
  }

  Map<String, List<Website>> get _websitesByCountry {
    // Sort all websites by orderId first
    final sorted = [..._websites]..sort((a, b) => a.orderId.compareTo(b.orderId));

    final map = <String, List<Website>>{};
    for (final w in sorted) {
      final key = w.country.trim().isEmpty ? 'Other' : w.country;
      map.putIfAbsent(key, () => []).add(w);
    }

    // Order countries by the smallest orderId within each group
    final countries = map.keys.toList()
      ..sort((a, b) => map[a]!.first.orderId.compareTo(map[b]!.first.orderId));

    return Map.fromEntries(countries.map((k) => MapEntry(k, map[k]!)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          backgroundColor: context.surfaceColor,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              width: 78,
                              height: 78,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.local_shipping,
                                      color: AppColors.primary, size: 78),
                            ),
                            if (_user != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${l10n.hello}, ${_user!.name ?? ""}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                          _loadData();
                        },
                        icon: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            if (_unreadNotificationCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    _unreadNotificationCount > 9
                                        ? '9+'
                                        : '$_unreadNotificationCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Banners ─────────────────────────────────────────────────
              if (_isSilver || _banners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: PageView.builder(
                      controller: _bannerPageController,
                      onPageChanged: (index) {
                        setState(() => _currentBannerIndex = index);
                      },
                      itemCount: _isSilver ? 1 : _banners.length,
                      itemBuilder: (context, index) {
                        if (_isSilver) {
                          return _buildSilverLogoBannerSlide(context);
                        }
                        final banner = _banners[index];
                        return GestureDetector(
                          onTap: () {
                            final uri = Uri.tryParse(banner.link);
                            if (banner.link.isNotEmpty && uri != null) {
                              launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.secondary.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (banner.image.isNotEmpty)
                                    Image.network(
                                      banner.image,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: AppColors.surface,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (ctx, __, ___) => _bannerPlaceholder(ctx),
                                    )
                                  else
                                    _bannerPlaceholder(context),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Banner dots
              if (!_isSilver && _banners.length > 1)
                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _banners.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        width: _currentBannerIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentBannerIndex == index
                              ? AppColors.primary
                              : context.borderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Quick Actions (non-bronze, non-silver) ───────────────────
              if (_user != null && !_user!.isBronzeAccount && !_isSilver)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            context: context,
                            icon: Icons.add_shopping_cart,
                            label: l10n.newOrder,
                            iconColor: AppColors.primary,
                            onTap: _navigateToAddOrder,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            context: context,
                            icon: Icons.receipt_long,
                            label: l10n.myOrders,
                            iconColor: AppColors.primary,
                            onTap: _navigateToMyOrders,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Silver: My Orders quick action only ──────────────────────
              if (_isSilver)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildQuickAction(
                      context: context,
                      icon: Icons.receipt_long,
                      label: l10n.myOrders,
                      iconColor: AppColors.primary,
                      onTap: _navigateToMyOrders,
                    ),
                  ),
                ),

              // ── Silver: Featured Products ────────────────────────────────
              if (_isSilver) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${_shopItems.length} items',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_shopItems.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No products available',
                            style: TextStyle(color: context.textSecondaryColor, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) => _buildShopItemCard(ctx, _shopItems[index]),
                        childCount: _shopItems.length,
                      ),
                    ),
                  ),
              ],

              // ── Non-silver: Websites section ─────────────────────────────
              if (!_isSilver) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.websites,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${_websites.length} ${l10n.websites.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_websites.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.web_asset_off, size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noWebsitesAvailable,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._websitesByCountry.entries.expand((entry) {
                    final country = entry.key;
                    final list = entry.value;
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                country.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimaryColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            // Wider vs height → shorter rows (less vertical space per site)
                            childAspectRatio: 1.95,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, index) => _buildWebsiteCard(ctx, list[index]),
                            childCount: list.length,
                          ),
                        ),
                      ),
                    ];
                  }),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    List<Color>? gradient,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient != null
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradient == null ? context.surfaceColor : null,
          borderRadius: BorderRadius.circular(16),
          border: gradient == null ? Border.all(color: context.borderColor) : null,
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: gradient != null ? Colors.white : iconColor,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: gradient != null ? Colors.white : context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Silver accounts: promotional images hidden — logo only on the same gradient shell as the carousel.
  Widget _buildSilverLogoBannerSlide(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.secondary.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.local_shipping_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerPlaceholder(BuildContext context) {
    return Container(
      color: context.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: AppColors.primary.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text('Banner', style: TextStyle(fontSize: 14, color: context.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteCard(BuildContext context, Website website) {
    final hasImage = website.imageUrl != null && website.imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => _openWebsite(website),
      child: Container(
        decoration: BoxDecoration(
          color: context.homeWebsiteTileBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.08 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: hasImage
                ? Image.network(
                    website.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.language,
                        color: Colors.grey.shade600,
                        size: 28,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.language,
                      color: Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopItemCard(BuildContext context, ShopItem item) {
    return GestureDetector(
      onTap: () => _openShopItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    item.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.image_not_supported,
                          color: context.textSecondaryColor, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.price > 0
                                ? AppCurrency.format(item.price, context)
                                : '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
