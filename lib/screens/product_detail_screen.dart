import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';
import '../constants/currency.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/shop_item_model.dart';
import '../models/user_model.dart';
import '../generated/app_localizations.dart';

class ProductDetailScreen extends StatefulWidget {
  final ShopItem item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  User? _user;
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _user = await StorageService.getUser();
    } catch (e) {
      debugPrint('Error loading product detail: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<File?> _downloadImageToFile(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final tempDir = await Directory.systemTemp.createTemp('velox_product');
      final ext = imageUrl.contains('.png') ? 'png' : 'jpg';
      final file = File('${tempDir.path}/product_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('Download image error: $e');
      return null;
    }
  }

  Future<void> _orderProduct() async {
    final l10n = AppLocalizations.of(context)!;
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequired)),
      );
      return;
    }

    final totalPrice = widget.item.price * _quantity;
    final totalFormatted = AppCurrency.format(totalPrice, context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(l10n.addToOrder, style: TextStyle(color: context.textPrimaryColor)),
        content: Text(
          '${widget.item.itemName}\n\n${l10n.quantity}: $_quantity\n${l10n.totalPrice}: $totalFormatted',
          style: TextStyle(color: context.textSecondaryColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final imageFile = await _downloadImageToFile(widget.item.imagePath);
      if (imageFile == null || !mounted) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorSubmittingOrder),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final note = '${widget.item.itemName} x$_quantity @ ${AppCurrency.format(widget.item.price, context)}';
      final response = await ApiService.addOrder(
        customerId: _user!.id,
        link: widget.item.imagePath,
        size: 'N/A',
        qty: _quantity,
        imageFile: imageFile,
        price: totalPrice,
        note: note,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderSubmitted),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? l10n.errorSubmittingOrder),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Order error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSubmittingOrder),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalPrice = widget.item.price * _quantity;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Product Image — starts below the status bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              color: context.surfaceColor,
              child: Image.network(
                widget.item.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
          ),
          // Product Details
          Positioned(
            top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height * 0.4,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    if (widget.item.brandName.isNotEmpty)
                      Text(
                        widget.item.brandName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Product Name
                    Text(
                      widget.item.itemName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      AppCurrency.format(widget.item.price, context),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Description
                    if (widget.item.itemDescription.isNotEmpty) ...[
                      Text(
                        l10n.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.itemDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondaryColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Quantity Selector
                    Text(
                      l10n.quantity,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _decrementQuantity,
                                icon: Icon(
                                  Icons.remove,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _quantity.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _incrementQuantity,
                                icon: Icon(
                                  Icons.add,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.totalPrice,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            Text(
                              AppCurrency.format(totalPrice, context),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
          // Add to Order Button
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _orderProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: context.textPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.textPrimaryColor,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_checkout, color: context.textPrimaryColor),
                          const SizedBox(width: 10),
                          Text(
                            l10n.addToOrder,
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
          ),
        ],
      ),
    );
  }
}
