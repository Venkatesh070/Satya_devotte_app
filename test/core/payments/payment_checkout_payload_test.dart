import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/core/payments/payment_gateway_urls.dart';

void main() {
  group('PaymentGatewayUrls.parseCheckout', () {
    test('reads redirect URL from nested data', () {
      final payload = PaymentGatewayUrls.parseCheckout({
        'data': {
          'reference': 'ref-1',
          'paymentUrl': 'https://checkout.example/pay/abc',
        },
      });

      expect(payload.redirectUrl, 'https://checkout.example/pay/abc');
      expect(payload.isValid, isTrue);
    });

    test('builds POST form when PayFast returns process URL + fields', () {
      final payload = PaymentGatewayUrls.parseCheckout({
        'data': {
          'reference': 'ref-2',
          'paymentUrl': 'https://sandbox.payfast.co.za/eng/process',
          'formData': {
            'merchant_id': '10000100',
            'amount': '100.00',
          },
        },
      });

      expect(payload.redirectUrl, isEmpty);
      expect(payload.postHtml, contains('method="POST"'));
      expect(payload.postHtml, contains('merchant_id'));
      expect(payload.postBaseUrl, contains('payfast.co.za'));
      expect(payload.isValid, isTrue);
    });
  });
}
