// lib/features/poojakit/state/cart_controller.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';
import 'package:satya_devotte_app/features/poojakit/domain/warehouse_cart_rules.dart';
import 'package:satya_devotte_app/features/poojakit/presentation/widgets/mixed_warehouse_cart_dialog.dart';

class CartController extends GetxController {
  CartController(this._repo);
  final PoojaKitRepository _repo;

  final _cart = Rxn<CartModel>();
  final _isLoading = false.obs;
  final _error = RxnString();
  final _busyProductIds = <String>{}.obs;

  CartModel? get cart => _cart.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  bool isBusy(String productId) => _busyProductIds.contains(productId);
  int get itemCount {
    if (_cart.value == null) return 0;
    // Use server-provided itemCount if available, otherwise sum quantities
    if (_cart.value!.serverItemCount != null) {
      return _cart.value!.serverItemCount!;
    }
    return _cart.value!.items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  @override
  void onInit() {
    super.onInit();
    fetchCart();
  }

  Future<void> fetchCart() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      _cart.value = await _repo.getCart();
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> addToCart(
    String productId, {
    int quantity = 1,
    String? productCategory,
  }) async {
    if (_busyProductIds.contains(productId)) return false;

    if (productCategory != null && productCategory.trim().isNotEmpty) {
      final cartGroup = cartWarehouseGroup(_cart.value?.items ?? []);
      final conflict = mixedWarehouseCartMessage(
        cartGroup: cartGroup,
        addingCategory: productCategory,
      );
      if (conflict != null) {
        await MixedWarehouseCartDialog.show(
          message: conflict,
          cartGroup: cartGroup,
        );
        return false;
      }
    }

    _busyProductIds.add(productId);
    try {
      _cart.value = await _repo.addToCart(productId, quantity);
      return true;
    } catch (e) {
      final (title, msg) = _formatCartError(e);
      if (isMixedWarehouseCartError(msg)) {
        await MixedWarehouseCartDialog.show(
          message: msg,
          cartGroup: cartWarehouseGroup(_cart.value?.items ?? []),
        );
      } else {
        ToastUtil.showError(msg, title: title);
      }
      return false;
    } finally {
      _busyProductIds.remove(productId);
    }
  }

  (String title, String message) _formatCartError(dynamic e) {
    String msg = '';
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        msg = (data['message'] ?? data['error'] ?? '').toString();
      }
      if (msg.isEmpty) {
        msg = e.message ?? 'An error occurred';
      }
    } else {
      msg = e.toString();
    }

    msg = msg
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();

    // Pattern: Only X kit(s) of "Product Name" can be built from inventory
    final match = RegExp(
      r'Only\s+(\d+)\s*(?:kit\(s\)|item\(s\)|unit\(s\)|products?|kits?|items?)?\s*(?:of)?\s*["\u201C\u201D]?([^"\u201C\u201D]+)["\u201C\u201D]?\s*can be built from inventory',
      caseSensitive: false,
    ).firstMatch(msg);

    if (match != null) {
      final count = match.group(1);
      final rawName = match.group(2);
      final itemName = (rawName ?? 'this item').replaceAll('"', '').trim();
      final countNum = int.tryParse(count ?? '0') ?? 0;
      if (countNum <= 0) {
        return ('Out of Stock', '$itemName is currently out of stock.');
      }
      return (
        'Stock Limit',
        'Only $count kit(s) of $itemName are available in stock.',
      );
    }

    if (msg.toLowerCase().contains('can be built from inventory')) {
      final cleaned = msg
          .replaceAll('can be built from inventory', 'are available in stock')
          .replaceAll('"', '')
          .trim();
      return ('Stock Limit', cleaned);
    }

    if (msg.toLowerCase().contains('out of stock')) {
      final cleaned = msg.replaceAll('"', '').trim();
      return ('Out of Stock', cleaned);
    }

    if (msg.toLowerCase().contains('insufficient stock') ||
        msg.toLowerCase().contains('inventory stock') ||
        msg.toLowerCase().contains('stock limit') ||
        msg.toLowerCase().contains('limited stock')) {
      final cleaned = msg.replaceAll('"', '').trim();
      return ('Stock Limit', cleaned);
    }

    final cleaned = msg
        .replaceAll('"', '')
        .replaceAll('\u201C', '')
        .replaceAll('\u201D', '')
        .trim();
    return ('Cart Update', cleaned.isEmpty ? 'Failed to update cart.' : cleaned);
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    if (_busyProductIds.contains(productId)) return;
    final previousCart = _cart.value;
    _busyProductIds.add(productId);
    _updateLocalQuantity(productId, quantity);
    try {
      _cart.value = await _repo.updateCartQuantity(productId, quantity);
    } catch (e) {
      _cart.value = previousCart;
      final (title, msg) = _formatCartError(e);
      ToastUtil.showError(msg, title: title);
    } finally {
      _busyProductIds.remove(productId);
    }
  }

  Future<void> removeFromCart(String productId) async {
    if (_busyProductIds.contains(productId)) return;
    final previousCart = _cart.value;
    _busyProductIds.add(productId);
    _removeLocalItem(productId);
    try {
      _cart.value = await _repo.removeFromCart(productId);
    } catch (e) {
      _cart.value = previousCart;
      final (title, msg) = _formatCartError(e);
      ToastUtil.showError(msg, title: title);
    } finally {
      _busyProductIds.remove(productId);
    }
  }

  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
      _cart.value = const CartModel(items: [], totalAmount: 0, currency: 'ZAR');
    } catch (e) {
      final (title, msg) = _formatCartError(e);
      ToastUtil.showError(msg, title: title);
    }
  }

  void clearLocalCart() {
    _cart.value = null;
  }

  void _updateLocalQuantity(String productId, int quantity) {
    final current = _cart.value;
    if (current == null) return;

    final items = current.items.map((item) {
      if (item.product.id != productId) return item;
      return item.copyWith(
        quantity: quantity,
        lineTotal: item.product.effectivePrice * quantity,
      );
    }).toList();

    _cart.value = current.copyWith(
      items: items,
      totalAmount: _calculateTotal(items),
    );
  }

  void _removeLocalItem(String productId) {
    final current = _cart.value;
    if (current == null) return;

    final items = current.items
        .where((item) => item.product.id != productId)
        .toList();
    _cart.value = current.copyWith(
      items: items,
      totalAmount: _calculateTotal(items),
    );
  }

  num _calculateTotal(List<CartItemModel> items) {
    return items.fold<num>(0, (sum, item) => sum + item.lineTotal);
  }
}
