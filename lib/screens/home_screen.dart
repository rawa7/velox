import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/website_model.dart';
import '../models/banner_model.dart';
import '../generated/app_localizations.dart';
import 'add_order_screen.dart';
import 'my_orders_screen.dart';
import 'website_view_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  List<Website> _websites = [];
  List<BannerItem> _banners = [];
  bool _isLoading = true;
  int _currentBannerIndex = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await StorageService.getUser();
      _user = user;

      // Load websites
      final websitesResult = await ApiService.getWebsites();
      if (websitesResult['success'] == true) {
        _websites = websitesResult['websites'] as List<Website>;
      }

      // Load banners
      if (user != null) {
        final bannersResult = await ApiService.getBanners(user.id.toString());
        if (bannersResult['success'] == true) {
          final bannersList = bannersResult['banners'] as List;
          _banners = bannersList.map((b) => BannerItem.fromJson(b)).toList();
        }

        // Load notification count
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
    }
  }

  void _navigateToAddOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddOrderScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.3),
                                  AppColors.secondary.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.local_shipping,
                                    color: AppColors.primary,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: AppColors.primaryGradient,
                                ).createShader(bounds),
                                child: const Text(
                                  'Velox',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (_user != null)
                                Text(
                                  '${l10n.hello}, ${_user!.name ?? ""}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
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
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textPrimary,
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
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
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
              // Banner Section
              if (_banners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: PageView.builder(
                      onPageChanged: (index) {
                        setState(() => _currentBannerIndex = index);
                      },
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
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
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (banner.image.isNotEmpty)
                                  Image.network(
                                    banner.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(),
                                  ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Banner indicators
              if (_banners.length > 1)
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
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              // Quick Actions
              if (_user != null && _user!.isBronzeAccount != true)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.add_shopping_cart,
                            label: l10n.newOrder,
                            gradient: AppColors.primaryGradient,
                            onTap: _navigateToAddOrder,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.receipt_long,
                            label: l10n.myOrders,
                            color: AppColors.surface,
                            iconColor: AppColors.primary,
                            onTap: _navigateToMyOrders,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Websites Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.websites,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_websites.length} ${l10n.websites.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Loading or Websites Grid
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
                        Icon(
                          Icons.web_asset_off,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noWebsitesAvailable,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildWebsiteCard(_websites[index]),
                      childCount: _websites.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    List<Color>? gradient,
    Color? color,
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
          color: gradient == null ? color : null,
          borderRadius: BorderRadius.circular(16),
          border: gradient == null ? Border.all(color: AppColors.border) : null,
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
                color: gradient != null ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteCard(Website website) {
    return GestureDetector(
      onTap: () => _openWebsite(website),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: website.imageUrl != null && website.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        website.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.language,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.language,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                website.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

