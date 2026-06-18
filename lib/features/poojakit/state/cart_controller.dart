// lib/features/poojakit/state/cart_controller.dart

import 'package:get/get.dart';
import 'package:satya_devotte_app/core/utils/toast_util.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';

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

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    if (_busyProductIds.contains(productId)) return;
    _busyProductIds.add(productId);
    try {
      _cart.value = await _repo.addToCart(productId, quantity);
    } catch (e) {
      ToastUtil.showError(e.toString());
    } finally {
      _busyProductIds.remove(productId);
    }
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
      ToastUtil.showError(e.toString());
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
      ToastUtil.showError(e.toString());
    } finally {
      _busyProductIds.remove(productId);
    }
  }

  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
      _cart.value = const CartModel(items: [], totalAmount: 0, currency: 'ZAR');
    } catch (e) {
      ToastUtil.showError(e.toString());
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
