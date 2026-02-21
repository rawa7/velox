import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/web_scraper_service.dart';
import '../models/user_model.dart';
import '../models/size_model.dart';
import '../models/currency_model.dart';
import '../models/cart_item_model.dart';
import '../generated/app_localizations.dart';

class AddOrderScreen extends StatefulWidget {
  final String? initialUrl;

  const AddOrderScreen({super.key, this.initialUrl});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  User? _user;
  List<Size> _sizes = [];
  List<Currency> _currencies = [];
  Size? _selectedSize;
  Currency? _selectedCurrency;
  
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetchingProduct = false;
  File? _mainImage;
  
  // Cart Items
  List<CartItem> _cartItems = [];
  bool _showCartItems = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
    // Start with one empty cart item
    _cartItems.add(CartItem());
  }

  @override
  void dispose() {
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _user = await StorageService.getUser();

      // Load sizes
      final sizesResult = await ApiService.getSizes();
      if (sizesResult['success'] == true) {
        _sizes = sizesResult['sizes'] as List<Size>;
      }

      // Load currencies
      final currenciesResult = await ApiService.getCurrencies();
      if (currenciesResult['success'] == true) {
        _currencies = currenciesResult['currencies'] as List<Currency>;
        _selectedCurrency = _currencies.firstWhere(
          (c) => c.currencyCode.toUpperCase() == 'USD',
          orElse: () => _currencies.first,
        );
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProductDetails() async {
    if (_urlController.text.isEmpty) return;

    setState(() => _isFetchingProduct = true);

    try {
      final details = await WebScraperService.fetchProductDetails(_urlController.text);
      
      if (details != null && mounted) {
        setState(() {
          // If we have a single product, update the first cart item
          if (_cartItems.isNotEmpty) {
            _cartItems[0] = _cartItems[0].copyWith(
              itemName: details['title'] as String? ?? '',
              price: (details['price'] as num?)?.toDouble() ?? 0.0,
              imageUrl: details['image'] as String?,
              serialNumber: details['good_sn'] as String? ?? details['sku'] as String? ?? '',
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product details extracted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not extract product details'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isFetchingProduct = false);
    }
  }

  Future<void> _extractSheinCart() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a SHEIN link to extract cart items'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isFetchingProduct = true);

    try {
      // Call the SHEIN extraction API
      final result = await ApiService.extractSheinCart(_urlController.text);
      
      if (mounted) {
        if (result['success'] == true) {
          final items = result['items'] as List<dynamic>;
          
          if (items.isNotEmpty) {
            setState(() {
              _cartItems = items.map((item) => CartItem.fromSheinJson(item as Map<String, dynamic>)).toList();
              _showCartItems = true;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Successfully extracted ${items.length} items from SHEIN cart!'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No items found in the cart. The link may be empty or expired.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Could not extract cart items'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error extracting SHEIN cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isFetchingProduct = false);
    }
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

    // Check if we have at least one valid item or main image
    final hasValidItems = _cartItems.any((item) => item.isValid);
    if (_mainImage == null && !hasValidItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectImage)),
      );
      return;
    }

    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectSize)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get image to submit - use main image or first cart item's image
      File? imageToSubmit = _mainImage;
      if (imageToSubmit == null && _cartItems.isNotEmpty) {
        imageToSubmit = _cartItems.first.localImage;
      }
      
      if (imageToSubmit == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.pleaseSelectImage)),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Build note with cart items info
      String orderNote = _notesController.text;
      if (_cartItems.isNotEmpty && _cartItems.any((item) => item.isValid)) {
        final itemsNote = _cartItems
            .where((item) => item.isValid)
            .map((item) => '${item.serialNumber.isNotEmpty ? "[${item.serialNumber}] " : ""}${item.itemName} x${item.quantity} @ \$${item.price.toStringAsFixed(2)}')
            .join('\n');
        orderNote = orderNote.isEmpty ? itemsNote : '$orderNote\n\n--- Items ---\n$itemsNote';
      }

      final response = await ApiService.addOrder(
        customerId: _user!.id,
        link: _urlController.text,
        size: _selectedSize!.name,
        qty: _cartItems.totalQuantity > 0 ? _cartItems.totalQuantity : 1,
        imageFile: imageToSubmit,
        price: _totalItemPrice > 0 ? _totalItemPrice : null,
        currencyId: _selectedCurrency?.id,
        note: orderNote.isNotEmpty ? orderNote : null,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.orderSubmitted),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(l10n.newOrder),
        actions: [
          if (_cartItems.length > 1)
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
                    '${_cartItems.length} items',
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
      body: _isLoading && _sizes.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
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
                              onPressed: _fetchProductDetails,
                            ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 6),
                      child: Text(
                        'Paste SHEIN cart/share link to auto-extract items',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Extract Cart Button (for SHEIN)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isFetchingProduct ? null : _extractSheinCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: _isFetchingProduct
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome, size: 20),
                            label: Text(
                              _isFetchingProduct ? 'Extracting...' : 'Auto-Extract from SHEIN Cart',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Cart Items Section
                    _buildCartItemsSection(l10n),
                    const SizedBox(height: 24),

                    // Main Product Image (if no cart item images)
                    _buildSectionTitle(l10n.productImage),
                    _buildMainImagePicker(l10n),
                    const SizedBox(height: 20),

                    // Currency Selection
                    _buildSectionTitle(l10n.currency),
                    _buildCurrencyDropdown(),
                    const SizedBox(height: 20),

                    // Size Selection
                    if (_sizes.isNotEmpty) ...[
                      _buildSectionTitle(l10n.selectSize),
                      _buildSizeSelector(),
                      const SizedBox(height: 20),
                    ],

                    // Notes
                    _buildSectionTitle(l10n.note),
                    _buildTextField(
                      controller: _notesController,
                      hint: l10n.enterNote,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),

                    // Total Price Display
                    if (_totalItemPrice > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.totalPrice} (${_cartItems.totalQuantity} items):',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '\$${_totalItemPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.submit,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildCartItemsSection(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                    const Text(
                      'Cart Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _addCartItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          
          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Add each product from the cart. Item Price will be calculated automatically.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          
          // Cart Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartItems.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
            itemBuilder: (context, index) => _buildCartItemCard(index, l10n),
          ),
          
          // Total Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total (Item Price):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '\$${_totalItemPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
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
          // Item number and delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (_cartItems.length > 1)
                IconButton(
                  onPressed: () => _removeCartItem(index),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
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
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: item.hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.localImage != null
                              ? Image.file(item.localImage!, fit: BoxFit.cover)
                              : Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, 
                                color: AppColors.textSecondary, size: 24),
                            SizedBox(height: 2),
                            Text('Photo', 
                                style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Fields
              Expanded(
                child: Column(
                  children: [
                    // Serial Number (good_sn)
                    _buildSmallTextField(
                      hint: 'Serial # (good_sn)',
                      value: item.serialNumber,
                      onChanged: (value) {
                        setState(() {
                          _cartItems[index] = item.copyWith(serialNumber: value);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Item Name
                    _buildSmallTextField(
                      hint: 'Item Code/Name',
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
          
          // Quantity, Price, Subtotal row
          Row(
            children: [
              // Quantity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Qty', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              border: Border.symmetric(
                                horizontal: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
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
              ),
              const SizedBox(width: 12),
              // Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        controller: TextEditingController(
                          text: item.price > 0 ? item.price.toStringAsFixed(2) : '',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _cartItems[index] = item.copyWith(
                              price: double.tryParse(value) ?? 0,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Subtotal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subtotal', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
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
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSmallTextField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: TextEditingController(text: value),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMainImagePicker(AppLocalizations l10n) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: _mainImage != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_mainImage!, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _mainImage = null),
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
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.chooseFromGallery,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Currency>(
          value: _selectedCurrency,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          items: _currencies.map((currency) {
            return DropdownMenuItem(
              value: currency,
              child: Text(currency.currencyCode),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCurrency = value);
          },
        ),
      ),
    );
  }

  Widget _buildSizeSelector() {
    return GestureDetector(
      onTap: () => _showSizeSearchDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedSize != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSize?.name ?? 'Select Size...',
              style: TextStyle(
                fontSize: 15,
                color: _selectedSize != null 
                    ? AppColors.textPrimary 
                    : AppColors.textHint,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _selectedSize != null 
                  ? AppColors.primary 
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSizeSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SizeSearchSheet(
        sizes: _sizes,
        selectedSize: _selectedSize,
        onSizeSelected: (size) {
          setState(() => _selectedSize = size);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// Searchable Size Selection Bottom Sheet
class _SizeSearchSheet extends StatefulWidget {
  final List<Size> sizes;
  final Size? selectedSize;
  final ValueChanged<Size> onSizeSelected;

  const _SizeSearchSheet({
    required this.sizes,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  State<_SizeSearchSheet> createState() => _SizeSearchSheetState();
}

class _SizeSearchSheetState extends State<_SizeSearchSheet> {
  final _searchController = TextEditingController();
  List<Size> _filteredSizes = [];

  @override
  void initState() {
    super.initState();
    _filteredSizes = widget.sizes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSizes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSizes = widget.sizes;
      } else {
        _filteredSizes = widget.sizes
            .where((size) => size.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Size',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search sizes...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _filterSizes('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _filterSizes,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Size count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredSizes.length} sizes found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Size List
          Expanded(
            child: _filteredSizes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No sizes found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredSizes.length,
                    itemBuilder: (context, index) {
                      final size = _filteredSizes[index];
                      final isSelected = widget.selectedSize?.id == size.id;
                      
                      return GestureDetector(
                        onTap: () => widget.onSizeSelected(size),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primary.withOpacity(0.15) 
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  size.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected 
                                        ? AppColors.primary 
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
