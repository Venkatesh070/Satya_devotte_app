// lib/features/cms/models/product_model.dart
//
// Pooja Kit product. Maps to the backend `Product` resource managed via
// `POST /api/v1/products/create-product` (multipart/form-data).
// See Flutter-admin-pujakit.plan.

/// One BOM line: warehouse stock units consumed per kit.
class ProductItem {
  const ProductItem({
    required this.inventoryItem,
    required this.quantity,
    this.inventoryName,
    this.inventoryUnit,
    this.inventoryItemQuantity,
    this.inventoryPrice,
    this.inventorySalePrice,
    this.inventoryCurrency,
  });

  /// `InventoryItem` ObjectId (24 hex).
  final String inventoryItem;
  /// Stock **units** per kit (packs), not grams.
  final num quantity;
  /// Populated on GET when `items.inventoryItem` is expanded.
  final String? inventoryName;
  final String? inventoryUnit;
  final num? inventoryItemQuantity;
  final num? inventoryPrice;
  final num? inventorySalePrice;
  final String? inventoryCurrency;

  String get displayLabel {
    if (inventoryName != null && inventoryName!.isNotEmpty) {
      final size = inventoryItemQuantity != null && inventoryUnit != null
          ? ' (${inventoryItemQuantity} $inventoryUnit)'
          : '';
      return '${inventoryName!}$size';
    }
    return inventoryItem;
  }

  Map<String, dynamic> toJson() => {
        'inventoryItem': inventoryItem,
        'quantity': quantity,
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    var invId = '';
    String? name;
    String? unit;
    num? itemQty;

    num? invPrice;
    num? invSale;
    String? invCurrency;

    final inv = json['inventoryItem'];
    if (inv is String) {
      invId = inv;
    } else if (inv is Map<String, dynamic>) {
      invId = (inv['_id'] ?? inv['id'] ?? '').toString();
      name = inv['name']?.toString();
      unit = inv['unit']?.toString();
      final iq = inv['itemQuantity'];
      if (iq is num) {
        itemQty = iq;
      } else if (iq != null) {
        itemQty = num.tryParse(iq.toString());
      }
      invPrice = _parseNum(inv['price']);
      invSale = _parseNum(inv['salePrice']);
      invCurrency = inv['currency']?.toString();
    }

    final rawQty = json['quantity'];
    num qty = 1;
    if (rawQty is num) {
      qty = rawQty;
    } else if (rawQty != null) {
      qty = num.tryParse(rawQty.toString()) ?? 1;
    }

    return ProductItem(
      inventoryItem: invId,
      quantity: qty,
      inventoryName: name ?? json['itemName']?.toString(),
      inventoryUnit: unit ?? json['unit']?.toString(),
      inventoryItemQuantity: itemQty,
      inventoryPrice: invPrice,
      inventorySalePrice: invSale,
      inventoryCurrency: invCurrency,
    );
  }

  ProductItem copyWith({
    String? inventoryItem,
    num? quantity,
    String? inventoryName,
    String? inventoryUnit,
    num? inventoryItemQuantity,
    num? inventoryPrice,
    num? inventorySalePrice,
    String? inventoryCurrency,
  }) =>
      ProductItem(
        inventoryItem: inventoryItem ?? this.inventoryItem,
        quantity: quantity ?? this.quantity,
        inventoryName: inventoryName ?? this.inventoryName,
        inventoryUnit: inventoryUnit ?? this.inventoryUnit,
        inventoryItemQuantity:
            inventoryItemQuantity ?? this.inventoryItemQuantity,
        inventoryPrice: inventoryPrice ?? this.inventoryPrice,
        inventorySalePrice: inventorySalePrice ?? this.inventorySalePrice,
        inventoryCurrency: inventoryCurrency ?? this.inventoryCurrency,
      );
}

num? _parseNum(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
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
  /// Max kits buildable from inventory (computed server-side).
  final int stockQuantity;
  final num price;
  final num? salePrice;
  final String currency;
  final String category;
  final String status;
  final String productStatus;
  final bool isFeatured;
  final String? imageUrl;
  final String? createdAt;
  final String? createdBy;

  bool get isActive => productStatus.toUpperCase() == 'ACTIVE';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isDraft => status.toUpperCase() == 'DRAFT';
  bool get isQueued => status.toUpperCase() == 'QUEUED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  bool get inStock => stockQuantity > 0;
  num get effectivePrice => salePrice ?? price;

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
      productStatus: _str(json, ['productStatus'], 'ACTIVE').toUpperCase(),
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
