// lib/features/poojakit/state/cart_controller.dart

import 'package:get/get.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';

class CartController extends GetxController {
  CartController(this._repo);
  final PoojaKitRepository _repo;

  final _cart = Rxn<CartModel>();
  final _isLoading = false.obs;
  final _error = RxnString();

  CartModel? get cart => _cart.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
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
    try {
      _cart.value = await _repo.addToCart(productId, quantity);
      Get.snackbar('Success', 'Item added to cart');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    try {
      _cart.value = await _repo.updateCartQuantity(productId, quantity);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      _cart.value = await _repo.removeFromCart(productId);
      Get.snackbar('Removed', 'Item removed from cart');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
      _cart.value = const CartModel(items: [], totalAmount: 0, currency: 'ZAR');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
