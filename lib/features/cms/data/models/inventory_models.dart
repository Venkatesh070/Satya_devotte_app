// Warehouse inventory items (`/api/v1/inventory/*`).
// See Flutter-Manageinventory.plan.

class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.code,
    required this.label,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String label;
  final int sortOrder;
  final bool isActive;

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? json['code'] ?? '').toString(),
      sortOrder: _toInt(json['sortOrder']) ?? 0,
      isActive: json['isActive'] != false,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.unit,
    required this.itemQuantity,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.status,
    required this.price,
    required this.currency,
    this.salePrice,
    this.totalAvailableQuantity,
    this.effectivePrice,
    this.description = '',
    this.imageUrl,
    this.supplierName = '',
    this.isLowStock = false,
  });

  final String id;
  final String name;
  final String slug;
  /// Master category code (e.g. `SACRED_POWDERS`).
  final String category;
  final String unit;
  /// Size of one stock unit (e.g. 50 with unit `grams` → 50 g per unit).
  final num itemQuantity;
  /// Count of stock units in warehouse (e.g. 50 units of 50 g).
  final int stockQuantity;
  final int lowStockThreshold;
  final String status;
  final num price;
  final num? salePrice;
  final String currency;
  /// Virtual: `stockQuantity * itemQuantity` when provided by API.
  final num? totalAvailableQuantity;
  /// Virtual: sale if set, else price when provided by API.
  final num? effectivePrice;
  final String description;
  final String? imageUrl;
  final String supplierName;
  final bool isLowStock;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isOutOfStock => stockQuantity <= 0;

  num get resolvedEffectivePrice =>
      effectivePrice ?? (salePrice != null ? salePrice! : price);

  /// Total amount in [unit]: `stockQuantity × itemQuantity` (e.g. 50 × 50 g = 2500 g).
  num get resolvedTotalAvailable =>
      totalAvailableQuantity ?? (stockQuantity * itemQuantity);

  String get itemSizeLabel => '${_formatQty(itemQuantity)} $unit';

  String get totalAvailableLabel =>
      '${_formatQty(resolvedTotalAvailable)} $unit';

  String get stockSummaryLabel =>
      '$stockQuantity × $itemSizeLabel = $totalAvailableLabel';

  String get stockLevelLabel {
    if (isOutOfStock) return 'Out of stock';
    if (isLowStock || stockQuantity <= lowStockThreshold) return 'Low stock';
    return 'In stock';
  }

  InventoryItem copyWith({
    String? status,
    String? imageUrl,
  }) {
    return InventoryItem(
      id: id,
      name: name,
      slug: slug,
      category: category,
      unit: unit,
      itemQuantity: itemQuantity,
      stockQuantity: stockQuantity,
      lowStockThreshold: lowStockThreshold,
      status: status ?? this.status,
      price: price,
      salePrice: salePrice,
      currency: currency,
      totalAvailableQuantity: totalAvailableQuantity,
      effectivePrice: effectivePrice,
      description: description,
      imageUrl: imageUrl ?? this.imageUrl,
      supplierName: supplierName,
      isLowStock: isLowStock,
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final itemQty = _toNum(json['itemQuantity']) ?? 1;
    final stock = _toInt(json['stockQuantity']) ?? 0;
    final price = _toNum(json['price']) ?? 0;
    final sale = _toNum(json['salePrice']);
    return InventoryItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      itemQuantity: itemQty,
      stockQuantity: stock,
      lowStockThreshold: _toInt(json['lowStockThreshold']) ?? 10,
      status: (json['status'] ?? 'ACTIVE').toString(),
      price: price,
      salePrice: sale,
      currency: (json['currency'] ?? 'ZAR').toString(),
      totalAvailableQuantity: _toNum(json['totalAvailableQuantity']),
      effectivePrice: _toNum(json['effectivePrice']),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'])?.toString(),
      supplierName: (json['supplierName'] ?? '').toString(),
      isLowStock: json['isLowStock'] == true,
    );
  }
}

class InventoryItemsPage {
  const InventoryItemsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<InventoryItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

num? _toNum(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

String _formatQty(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}
