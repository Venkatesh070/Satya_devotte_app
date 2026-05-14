// lib/features/poojakit/data/repositories/poojakit_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/product_model.dart';
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
}
