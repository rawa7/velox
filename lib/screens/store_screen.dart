import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/currency.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/shop_item_model.dart';
import '../models/shop_banner_model.dart';
import '../generated/app_localizations.dart';
import 'product_detail_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  User? _user;
  List<ShopItem> _items = [];
  List<ShopItem> _filteredItems = [];
  List<ShopBanner> _shopBanners = [];
  List<Brand> _brands = [];
  List<String> _categories = [];
  String? _selectedBrandId;
  String? _selectedCategory;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _user = await StorageService.getUser();

      // Load shop items
      final result = await ApiService.getShopItems(customerId: _user?.id);
      if (result['success'] == true) {
        _items = result['data'] as List<ShopItem>;
        _filteredItems = List.from(_items);

        // Extract unique brands
        final brandMap = <String, Brand>{};
        for (var item in _items) {
          if (item.brandId.isNotEmpty && !brandMap.containsKey(item.brandId)) {
            brandMap[item.brandId] = Brand(
              brandId: item.brandId,
              brandName: item.brandName,
              brandImageUrl: item.brandImageUrl,
            );
          }
        }
        _brands = brandMap.values.toList();

        // Extract unique categories
        final categorySet = <String>{};
        for (var item in _items) {
          if (item.itemCategory.isNotEmpty) {
            categorySet.add(item.itemCategory);
          }
        }
        _categories = categorySet.toList();
      }

      // Load shop banners
      final bannersResult = await ApiService.getShopBanners();
      if (bannersResult['success'] == true) {
        _shopBanners = bannersResult['data'] as List<ShopBanner>;
      }
    } catch (e) {
      debugPrint('Error loading store: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _filterByBrand(String? brandId) {
    setState(() {
      _selectedBrandId = brandId;
      _applyFilters();
    });
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _applySearch() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _items.where((item) {
        // Brand filter
        if (_selectedBrandId != null && item.brandId != _selectedBrandId) {
          return false;
        }
        // Category filter
        if (_selectedCategory != null && item.itemCategory != _selectedCategory) {
          return false;
        }
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          return item.itemName.toLowerCase().contains(searchQuery) ||
              item.brandName.toLowerCase().contains(searchQuery) ||
              item.itemCategory.toLowerCase().contains(searchQuery);
        }
        return true;
      }).toList();
    });
  }

  void _navigateToProductDetail(ShopItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(item: item),
      ),
    );
  }

  Future<void> _quickOrder(ShopItem item) async {
    final l10n = AppLocalizations.of(context)!;

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequired)),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.addToOrder,
                style: TextStyle(
                  color: ctx.textPrimaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName,
              style: TextStyle(
                color: ctx.textPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppCurrency.format(item.price, ctx),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Qty: 1',
              style: TextStyle(color: ctx.textSecondaryColor, fontSize: 13),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Placing order...'),
          ],
        ),
        duration: Duration(seconds: 10),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      // Download image
      File? imageFile;
      try {
        final resp = await http.get(Uri.parse(item.imagePath));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          final dir = await Directory.systemTemp.createTemp('velox_store');
          final f = File('${dir.path}/item_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await f.writeAsBytes(resp.bodyBytes);
          imageFile = f;
        }
      } catch (_) {}

      if (imageFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorSubmittingOrder),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final response = await ApiService.addOrder(
        customerId: _user!.id,
        link: item.imagePath,
        size: 'N/A',
        qty: 1,
        imageFile: imageFile,
        price: item.price,
        note: '${item.itemName} x1 @ ${AppCurrency.format(item.price, context)}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['success'] == true
                ? AppLocalizations.of(context)!.orderSubmitted
                : response['message'] ?? AppLocalizations.of(context)!.errorSubmittingOrder,
          ),
          backgroundColor: response['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorSubmittingOrder),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
              // Store Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.store,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Shop Banners
              if (_shopBanners.isNotEmpty && _user != null && !_user!.isBronzeAccount && !_user!.isSilverAccount)
                SliverToBoxAdapter(
                  child: Container(
                    height: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: PageView.builder(
                      onPageChanged: (index) {
                        setState(() => _currentBannerIndex = index);
                      },
                      itemCount: _shopBanners.length,
                      itemBuilder: (context, index) {
                        final banner = _shopBanners[index];
                        final imageUrl = banner.bannerImage.isNotEmpty ? banner.bannerImage : banner.productImage;
                        return GestureDetector(
                          onTap: () {
                            // Find product and navigate
                            final item = _items.firstWhere(
                              (i) => i.itemId == banner.productId.toString(),
                              orElse: () => _items.first,
                            );
                            _navigateToProductDetail(item);
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
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (imageUrl.isNotEmpty)
                                    Image.network(
                                      imageUrl,
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
                                          Colors.black.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          banner.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          banner.description,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Brand Filters
              if (_brands.isNotEmpty && _user != null && !_user!.isBronzeAccount && !_user!.isSilverAccount)
                SliverToBoxAdapter(
                  child: Container(
                    height: 118,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildBrandChip(
                          label: l10n.allBrands,
                          isSelected: _selectedBrandId == null,
                          onTap: () => _filterByBrand(null),
                        ),
                        ..._brands.map((brand) => _buildBrandChip(
                              label: brand.brandName,
                              imageUrl: brand.brandImageUrl,
                              isSelected: _selectedBrandId == brand.brandId,
                              onTap: () => _filterByBrand(brand.brandId),
                            )),
                      ],
                    ),
                  ),
                ),
              // Category Filters
              if (_categories.isNotEmpty && _user != null && !_user!.isBronzeAccount && !_user!.isSilverAccount)
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          label: 'All',
                          isSelected: _selectedCategory == null,
                          onTap: () => _filterByCategory(null),
                        ),
                        ..._categories.map((cat) => _buildCategoryChip(
                              label: cat,
                              isSelected: _selectedCategory == cat,
                              onTap: () => _filterByCategory(cat),
                            )),
                      ],
                    ),
                  ),
                ),
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _applySearch(),
                      style: TextStyle(color: context.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: l10n.searchProducts,
                        hintStyle: TextStyle(color: context.textSecondaryColor),
                        prefixIcon: Icon(Icons.search, color: context.textSecondaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
              // Products Grid
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_filteredItems.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: context.textSecondaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noProductsFound,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 16,
                          ),
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
                      (context, index) => _buildProductCard(_filteredItems[index]),
                      childCount: _filteredItems.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandChip({
    required String label,
    String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : context.brandLogoTileBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.shopping_bag,
                          size: 28,
                          color: isSelected ? AppColors.primary : context.textSecondaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.apps,
                      size: 28,
                      color: isSelected ? AppColors.primary : context.textSecondaryColor,
                    ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppColors.primary : context.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: context.surfaceColor,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : context.textSecondaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.borderColor,
        ),
      ),
    );
  }

  Widget _buildProductCard(ShopItem item) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
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
                      child: Icon(
                        Icons.image_not_supported,
                        color: context.textSecondaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 13,
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
                        Text(
                          AppCurrency.format(item.price, context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _quickOrder(item),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: AppColors.primary,
                              size: 18,
                            ),
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

