// lib/features/poojakit/data/repositories/poojakit_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/order_init_data.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';

class PoojaKitRepository {
  PoojaKitRepository(this._apiClient);
  final ApiClient _apiClient;

  /// Initiate a Paystack payment for a product order.
  /// This is now a 2-step process as per the API:
  /// 1. Create order
  /// 2. Initialize Paystack payment
  Future<OrderInitData> initiateOrder({
    required String productId,
    required int quantity,
    required AddressModel shippingAddress,
    String? notes,
  }) async {
    try {
      // Step 1: Create Order
      final orderBody = <String, dynamic>{
        'items': [
          {'productId': productId, 'quantity': quantity},
        ],
        'shippingAddress': shippingAddress.toJson(),
        'paymentMethod': 'PAYSTACK',
        if (notes != null) 'notes': notes,
      };

      final orderRes = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.createOrder,
        data: orderBody,
      );

      final orderData = orderRes.data;
      // Debug print to see the actual structure
      debugPrint('Order Creation Response: $orderData');

      final dynamic dataObj = orderData['data'];
      final dynamic orderObj = dataObj is Map ? dataObj['order'] : null;

      final String orderId =
          (orderObj?['_id'] ??
                  orderObj?['id'] ??
                  dataObj?['_id'] ??
                  dataObj?['id'] ??
                  orderData['_id'] ??
                  orderData['id'] ??
                  '')
              .toString();

      if (orderId.isEmpty) {
        throw Exception(
          'Failed to create order. Server returned: ${orderData['message'] ?? "No ID"}',
        );
      }

      // Step 2: Initialize Payment
      final payRes = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.initializeOrderPayment(orderId),
      );

      final payData = payRes.data;
      if (payData is! Map<String, dynamic>) {
        throw Exception('Unexpected response during payment initialization.');
      }

      // Inject orderId into the result so the WebView knows which order to verify later
      if (payData['data'] is Map<String, dynamic>) {
        payData['data']['orderId'] = orderId;
      }

      return OrderInitData.fromJson(payData);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not complete the order process.';
      throw Exception(msg);
    }
  }

  /// Verify a Paystack reference for an order.
  Future<VerifyResult> verifyOrderPayment(
    String orderId,
    String reference,
  ) async {
    try {
      final res = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.verifyOrderPayment(orderId),
        data: {'reference': reference},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      return VerifyResult.fromJson(data, fallbackReference: reference);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Could not verify the payment.';
      throw Exception(msg);
    }
  }

  /// Get the current user's orders (paginated).
  Future<AdminOrdersPage> getMyOrders({int page = 1, int limit = 10}) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myOrders,
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }

      final payload = data['data'];
      if (payload is! Map<String, dynamic>) {
        throw Exception('Invalid data format in response.');
      }

      debugPrint('My Orders Payload: $payload');

      final List<AdminOrder> items = [];
      final rawItems = payload['items'] ?? payload['orders'];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is Map<String, dynamic>) {
            items.add(AdminOrder.fromJson(item));
          }
        }
      }

      return AdminOrdersPage(
        items: items,
        page: int.tryParse(payload['page']?.toString() ?? '1') ?? 1,
        limit: int.tryParse(payload['limit']?.toString() ?? '10') ?? 10,
        total:
            int.tryParse(
              payload['total']?.toString() ??
                  payload['totalItems']?.toString() ??
                  items.length.toString(),
            ) ??
            items.length,
        totalPages:
            int.tryParse(
              payload['totalPages']?.toString() ??
                  payload['pages']?.toString() ??
                  '1',
            ) ??
            1,
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Could not fetch your orders.';
      throw Exception(msg);
    }
  }

  /// Cancel an order (Placed / Processing). `POST /orders/:id/cancel`.
  /// Body: `{ "reason": string }`.
  Future<void> cancelOrder(String orderId, {required String reason}) async {
    try {
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.cancelOrder(orderId),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not cancel the order.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// Confirm delivery of an order.
  Future<void> confirmDelivery(
    String orderId, {
    required bool satisfied,
    String? feedback,
  }) async {
    try {
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.confirmDelivery(orderId),
        data: {'satisfied': satisfied, 'feedback': feedback},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not confirm delivery.';
      throw Exception(msg);
    }
  }

  /// POST multipart replacement request for a delivered order.
  Future<void> requestReplacement({
    required String orderId,
    required String reason,
    required List<PickedFile> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('Please attach at least one photo of the damage.');
    }
    try {
      final formData = FormData();
      formData.fields
        ..add(MapEntry('orderId', orderId))
        ..add(MapEntry('reason', reason));
      for (final img in images) {
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              img.bytes,
              filename: img.filename,
              contentType: MediaType.parse(img.mimeType),
            ),
          ),
        );
      }
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.requestReplacement,
        data: formData,
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not submit the replacement request.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// Get a single order detail.
  Future<AdminOrder> getOrderDetail(String orderId) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.order(orderId),
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      final orderData = payload is Map && payload['order'] is Map
          ? payload['order']
          : payload;
      return AdminOrder.fromJson(orderData as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Could not fetch order detail.';
      throw Exception(msg);
    }
  }

  // ── Cart Operations ─────────────────────────────────────────

  /// GET — get the current user's cart.
  Future<CartModel> getCart() async {
    try {
      final res = await _apiClient.dio.get<dynamic>(ApiEndpoints.cart);
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      return CartModel.fromJson(cartData as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not fetch cart.';
      throw Exception(msg);
    }
  }

  /// POST — add a product to the cart.
  Future<CartModel> addToCart(String productId, int quantity) async {
    try {
      final res = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.cartAdd,
        data: {'productId': productId, 'quantity': quantity},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      return CartModel.fromJson(cartData as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not add to cart.';
      throw Exception(msg);
    }
  }

  /// POST — remove a product from the cart.
  Future<CartModel> removeFromCart(String productId) async {
    try {
      // Trying the DELETE endpoint first as it's more standard for specific item removal
      final res = await _apiClient.dio.delete<dynamic>(
        ApiEndpoints.cartRemoveItem(productId),
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      return CartModel.fromJson(cartData as Map<String, dynamic>);
    } on DioException catch (e) {
      // Fallback to POST remove if DELETE fails (some environments might only support POST)
      try {
        final res = await _apiClient.dio.post<dynamic>(
          ApiEndpoints.cartRemove,
          data: {'productId': productId},
        );
        final data = res.data;
        final payload = data['data'];
        final cartData = payload is Map && payload['cart'] is Map
            ? payload['cart']
            : payload;
        return CartModel.fromJson(cartData as Map<String, dynamic>);
      } catch (_) {
        final msg =
            e.response?.data?['message'] ?? 'Could not remove from cart.';
        throw Exception(msg);
      }
    }
  }

  /// PUT — update quantity for a product in the cart.
  Future<CartModel> updateCartQuantity(String productId, int quantity) async {
    try {
      final res = await _apiClient.dio.put<dynamic>(
        ApiEndpoints.cartUpdate,
        data: {'productId': productId, 'quantity': quantity},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      return CartModel.fromJson(cartData as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not update cart.';
      throw Exception(msg);
    }
  }

  /// DELETE — clear the entire cart.
  Future<void> clearCart() async {
    try {
      await _apiClient.dio.delete<dynamic>(ApiEndpoints.cartClear);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not clear cart.';
      throw Exception(msg);
    }
  }

  /// Initiate checkout from the entire cart.
  Future<OrderInitData> initiateCartOrder({
    required AddressModel shippingAddress,
    String? notes,
  }) async {
    try {
      // Step 1: Create Order from Cart
      final orderBody = <String, dynamic>{
        'items':
            [], // Backend knows it's from cart if items is empty or omitted
        'shippingAddress': shippingAddress.toJson(),
        'paymentMethod': 'PAYSTACK',
        if (notes != null) 'notes': notes,
      };

      final orderRes = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.createOrder,
        data: orderBody,
      );

      final orderData = orderRes.data;
      final dynamic dataObj = orderData['data'];
      final dynamic orderObj = dataObj is Map ? dataObj['order'] : null;

      final String orderId =
          (orderObj?['_id'] ??
                  orderObj?['id'] ??
                  dataObj?['_id'] ??
                  dataObj?['id'] ??
                  '')
              .toString();

      if (orderId.isEmpty) {
        throw Exception('Failed to create order from cart.');
      }

      // Step 2: Initialize Payment
      final payRes = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.initializeOrderPayment(orderId),
      );

      final payData = payRes.data;
      if (payData['data'] is Map<String, dynamic>) {
        payData['data']['orderId'] = orderId;
      }

      return OrderInitData.fromJson(payData);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not complete the checkout process.';
      throw Exception(msg);
    }
  }
}
