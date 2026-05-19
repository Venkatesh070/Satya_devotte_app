// lib/features/poojakit/data/models/cart_model.dart

import 'package:satya_devotte_app/features/cms/models/product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.product,
    required this.quantity,
    required this.lineTotal,
  });

  final ProductModel product;
  final int quantity;
  final num lineTotal;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = Map<String, dynamic>.from(
      json['product'] as Map<String, dynamic>,
    );

    // Merge pricing data from the cart item into the product model if missing
    if (productJson['price'] == null && json['price'] != null) {
      productJson['price'] = json['price'];
    }
    if (productJson['salePrice'] == null && json['salePrice'] != null) {
      productJson['salePrice'] = json['salePrice'];
    }

    return CartItemModel(
      product: ProductModel.fromJson(productJson),
      quantity: (json['quantity'] ?? 1) as int,
      lineTotal: (json['lineTotal'] ?? 0) as num,
    );
  }
}

class CartModel {
  const CartModel({
    required this.items,
    required this.totalAmount,
    required this.currency,
    this.serverItemCount,
  });

  final List<CartItemModel> items;
  final num totalAmount;
  final String currency;
  final int? serverItemCount;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return CartModel(
      items: rawItems
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0) as num,
      currency: (json['currency'] ?? 'ZAR').toString(),
      serverItemCount: json['itemCount'] as int?,
    );
  }

  bool get isEmpty => items.isEmpty;
}
