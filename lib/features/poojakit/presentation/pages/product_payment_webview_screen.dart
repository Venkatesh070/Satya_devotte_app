// lib/features/poojakit/presentation/pages/product_payment_webview_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:satya_devotte_app/core/payments/payment_gateway_urls.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/features/poojakit/data/models/order_init_data.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donation_failed_screen.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';
import 'package:satya_devotte_app/features/poojakit/state/poojakit_checkout_controller.dart';

class ProductPaymentWebViewScreen extends StatefulWidget {
  const ProductPaymentWebViewScreen({super.key});

  @override
  State<ProductPaymentWebViewScreen> createState() =>
      _ProductPaymentWebViewScreenState();
}

class _ProductPaymentWebViewScreenState
    extends State<ProductPaymentWebViewScreen>
    with WidgetsBindingObserver {
  late final PoojaKitCheckoutController _ctrl;
  late final CartController _cartCtrl;
  OrderInitData? _init;

  WebViewController? _webview;
  bool _completed = false;
  bool _pageLoading = true;

  Timer? _pollTimer;
  static const _pollEvery = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is! OrderInitData || !arg.checkout.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Get.back();
      });
      return;
    }
    _init = arg;
    _ctrl = Get.find<PoojaKitCheckoutController>();
    _cartCtrl = Get.find<CartController>();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      _launchWebPopup();
    } else {
      _setupWebView();
    }
    _startWebPoll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_completed) {
      _verifyAndRoute(silent: true);
    }
  }

  void _setupWebView() {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _pageLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _pageLoading = false);
            if (_isTerminalUrl(url)) _onTerminalUrl(url);
          },
          onNavigationRequest: (req) {
            if (_isTerminalUrl(req.url)) {
              _onTerminalUrl(req.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _pageLoading = false);
          },
        ),
      );
    _webview = c;
    _loadCheckout(c);
  }

  Future<void> _loadCheckout(WebViewController controller) async {
    final checkout = _init!.checkout;
    if (checkout.postHtml.isNotEmpty) {
      await controller.loadHtmlString(
        checkout.postHtml,
        baseUrl: checkout.postBaseUrl.isNotEmpty ? checkout.postBaseUrl : null,
      );
      return;
    }
    final url = checkout.redirectUrl;
    if (url.isNotEmpty) {
      await controller.loadRequest(Uri.parse(url));
    }
  }

  Future<void> _launchWebPopup() async {
    final checkout = _init!.checkout;
    final url = checkout.redirectUrl;
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {}
  }

  void _startWebPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) async {
      if (!mounted || _completed) {
        _pollTimer?.cancel();
        return;
      }
      await _verifyAndRoute(silent: true);
    });
  }

  bool _isTerminalUrl(String url) =>
      PaymentGatewayUrls.isTerminalCallbackUrl(url);

  Future<void> _onTerminalUrl(String url) async {
    if (_completed) return;
    _completed = true;
    _pollTimer?.cancel();
    await _verifyAndRoute();
  }

  Future<void> _verifyAndRoute({bool silent = false}) async {
    if (_ctrl.isVerifying) return;
    final init = _init;
    if (init == null) return;
    final r = await _ctrl.verify(init.orderId, init.reference);
    if (!mounted) return;

    if (silent && r == null) return;
    if (silent && r != null && !_isTerminalVerify(r)) return;

    if (r == null) {
      _completed = true;
      Get.offNamed(
        AppRoutes.userDonationFailed,
        arguments: DonationFailedArgs(
          reference: init.reference,
          status: VerifyStatus.unknown,
          message: _ctrl.lastError,
        ),
      );
      return;
    }
    if (r.isPaid) {
      _completed = true;
      await _cartCtrl.clearCart();
      Get.offNamed(AppRoutes.poojaKitOrderSuccess, arguments: r);
    } else if (_isTerminalVerify(r)) {
      _completed = true;
      Get.offNamed(
        AppRoutes.userDonationFailed,
        arguments: DonationFailedArgs(
          reference: r.reference,
          status: r.status,
          message: _ctrl.lastError,
        ),
      );
    }
  }

  bool _isTerminalVerify(VerifyResult r) =>
      r.status == VerifyStatus.success ||
      r.status == VerifyStatus.failed ||
      r.status == VerifyStatus.abandoned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textColor,
        elevation: 0,
      ),
      body: kIsWeb
          ? _PaymentWebFallback(
              reference: _init?.reference ?? '',
              relaunch: _launchWebPopup,
              verifyNow: () => _verifyAndRoute(),
            )
          : Stack(
              children: [
                if (_webview != null)
                  WebViewWidget(controller: _webview!)
                else
                  const SizedBox.shrink(),
                if (_pageLoading)
                  const ColoredBox(
                    color: Colors.white,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}

class _PaymentWebFallback extends StatelessWidget {
  const _PaymentWebFallback({
    required this.reference,
    required this.relaunch,
    required this.verifyNow,
  });

  final String reference;
  final Future<void> Function() relaunch;
  final Future<void> Function() verifyNow;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(Icons.lock_outline, size: 48, color: AppColors.textColor),
            const SizedBox(height: 14),
            const Text(
              'Complete the payment in the secure tab',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Finish payment in the opened tab. We will detect completion '
              'automatically when you return.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => verifyNow(),
              child: const Text("I've completed the payment"),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => relaunch(),
              child: const Text('Re-open payment page'),
            ),
            if (reference.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Ref: $reference',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
