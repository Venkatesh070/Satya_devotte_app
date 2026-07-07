// lib/features/poojakit/data/models/order_init_data.dart

import 'package:satya_devotte_app/core/payments/payment_gateway_urls.dart';

class OrderInitData {
  const OrderInitData({
    required this.reference,
    required this.authorizationUrl,
    required this.checkout,
    required this.amount,
    required this.currency,
    required this.orderId,
    this.accessCode,
    this.publicKey,
  });

  final String reference;
  final String authorizationUrl;
  final PaymentCheckoutPayload checkout;
  final num amount;
  final String currency;
  final String orderId;
  final String? accessCode;
  final String? publicKey;

  static String _str(dynamic v) => (v ?? '').toString().trim();

  factory OrderInitData.fromJson(Map<String, dynamic> raw) {
    final root = (raw['data'] is Map<String, dynamic>)
        ? raw['data'] as Map<String, dynamic>
        : raw;

    final checkout = PaymentGatewayUrls.parseCheckout(raw);

    return OrderInitData(
      reference: _str(root['reference']),
      authorizationUrl: checkout.redirectUrl,
      checkout: checkout,
      amount: (root['amount'] is num)
          ? root['amount'] as num
          : num.tryParse(_str(root['amount'])) ?? 0,
      currency: _str(root['currency']).isEmpty ? 'ZAR' : _str(root['currency']),
      orderId: _str(root['orderId'] ?? root['id'] ?? raw['orderId']),
      accessCode: () {
        final s = _str(root['accessCode']);
        return s.isEmpty ? null : s;
      }(),
      publicKey: () {
        final s = _str(root['publicKey']);
        return s.isEmpty ? null : s;
      }(),
    );
  }
}
