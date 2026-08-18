/// Parsed PayFast (or legacy Paystack) checkout payload from initialize APIs.
class PaymentCheckoutPayload {
  const PaymentCheckoutPayload({
    this.redirectUrl = '',
    this.postHtml = '',
    this.postBaseUrl = '',
  });

  /// GET redirect — open directly in a WebView or browser tab.
  final String redirectUrl;

  /// Auto-submit HTML form — used when PayFast expects a POST body.
  final String postHtml;

  /// Base URL for [postHtml] so relative links resolve correctly.
  final String postBaseUrl;

  bool get isValid => redirectUrl.isNotEmpty || postHtml.isNotEmpty;
}

/// Shared helpers for PayFast (and legacy Paystack) hosted checkout redirects.
class PaymentGatewayUrls {
  const PaymentGatewayUrls._();

  static String str(dynamic v) => (v ?? '').toString().trim();

  static const _urlKeys = [
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
    'url',
  ];

  static const _nestedKeys = ['payment', 'payfast', 'payFast', 'checkout'];

  /// Resolves the redirect URL returned by payment initialize endpoints.
  static String authorizationUrlFromMap(Map<String, dynamic> root) {
    return parseCheckout(root).redirectUrl;
  }

  /// Parses initialize responses that may return a GET URL or a POST form.
  static PaymentCheckoutPayload parseCheckout(Map<String, dynamic> raw) {
    final root = _unwrapData(raw);

    // PayFast requires POST — prefer signed formFields over authorization_url GET.
    for (final candidate in _candidateMaps(root)) {
      final post = _postFormFromMap(candidate);
      if (post != null) return post;
    }

    for (final candidate in _candidateMaps(root)) {
      final html = str(
        candidate['checkoutHtml'] ??
            candidate['checkout_html'] ??
            candidate['paymentHtml'] ??
            candidate['html'],
      );
      if (html.isNotEmpty) {
        final base = str(
          candidate['actionUrl'] ??
              candidate['action_url'] ??
              candidate['processUrl'] ??
              candidate['url'],
        );
        return PaymentCheckoutPayload(postHtml: html, postBaseUrl: base);
      }
    }

    final redirect = _redirectFromMaps(_candidateMaps(root));
    if (redirect.isNotEmpty) {
      return PaymentCheckoutPayload(redirectUrl: redirect);
    }

    return const PaymentCheckoutPayload();
  }

  static PaymentCheckoutPayload? _postFormFromMap(Map<String, dynamic> candidate) {
    final action = _actionUrlFromMap(candidate);
    final form = candidate['formFields'] ??
        candidate['form_fields'] ??
        candidate['formData'] ??
        candidate['form_data'] ??
        candidate['form'] ??
        candidate['fields'];
    if (action.isNotEmpty && form is Map) {
      return PaymentCheckoutPayload(
        postHtml: buildAutoSubmitFormHtml(action, form),
        postBaseUrl: action,
      );
    }
    return null;
  }

  static Map<String, dynamic> _unwrapData(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }

  static Iterable<Map<String, dynamic>> _candidateMaps(
    Map<String, dynamic> root,
  ) sync* {
    yield root;
    for (final key in _nestedKeys) {
      final nested = root[key];
      if (nested is Map<String, dynamic>) yield nested;
    }
  }

  static String _redirectFromMaps(Iterable<Map<String, dynamic>> maps) {
    for (final candidate in maps) {
      for (final key in _urlKeys) {
        final value = str(candidate[key]);
        if (value.isNotEmpty &&
            !_looksLikeProcessEndpointOnly(value) &&
            !_isPayFastProcessUrl(value)) {
          return value;
        }
      }
    }
    return '';
  }

  static String _actionUrlFromMap(Map<String, dynamic> candidate) {
    final explicit = str(
      candidate['actionUrl'] ??
          candidate['action_url'] ??
          candidate['processUrl'] ??
          candidate['process_url'],
    );
    if (explicit.isNotEmpty) return explicit;

    for (final key in _urlKeys) {
      final value = str(candidate[key]);
      if (value.isEmpty) continue;
      if (_isPayFastProcessUrl(value)) {
        final uri = Uri.parse(value);
        return '${uri.scheme}://${uri.host}${uri.path}';
      }
      if (_looksLikeProcessEndpointOnly(value)) {
        return value;
      }
    }
    return '';
  }

  /// PayFast hosted checkout — always POST a form, never GET (even with query).
  static bool _isPayFastProcessUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (!host.contains('payfast')) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('/eng/process') || path.endsWith('/process');
  }

  /// PayFast process URLs without query params need a POST form, not a GET.
  static bool _looksLikeProcessEndpointOnly(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    final isProcess = path.endsWith('/eng/process') || path.endsWith('/process');
    return isProcess && uri.query.isEmpty;
  }

  static String buildAutoSubmitFormHtml(
    String actionUrl,
    Map<dynamic, dynamic> fields,
  ) {
    final inputs = StringBuffer();
    fields.forEach((key, value) {
      final name = str(key);
      if (name.isEmpty || value == null) return;
      inputs.writeln(
        '<input type="hidden" name="${_escapeHtml(name)}" '
        'value="${_escapeHtml(str(value))}" />',
      );
    });
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Redirecting to PayFast</title></head>
<body onload="document.forms[0].submit()">
<form method="POST" action="${_escapeHtml(actionUrl)}">
$inputs
<noscript>
<button type="submit">Continue to PayFast</button>
</noscript>
</form>
<p style="font-family:sans-serif;text-align:center;margin-top:2rem;">
Redirecting to secure payment&hellip;
</p>
</body>
</html>''';
  }

  static String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

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

    // App / backend cancel handlers.
    final isCancelParameter = u.contains('cancel_url') ||
        u.contains('cancel-url') ||
        u.contains('cancelurl') ||
        u.contains('cancel_return') ||
        u.contains('cancel_redirect');
    if (u.contains('cancel') && !isCancelParameter) return true;

    return false;
  }
}
