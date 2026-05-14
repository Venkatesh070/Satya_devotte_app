// lib/features/poojakit/state/poojakit_checkout_controller.dart

import 'package:get/get.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/order_init_data.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';

class PoojaKitCheckoutController extends GetxController {
  PoojaKitCheckoutController(this._repo);
  final PoojaKitRepository _repo;

  final _isInitiating = false.obs;
  final _isVerifying = false.obs;
  final _lastError = RxnString();

  bool get isInitiating => _isInitiating.value;
  bool get isVerifying => _isVerifying.value;
  String? get lastError => _lastError.value;

  void reset() {
    _isInitiating.value = false;
    _isVerifying.value = false;
    _lastError.value = null;
  }

  Future<OrderInitData?> initiate({
    required String productId,
    required int quantity,
    required AddressModel shippingAddress,
    String? notes,
  }) async {
    _isInitiating.value = true;
    _lastError.value = null;
    try {
      final res = await _repo.initiateOrder(
        productId: productId,
        quantity: quantity,
        shippingAddress: shippingAddress,
        notes: notes,
      );
      return res;
    } catch (e) {
      _lastError.value = e.toString();
      return null;
    } finally {
      _isInitiating.value = false;
    }
  }

  Future<OrderInitData?> initiateCartCheckout({
    required AddressModel shippingAddress,
    String? notes,
  }) async {
    _isInitiating.value = true;
    _lastError.value = null;
    try {
      final res = await _repo.initiateCartOrder(
        shippingAddress: shippingAddress,
        notes: notes,
      );
      return res;
    } catch (e) {
      _lastError.value = e.toString();
      return null;
    } finally {
      _isInitiating.value = false;
    }
  }

  Future<VerifyResult?> verify(String orderId, String reference) async {
    _isVerifying.value = true;
    _lastError.value = null;
    try {
      final res = await _repo.verifyOrderPayment(orderId, reference);
      return res;
    } catch (e) {
      _lastError.value = e.toString();
      return null;
    } finally {
      _isVerifying.value = false;
    }
  }
}
