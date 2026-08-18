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
    return 'Your cart has Ayurvedic items. Remove them or checkout before adding Books or Puja Kits.';
  }
  return 'Your cart has Books/Puja Kits. Remove them or checkout before adding Ayurvedic products.';
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
      return 'Ayurvedic cart in progress';
    case WarehouseShippingGroup.bookPujakit:
      return 'Books & Puja Kits in cart';
    default:
      return 'Different product types';
  }
}
