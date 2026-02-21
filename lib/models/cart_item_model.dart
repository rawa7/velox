import 'dart:io';

/// Model for cart sub-items in an order
class CartItem {
  String? id;
  String serialNumber; // good_sn from API
  String itemName;
  int quantity;
  double price;
  String? imageUrl; // URL from API extraction
  File? localImage; // Locally selected image
  String? color;
  String? size;
  String? note;

  CartItem({
    this.id,
    this.serialNumber = '',
    this.itemName = '',
    this.quantity = 1,
    this.price = 0.0,
    this.imageUrl,
    this.localImage,
    this.color,
    this.size,
    this.note,
  });

  /// Calculate subtotal for this item
  double get subtotal => price * quantity;

  /// Check if item has an image (either URL or local file)
  bool get hasImage => (imageUrl != null && imageUrl!.isNotEmpty) || localImage != null;

  /// Check if item is valid for submission
  bool get isValid => itemName.isNotEmpty || serialNumber.isNotEmpty;

  /// Create from JSON (API response)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString(),
      serialNumber: json['code']?.toString() ?? json['good_sn']?.toString() ?? json['serial']?.toString() ?? '',
      itemName: json['name']?.toString() ?? json['item_name']?.toString() ?? '',
      quantity: int.tryParse(json['qty']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image']?.toString() ?? json['product_img']?.toString(),
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      note: json['note']?.toString(),
    );
  }

  /// Create from SHEIN extraction API response
  factory CartItem.fromSheinJson(Map<String, dynamic> json) {
    return CartItem(
      serialNumber: json['code']?.toString() ?? json['good_sn']?.toString() ?? '',
      itemName: json['name']?.toString() ?? '',
      quantity: int.tryParse(json['qty']?.toString() ?? '1') ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image']?.toString(),
      size: json['size']?.toString() ?? json['good_attr']?.toString() ?? json['attr_value']?.toString(),
    );
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'good_sn': serialNumber,
      'item_name': itemName,
      'qty': quantity,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (note != null) 'note': note,
    };
  }

  /// Create a copy with updated values
  CartItem copyWith({
    String? id,
    String? serialNumber,
    String? itemName,
    int? quantity,
    double? price,
    String? imageUrl,
    File? localImage,
    String? color,
    String? size,
    String? note,
  }) {
    return CartItem(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      localImage: localImage ?? this.localImage,
      color: color ?? this.color,
      size: size ?? this.size,
      note: note ?? this.note,
    );
  }
}

/// Extension for list of cart items
extension CartItemListExtension on List<CartItem> {
  /// Calculate total price of all items
  double get totalPrice => fold(0.0, (sum, item) => sum + item.subtotal);

  /// Get total quantity of all items
  int get totalQuantity => fold(0, (sum, item) => sum + item.quantity);

  /// Check if all items are valid
  bool get allValid => every((item) => item.isValid);
}

