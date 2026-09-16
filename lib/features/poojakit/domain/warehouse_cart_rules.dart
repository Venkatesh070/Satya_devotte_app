// lib/features/poojakit/domain/warehouse_cart_rules.dart

import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';

/// Shipping warehouse groups — Ayurvedic vs Books/Puja Kits cannot share a cart.
enum WarehouseShippingGroup { ayurvedic, bookPujakit }

WarehouseShippingGroup warehouseShippingGroupForCategory(String category) {
  final c = category.trim().toLowerCase();
  if (c == 'ayurvedic') return WarehouseShippingGroup.ayurvedic;
  return WarehouseShippingGroup.bookPujakit;
}

WarehouseShippingGroup? cartWarehouseGroup(List<CartItemModel> items) {
  if (items.isEmpty) return null;
  return warehouseShippingGroupForCategory(items.first.product.category);
}

String? mixedWarehouseCartMessage({
  required WarehouseShippingGroup? cartGroup,
  required String addingCategory,
}) {
  if (cartGroup == null) return null;
  final adding = warehouseShippingGroupForCategory(addingCategory);
  if (adding == cartGroup) return null;
  if (cartGroup == WarehouseShippingGroup.ayurvedic) {
    return 'Ayurvedic items and Books / Puja Kits are shipped from separate warehouses and cannot be combined in the same cart.';
  }
  return 'Books / Puja Kits and Ayurvedic items are shipped from separate warehouses and cannot be ordered together in the same cart.';
}

/// Matches backend `MIXED_WAREHOUSE_CART_MESSAGE` for API error handling.
bool isMixedWarehouseCartError(String message) {
  final lower = message.trim().toLowerCase();
  if (lower.isEmpty) return false;
  return lower.contains("can't mix") &&
      lower.contains('ayurvedic') &&
      (lower.contains('book') || lower.contains('puja'));
}

String mixedWarehouseCartDialogTitle(WarehouseShippingGroup? cartGroup) {
  switch (cartGroup) {
    case WarehouseShippingGroup.ayurvedic:
      return 'Separate Warehouse Shipping';
    case WarehouseShippingGroup.bookPujakit:
      return 'Separate Warehouse Shipping';
    default:
      return 'Different Warehouse Item';
  }
}
