// lib/features/poojakit/state/poojakit_checkout_controller.dart

import 'package:get/get.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/order_init_data.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/pickup_location_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/shipping_quote_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/repositories/poojakit_repository.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';

/// Checkout fulfilment: door-to-door delivery vs warehouse pickup.
enum FulfillmentMethod { delivery, pickup }

extension FulfillmentMethodX on FulfillmentMethod {
  String get wire =>
      this == FulfillmentMethod.delivery ? 'DELIVERY' : 'PICKUP';

  String get label =>
      this == FulfillmentMethod.delivery ? 'Delivery' : 'Pickup';

  static FulfillmentMethod parse(dynamic v) {
    final s = (v ?? '').toString().toUpperCase().trim();
    if (s == 'PICKUP') return FulfillmentMethod.pickup;
    return FulfillmentMethod.delivery;
  }
}

class PoojaKitCheckoutController extends GetxController {
  PoojaKitCheckoutController(this._repo);
  final PoojaKitRepository _repo;

  final _isInitiating = false.obs;
  final _isVerifying = false.obs;
  final _isQuoting = false.obs;
  final _isLoadingPickup = false.obs;
  final _lastError = RxnString();
  final _shippingAddress = Rxn<AddressModel>();
  final _fulfillmentMethod = FulfillmentMethod.delivery.obs;
  final _quoteRates = <ShippingRateModel>[].obs;
  final _selectedRate = Rxn<ShippingRateModel>();
  final _quoteCurrency = 'ZAR'.obs;
  final _pickupLocation = Rxn<PickupLocationModel>();

  bool get isInitiating => _isInitiating.value;
  bool get isVerifying => _isVerifying.value;
  bool get isQuoting => _isQuoting.value;
  bool get isLoadingPickup => _isLoadingPickup.value;
  String? get lastError => _lastError.value;
  AddressModel? get shippingAddress => _shippingAddress.value;
  bool get hasShippingAddress => _shippingAddress.value != null;
  FulfillmentMethod get fulfillmentMethod => _fulfillmentMethod.value;
  bool get isPickup => _fulfillmentMethod.value == FulfillmentMethod.pickup;
  bool get isDelivery => _fulfillmentMethod.value == FulfillmentMethod.delivery;
  List<ShippingRateModel> get quoteRates => _quoteRates;
  ShippingRateModel? get selectedRate => _selectedRate.value;
  String get quoteCurrency => _quoteCurrency.value;
  PickupLocationModel? get pickupLocation => _pickupLocation.value;

  /// Preview delivery charge for the bill summary (R0 for pickup).
  double get previewDeliveryCharge {
    if (isPickup) return 0;
    return _selectedRate.value?.rate ?? 0;
  }

  bool get canProceedCheckout {
    if (isPickup) {
      return _pickupLocation.value != null;
    }
    return _shippingAddress.value != null && _selectedRate.value != null;
  }

  void setFulfillmentMethod(
    FulfillmentMethod method, {
    List<Map<String, dynamic>>? pickupItems,
  }) {
    if (_fulfillmentMethod.value == method) return;
    _fulfillmentMethod.value = method;
    _selectedRate.value = null;
    _quoteRates.clear();
    _lastError.value = null;
    if (method == FulfillmentMethod.pickup && _pickupLocation.value == null) {
      final items = pickupItems ?? _cartItemsForPickup();
      fetchPickupLocation(cartItems: items);
    }
  }

  /// Cart line items for warehouse routing when checkout is opened from the cart.
  List<Map<String, dynamic>>? _cartItemsForPickup() {
    if (!Get.isRegistered<CartController>()) return null;
    final items = Get.find<CartController>().cart?.items;
    if (items == null || items.isEmpty) return null;
    final mapped = items
        .where((i) => i.product.id.trim().isNotEmpty)
        .map(
          (i) => <String, dynamic>{
            'productId': i.product.id,
            'quantity': i.quantity,
          },
        )
        .toList();
    return mapped.isEmpty ? null : mapped;
  }

  /// Reload pickup warehouse for explicit cart/product lines.
  Future<bool> fetchPickupForItems(List<Map<String, dynamic>> items) =>
      fetchPickupLocation(cartItems: items);

  void selectRate(ShippingRateModel rate) {
    _selectedRate.value = rate;
  }

  void saveShippingAddress(AddressModel address) {
    _shippingAddress.value = address;
  }

  void clearShippingAddress() {
    _shippingAddress.value = null;
    _selectedRate.value = null;
    _quoteRates.clear();
  }

  void reset() {
    _isInitiating.value = false;
    _isVerifying.value = false;
    _isQuoting.value = false;
    _isLoadingPickup.value = false;
    _lastError.value = null;
  }

  Future<bool> fetchShippingQuote(
    AddressModel address, {
    double? declaredValue,
    List<Map<String, dynamic>>? items,
  }) async {
    _isQuoting.value = true;
    _lastError.value = null;
    try {
      final quoteItems = items ?? _cartItemsForPickup();
      final quote = await _repo.quoteShipping(
        shippingAddress: address,
        declaredValue: declaredValue,
        items: quoteItems,
      );
      _quoteRates.assignAll(quote.rates);
      _quoteCurrency.value = quote.currency;
      if (_selectedRate.value != null) {
        final code = _selectedRate.value!.serviceLevelCode;
        final match = quote.rates.cast<ShippingRateModel?>().firstWhere(
              (r) => r?.serviceLevelCode == code,
              orElse: () => null,
            );
        _selectedRate.value = match ??
            (quote.rates.isNotEmpty ? quote.rates.first : null);
      } else if (quote.rates.isNotEmpty) {
        _selectedRate.value = quote.rates.first;
      } else {
        _selectedRate.value = null;
      }
      return true;
    } catch (e) {
      _quoteRates.clear();
      _selectedRate.value = null;
      _lastError.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isQuoting.value = false;
    }
  }

  Future<bool> fetchPickupLocation({List<Map<String, dynamic>>? cartItems}) async {
    _isLoadingPickup.value = true;
    _lastError.value = null;
    try {
      final items = cartItems ?? _cartItemsForPickup();
      final PickupLocationModel loc;
      if (items != null && items.isNotEmpty) {
        loc = await _repo.getWarehouseForCart(items: items);
      } else {
        loc = await _repo.getPickupLocation();
      }
      _pickupLocation.value = loc;
      return true;
    } catch (e) {
      _lastError.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoadingPickup.value = false;
    }
  }

  Future<OrderInitData?> initiate({
    required String productId,
    required int quantity,
    AddressModel? shippingAddress,
    String? notes,
    String? contactFullName,
    String? contactPhone,
  }) async {
    _isInitiating.value = true;
    _lastError.value = null;
    try {
      final method = _fulfillmentMethod.value;
      if (method == FulfillmentMethod.delivery) {
        final address = shippingAddress ?? _shippingAddress.value;
        final rate = _selectedRate.value;
        if (address == null || rate == null) {
          _lastError.value =
              'Please set a delivery address and choose a courier service.';
          return null;
        }
        return await _repo.initiateOrder(
          productId: productId,
          quantity: quantity,
          fulfillmentMethod: method.wire,
          shippingAddress: address,
          shippingServiceLevelCode: rate.serviceLevelCode,
          notes: notes,
        );
      }

      final name = (contactFullName ?? shippingAddress?.fullName ?? '').trim();
      final phone = (contactPhone ?? shippingAddress?.phone ?? '').trim();
      if (name.isEmpty || phone.isEmpty) {
        _lastError.value = 'Please enter your name and phone for pickup.';
        return null;
      }
      return await _repo.initiateOrder(
        productId: productId,
        quantity: quantity,
        fulfillmentMethod: method.wire,
        contactFullName: name,
        contactPhone: phone,
        shippingAddress: shippingAddress,
        notes: notes,
      );
    } catch (e) {
      _lastError.value = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isInitiating.value = false;
    }
  }

  Future<OrderInitData?> initiateCartCheckout({
    AddressModel? shippingAddress,
    String? notes,
    String? contactFullName,
    String? contactPhone,
  }) async {
    _isInitiating.value = true;
    _lastError.value = null;
    try {
      final method = _fulfillmentMethod.value;
      if (method == FulfillmentMethod.delivery) {
        final address = shippingAddress ?? _shippingAddress.value;
        final rate = _selectedRate.value;
        if (address == null || rate == null) {
          _lastError.value =
              'Please set a delivery address and choose a courier service.';
          return null;
        }
        return await _repo.initiateCartOrder(
          fulfillmentMethod: method.wire,
          shippingAddress: address,
          shippingServiceLevelCode: rate.serviceLevelCode,
          notes: notes,
        );
      }

      final name = (contactFullName ??
              shippingAddress?.fullName ??
              _shippingAddress.value?.fullName ??
              '')
          .trim();
      final phone = (contactPhone ??
              shippingAddress?.phone ??
              _shippingAddress.value?.phone ??
              '')
          .trim();
      if (name.isEmpty || phone.isEmpty) {
        _lastError.value = 'Please enter your name and phone for pickup.';
        return null;
      }
      return await _repo.initiateCartOrder(
        fulfillmentMethod: method.wire,
        contactFullName: name,
        contactPhone: phone,
        shippingAddress: shippingAddress ?? _shippingAddress.value,
        notes: notes,
      );
    } catch (e) {
      _lastError.value = e.toString().replaceFirst('Exception: ', '');
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
      _lastError.value = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isVerifying.value = false;
    }
  }
}
