// lib/features/cms/models/product_model.dart
//
// Pooja Kit product. Maps to the backend `Product` resource managed via
// `POST /api/v1/products/create-product` (multipart/form-data).

class ProductItem {
  const ProductItem({
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  final String itemName;
  final String quantity; // backend treats this as a string ("1", "50")
  final String unit; // packet, grams, ml, …

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'quantity': quantity,
        'unit': unit,
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        itemName: json['itemName']?.toString() ?? '',
        quantity: json['quantity']?.toString() ?? '',
        unit: json['unit']?.toString() ?? '',
      );

  ProductItem copyWith({String? itemName, String? quantity, String? unit}) =>
      ProductItem(
        itemName: itemName ?? this.itemName,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
      );
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description = '',
    this.items = const <ProductItem>[],
    this.stockQuantity = 0,
    this.price = 0,
    this.salePrice,
    this.currency = 'ZAR',
    this.category = '',
    this.status = 'PENDING',
    this.productStatus = 'ACTIVE',
    this.isFeatured = false,
    this.imageUrl,
    this.createdAt,
    this.createdBy,
  });

  final String id;
  final String title;
  final String slug;
  final String description;
  final List<ProductItem> items;
  final int stockQuantity;
  final num price;
  final num? salePrice;
  final String currency;
  final String category;
  /// Review status assigned by the backend / super admin.
  /// Values: PENDING | APPROVED | REJECTED.
  final String status;
  /// Admin-controlled lifecycle.
  /// Values: ACTIVE | INACTIVE.
  final String productStatus;
  final bool isFeatured;
  final String? imageUrl;
  final String? createdAt;
  /// Backend `_id` of the user who created this product. Used by the UI
  /// to detect whether the current super-admin is also the creator (in
  /// which case the action set switches to "Publish Now / Queue").
  final String? createdBy;

  bool get isActive => productStatus.toUpperCase() == 'ACTIVE';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isQueued => status.toUpperCase() == 'QUEUED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  ProductModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    List<ProductItem>? items,
    int? stockQuantity,
    num? price,
    num? salePrice,
    String? currency,
    String? category,
    String? status,
    String? productStatus,
    bool? isFeatured,
    String? imageUrl,
    String? createdAt,
    String? createdBy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      items: items ?? this.items,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      status: status ?? this.status,
      productStatus: productStatus ?? this.productStatus,
      isFeatured: isFeatured ?? this.isFeatured,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get displayPrice {
    final base = salePrice ?? price;
    return '$currency ${base.toString()}';
  }

  static String _str(
    Map<String, dynamic> json,
    List<String> keys, [
    String fb = '',
  ]) {
    for (final k in keys) {
      final v = json[k];
      if (v != null &&
          v is! List &&
          v is! Map &&
          v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return fb;
  }

  static num _num(Map<String, dynamic> json, List<String> keys, [num fb = 0]) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      if (v is num) return v;
      final parsed = num.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return fb;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <ProductItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map<String, dynamic>) items.add(ProductItem.fromJson(e));
      }
    }
    return ProductModel(
      id: _str(json, ['_id', 'id']),
      title: _str(json, ['title', 'name']),
      slug: _str(json, ['slug']),
      description: _str(json, ['description']),
      items: items,
      stockQuantity: _num(json, ['stockQuantity', 'stock'], 0).toInt(),
      price: _num(json, ['price'], 0),
      salePrice: json['salePrice'] is num
          ? json['salePrice'] as num
          : num.tryParse(json['salePrice']?.toString() ?? ''),
      currency: _str(json, ['currency'], 'ZAR'),
      category: _str(json, ['category']),
      status: _str(json, ['status'], 'PENDING').toUpperCase(),
      productStatus:
          _str(json, ['productStatus'], 'ACTIVE').toUpperCase(),
      isFeatured: json['isFeatured'] == true,
      imageUrl: _str(json, ['imageUrl', 'image']).isEmpty
          ? null
          : _str(json, ['imageUrl', 'image']),
      createdAt: json['createdAt']?.toString(),
      createdBy: () {
        final v = json['createdBy'];
        if (v == null) return null;
        if (v is String) return v.isEmpty ? null : v;
        if (v is Map<String, dynamic>) {
          final id = v['_id'] ?? v['id'];
          return id?.toString();
        }
        return v.toString();
      }(),
    );
  }
}
