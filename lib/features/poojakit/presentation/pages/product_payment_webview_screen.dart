// lib/features/poojakit/presentation/pages/product_payment_webview_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
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
  bool _pageLoading = true;
  bool _completed = false;
  bool _verifyOverlay = false;

  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const _maxPollAttempts = 20;
  static const _pollEvery = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is! OrderInitData || arg.authorizationUrl.isEmpty) {
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
      _startWebPoll();
    } else {
      _setupWebView();
    }
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
        ),
      )
      ..loadRequest(Uri.parse(_init!.authorizationUrl));
    _webview = c;
  }

  Future<void> _launchWebPopup() async {
    try {
      await launchUrl(Uri.parse(_init!.authorizationUrl));
    } catch (_) {}
  }

  void _startWebPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollEvery, (_) async {
      if (!mounted || _completed) {
        _pollTimer?.cancel();
        return;
      }
      _pollAttempts++;
      if (_pollAttempts > _maxPollAttempts) {
        _pollTimer?.cancel();
        return;
      }
      await _verifyAndRoute(silent: true);
    });
  }

  bool _isTerminalUrl(String url) {
    if (url.isEmpty) return false;
    final u = url.toLowerCase();
    return u.contains('/standard/close') ||
        u.contains('/standard/success') ||
        u.contains('reference=') ||
        u.contains('trxref=') ||
        u.contains('payment/return') ||
        u.contains('order/return');
  }

  Future<void> _onTerminalUrl(String url) async {
    if (_completed) return;
    _completed = true;
    _pollTimer?.cancel();
    if (mounted) setState(() => _verifyOverlay = true);
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

    setState(() => _verifyOverlay = false);
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
      body: Stack(
        children: [
          if (_webview != null) WebViewWidget(controller: _webview!),
          if (_pageLoading || _verifyOverlay)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
