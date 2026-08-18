// lib/features/poojakit/data/repositories/poojakit_repository.dart

import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_models.dart';
import 'package:satya_devotte_app/features/cms/data/models/admin_order_request_models.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/cart_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/order_init_data.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/address_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/pickup_location_model.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/shipping_quote_model.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';

class PoojaKitRepository {
  PoojaKitRepository(this._apiClient);
  final ApiClient _apiClient;

  /// `POST /shipping/quote` — live TCG door-to-door rates for an address.
  Future<ShippingQuoteModel> quoteShipping({
    required AddressModel shippingAddress,
    double? declaredValue,
    List<Map<String, dynamic>>? items,
    List<String>? productIds,
  }) async {
    try {
      final res = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.shippingQuote,
        data: {
          'shippingAddress': shippingAddress.toJson(),
          if (declaredValue != null) 'declaredValue': declaredValue,
          if (items != null && items.isNotEmpty) 'items': items,
          if (productIds != null && productIds.isNotEmpty)
            'productIds': productIds,
        },
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from shipping quote.');
      }
      final payload = data['data'];
      final quoteJson = payload is Map && payload['quote'] is Map
          ? payload['quote'] as Map<String, dynamic>
          : (payload is Map<String, dynamic> ? payload : data);
      return ShippingQuoteModel.fromJson(
        Map<String, dynamic>.from(quoteJson as Map),
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Could not fetch shipping rates.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// `GET /shipping/pickup-location` — default warehouse (legacy fallback).
  Future<PickupLocationModel> getPickupLocation() async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.shippingPickupLocation,
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from pickup location.');
      }
      final payload = data['data'];
      final locJson = payload is Map && payload['location'] is Map
          ? payload['location'] as Map<String, dynamic>
          : (payload is Map<String, dynamic> ? payload : data);
      return PickupLocationModel.fromJson(
        Map<String, dynamic>.from(locJson as Map),
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Could not fetch pickup location.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// `POST /warehouses/for-cart` — category-based pickup warehouse + address.
  Future<PickupLocationModel> getWarehouseForCart({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.warehousesForCart,
        data: {'items': items},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from warehouse resolver.');
      }
      final payload = data['data'];
      final locJson = payload is Map && payload['location'] is Map
          ? payload['location'] as Map<String, dynamic>
          : null;
      if (locJson == null) {
        throw Exception('Pickup warehouse location missing from response.');
      }
      final warehouseName = payload is Map
          ? (payload['warehouse'] is Map
              ? (payload['warehouse'] as Map)['name']?.toString()
              : null)
          : null;
      final model = PickupLocationModel.fromJson(
        Map<String, dynamic>.from(locJson),
      );
      if (warehouseName != null && warehouseName.trim().isNotEmpty) {
        return PickupLocationModel(
          company: warehouseName.trim(),
          streetAddress: model.streetAddress,
          localArea: model.localArea,
          city: model.city,
          zone: model.zone,
          postalCode: model.postalCode,
          country: model.country,
          enteredAddress: model.enteredAddress,
          contactName: model.contactName,
          contactPhone: model.contactPhone,
          contactEmail: model.contactEmail,
          hours: model.hours,
          instructions: model.instructions,
          lat: model.lat,
          lng: model.lng,
        );
      }
      return model;
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not resolve pickup warehouse for this cart.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// Initiate a PayFast payment for a product order.
  /// This is now a 2-step process as per the API:
  /// 1. Create order
  /// 2. Initialize PayFast payment
  Future<OrderInitData> initiateOrder({
    required String productId,
    required int quantity,
    required String fulfillmentMethod,
    AddressModel? shippingAddress,
    String? shippingServiceLevelCode,
    String? contactFullName,
    String? contactPhone,
    String? notes,
  }) async {
    try {
      // Step 1: Create Order
      final orderBody = _buildOrderBody(
        items: [
          {'productId': productId, 'quantity': quantity},
        ],
        fulfillmentMethod: fulfillmentMethod,
        shippingAddress: shippingAddress,
        shippingServiceLevelCode: shippingServiceLevelCode,
        contactFullName: contactFullName,
        contactPhone: contactPhone,
        notes: notes,
      );

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

  /// Verify a PayFast reference for an order.
  Future<VerifyResult> verifyOrderPayment(
    String orderId,
    String reference,
  ) async {
    try {
      final res = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.verifyOrderPayment(orderId),
        data: {'reference': reference},
        options: Options(extra: {kSkipApiLoaderKey: true}),
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
      final pagination = payload['pagination'] is Map<String, dynamic>
          ? payload['pagination'] as Map<String, dynamic>
          : const <String, dynamic>{};

      return AdminOrdersPage(
        items: items,
        page:
            int.tryParse(
              (pagination['page'] ?? payload['page'] ?? '1').toString(),
            ) ??
            1,
        limit:
            int.tryParse(
              (pagination['limit'] ?? payload['limit'] ?? '10').toString(),
            ) ??
            10,
        total:
            int.tryParse(
              pagination['total']?.toString() ??
                  payload['total']?.toString() ??
                  payload['totalItems']?.toString() ??
                  items.length.toString(),
            ) ??
            items.length,
        totalPages:
            int.tryParse(
              pagination['totalPages']?.toString() ??
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
    String? collectionCode,
  }) async {
    try {
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.confirmDelivery(orderId),
        data: {
          'satisfied': satisfied,
          'feedback': feedback,
          if (collectionCode != null && collectionCode.trim().isNotEmpty)
            'collectionCode': collectionCode.trim(),
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not confirm delivery.';
      throw Exception(msg);
    }
  }

  /// GET `/replacements/my-requests` — current user's replacement requests.
  Future<OrderRequestsPage> getMyReplacementRequests({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myReplacementRequests,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      if (payload is! Map) {
        throw Exception('Invalid data format in response.');
      }
      final payloadMap = Map<String, dynamic>.from(payload);
      final rawItems = payloadMap['requests'] ?? payloadMap['items'];
      final items = <OrderRequest>[];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is! Map) continue;
          items.add(
            OrderRequest.fromReplacementJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      final pagination = payloadMap['pagination'] is Map
          ? Map<String, dynamic>.from(payloadMap['pagination'] as Map)
          : const <String, dynamic>{};
      return OrderRequestsPage(
        items: items,
        page: int.tryParse((pagination['page'] ?? page).toString()) ?? page,
        limit: int.tryParse((pagination['limit'] ?? limit).toString()) ?? limit,
        total: int.tryParse(
              (pagination['total'] ?? items.length).toString(),
            ) ??
            items.length,
        totalPages: int.tryParse(
              (pagination['totalPages'] ?? '1').toString(),
            ) ??
            1,
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not fetch replacement requests.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// GET one replacement request owned by the current user.
  Future<OrderRequest> getMyReplacementRequest(String requestId) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myReplacementRequest(requestId),
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      final raw = payload is Map && payload['request'] is Map
          ? payload['request'] as Map<String, dynamic>
          : payload is Map<String, dynamic>
              ? payload
              : null;
      if (raw == null) {
        throw Exception('Replacement request not found.');
      }
      return OrderRequest.fromReplacementJson(raw);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not load replacement request.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// POST multipart replacement request for a delivered order.
  Future<void> requestReplacement({
    required String orderId,
    required String reason,
    required List<PickedFile> images,
    List<Map<String, dynamic>> affectedItems = const [],
  }) async {
    if (images.isEmpty) {
      throw Exception('Please attach at least one photo of the damage.');
    }
    try {
      final formData = FormData();
      formData.fields
        ..add(MapEntry('orderId', orderId))
        ..add(MapEntry('reason', reason));
      if (affectedItems.isNotEmpty) {
        formData.fields.add(
          MapEntry('affectedItems', jsonEncode(affectedItems)),
        );
      }
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

  /// POST `/orders/:id/requests` — return / refund request after delivery.
  Future<void> requestReturn({
    required String orderId,
    required String reason,
    List<Map<String, dynamic>> affectedItems = const [],
  }) async {
    try {
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.orderRequest(orderId),
        data: {
          'type': 'REFUND',
          'reason': reason,
          if (affectedItems.isNotEmpty) 'affectedItems': affectedItems,
        },
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not submit the return request.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// GET `/orders/requests/my` — devotee's cancellation / refund requests.
  Future<OrderRequestsPage> getMyOrderRequests({
    int page = 1,
    int limit = 50,
    String? type,
    String? status,
  }) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myOrderRequests,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null && type.isNotEmpty) 'type': type,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }

      final payload = data['data'];
      if (payload is! Map<String, dynamic>) {
        throw Exception('Invalid data format in response.');
      }

      final rawItems = payload['requests'] ?? payload['items'];
      final items = <OrderRequest>[];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is Map<String, dynamic>) {
            items.add(OrderRequest.fromJson(item));
          }
        }
      }

      final pagination = payload['pagination'] is Map<String, dynamic>
          ? payload['pagination'] as Map<String, dynamic>
          : const <String, dynamic>{};

      return OrderRequestsPage(
        items: items,
        page:
            int.tryParse(
              (pagination['page'] ?? payload['page'] ?? '1').toString(),
            ) ??
            1,
        limit:
            int.tryParse(
              (pagination['limit'] ?? payload['limit'] ?? '$limit').toString(),
            ) ??
            limit,
        total:
            int.tryParse(
              pagination['total']?.toString() ??
                  payload['total']?.toString() ??
                  items.length.toString(),
            ) ??
            items.length,
        totalPages:
            int.tryParse(
              pagination['totalPages']?.toString() ??
                  payload['totalPages']?.toString() ??
                  '1',
            ) ??
            1,
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not fetch your return requests.';
      throw Exception(msg is String ? msg : msg.toString());
    }
  }

  /// GET `/orders/requests/:id` — single refund / cancellation request.
  Future<OrderRequest> getMyOrderRequest(String requestId) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myOrderRequest(requestId),
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      final requestData = payload is Map && payload['request'] is Map
          ? payload['request']
          : payload;
      return OrderRequest.fromJson(requestData as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ??
          'Could not fetch the return request.';
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
      debugPrint('Cart API Response: $data');
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      debugPrint('Cart Payload: $payload');
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      debugPrint('Cart Data to Parse: $cartData');
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
      debugPrint('Add to Cart API Response: $data');
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      debugPrint('Add to Cart Payload: $payload');
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      debugPrint('Add to Cart Data to Parse: $cartData');
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
      debugPrint('Remove from Cart API Response: $data');
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      debugPrint('Remove from Cart Payload: $payload');
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      debugPrint('Remove from Cart Data to Parse: $cartData');
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
      debugPrint('Update Cart API Response: $data');
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from server.');
      }
      final payload = data['data'];
      debugPrint('Update Cart Payload: $payload');
      final cartData = payload is Map && payload['cart'] is Map
          ? payload['cart']
          : payload;
      debugPrint('Update Cart Data to Parse: $cartData');
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
    required String fulfillmentMethod,
    AddressModel? shippingAddress,
    String? shippingServiceLevelCode,
    String? contactFullName,
    String? contactPhone,
    String? notes,
  }) async {
    try {
      // Step 1: Create Order from Cart
      final orderBody = _buildOrderBody(
        items: [], // Backend knows it's from cart if items is empty or omitted
        fulfillmentMethod: fulfillmentMethod,
        shippingAddress: shippingAddress,
        shippingServiceLevelCode: shippingServiceLevelCode,
        contactFullName: contactFullName,
        contactPhone: contactPhone,
        notes: notes,
      );

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

  Map<String, dynamic> _buildOrderBody({
    required List<Map<String, dynamic>> items,
    required String fulfillmentMethod,
    AddressModel? shippingAddress,
    String? shippingServiceLevelCode,
    String? contactFullName,
    String? contactPhone,
    String? notes,
  }) {
    final method = fulfillmentMethod.toUpperCase().trim();
    final body = <String, dynamic>{
      'items': items,
      'fulfillmentMethod': method,
      'paymentMethod': 'PAYFAST',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    if (method == 'PICKUP') {
      final name = (contactFullName ?? shippingAddress?.fullName ?? '').trim();
      final phone = (contactPhone ?? shippingAddress?.phone ?? '').trim();
      body['contact'] = {
        'fullName': name,
        'phone': phone,
      };
    } else {
      if (shippingAddress == null) {
        throw Exception('shippingAddress is required for delivery orders.');
      }
      body['shippingAddress'] = shippingAddress.toJson();
      if (shippingServiceLevelCode != null &&
          shippingServiceLevelCode.trim().isNotEmpty) {
        body['shippingServiceLevelCode'] =
            shippingServiceLevelCode.trim().toUpperCase();
      }
    }
    return body;
  }
}
