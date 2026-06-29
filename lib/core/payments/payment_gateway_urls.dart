/// Shared helpers for PayFast (and legacy Paystack) hosted checkout redirects.
class PaymentGatewayUrls {
  const PaymentGatewayUrls._();

  static String str(dynamic v) => (v ?? '').toString().trim();

  /// Resolves the redirect URL returned by payment initialize endpoints.
  static String authorizationUrlFromMap(Map<String, dynamic> root) {
    for (final key in const [
      'authorizationUrl',
      'authorization_url',
      'paymentUrl',
      'payment_url',
      'checkoutUrl',
      'checkout_url',
      'redirectUrl',
      'redirect_url',
      'payfastUrl',
      'payfast_url',
    ]) {
      final value = str(root[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  /// True when navigation has reached our return URL or a known gateway terminal.
  static bool isTerminalCallbackUrl(String url) {
    if (url.isEmpty) return false;
    final u = url.toLowerCase();

    // PayFast return / notify style query params.
    if (u.contains('payment_status=')) return true;
    if (u.contains('m_payment_id=')) return true;
    if (u.contains('pf_payment_id=')) return true;
    if (u.contains('process/return')) return true;

    // Legacy Paystack hosted checkout (keep for old in-flight sessions).
    if (u.contains('/standard/close')) return true;
    if (u.contains('/standard/success')) return true;
    if (u.contains('trxref=')) return true;

    // App / backend return handlers.
    if (u.contains('reference=')) return true;
    if (u.contains('payment/return')) return true;
    if (u.contains('donation/return')) return true;
    if (u.contains('order/return')) return true;

    return false;
  }
}
