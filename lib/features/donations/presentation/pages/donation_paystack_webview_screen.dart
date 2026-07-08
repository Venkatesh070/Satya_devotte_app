// In-app Paystack WebView.
//
// Loads `DonationInitData.authorizationUrl` in `webview_flutter`. A
// [NavigationDelegate.onNavigationRequest] intercepts every URL change
// and, when a terminal Paystack callback is matched, prevents the in-page
// navigation and triggers a verify against the backend (the only trusted
// source of truth — never trust the redirect alone).
//
// State machine (mirrors `donations-flow.plan`):
//
//   • Loading the auth URL → spinner overlay until first page commits.
//   • Terminal URL detected → "Confirming your donation…" overlay, then
//     `DonateController.verify(reference)`.
//   • verify.status == success → push success screen.
//   • verify.status == failed | abandoned → push failed screen.
//   • verify.status == unknown OR verify error after 3 retries →
//     push failed screen with a "Try again" CTA (re-verify is idempotent).
//   • System back: if the WebView can go back internally we let it; else
//     we kick off one best-effort verify before popping (the user may have
//     completed payment before pressing back).
//
// Flutter web fallback: `webview_flutter` does not support the web
// platform. On web we render a polished "Open in a new tab + we'll auto-
// confirm" panel and use the existing `url_launcher` (no new dependency).
// Verify still drives all decisions.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:satya_devotte_app/core/payments/payment_gateway_urls.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_init_data.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donation_failed_screen.dart';
import 'package:satya_devotte_app/features/donations/state/donate_controller.dart';
class DonationPaystackWebViewScreen extends StatefulWidget {
  const DonationPaystackWebViewScreen({super.key});

  @override
  State<DonationPaystackWebViewScreen> createState() =>
      _DonationPaystackWebViewScreenState();
}

class _DonationPaystackWebViewScreenState
    extends State<DonationPaystackWebViewScreen> with WidgetsBindingObserver {
  late final DonateController _ctrl;
  DonationInitData? _init;

  WebViewController? _webview;
  bool _completed = false;
  bool _pageLoading = true;

  // Auto-verify polling on web (where we can't intercept the redirect
  // from a popup window). Mobile uses navigation interception instead.
  Timer? _pollTimer;
  static const _pollEvery = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is! DonationInitData || !arg.checkout.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Get.back();
      });
      return;
    }
    _init = arg;
    _ctrl = Get.find<DonateController>();
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
    // When the user returns to the tab/app after a redirect, trigger an
    // immediate verify so we don't wait for the next poll tick.
    if (state == AppLifecycleState.resumed && !_completed) {
      _verifyAndRoute(silent: true);
    }
  }

  // ── Mobile (webview_flutter) ────────────────────────────────
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

  // ── Web fallback (popup + poll) ─────────────────────────────
  Future<void> _launchWebPopup() async {
    final checkout = _init!.checkout;
    final url = checkout.redirectUrl;
    if (url.isEmpty) return;
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      // User can retry from the on-screen button.
    }
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

  // ── Shared: detect terminal URL ─────────────────────────────
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
    final r = await _ctrl.verify(init.reference);
    if (!mounted) return;

    // Web silent poll: terminal → route, transient → wait for next tick.
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
      Get.offNamed(AppRoutes.userDonationSuccess, arguments: r);
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

  // ── Back-press handling ────────────────────────────────────
  Future<bool> _onBack() async {
    if (_completed) return true;
    // Let the WebView consume back navigation first (Paystack flows often
    // have internal "back" steps like switching card type).
    if (_webview != null) {
      final canGoBack = await _webview!.canGoBack();
      if (canGoBack) {
        await _webview!.goBack();
        return false;
      }
    }
      // Best-effort verify before leaving — the user may have actually paid.
    await _verifyAndRoute(silent: true);
    if (_completed) return true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_init == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF1DD),
        body: SizedBox.shrink(),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onBack();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Complete payment'),
          backgroundColor: AppColors.appBgColor,
          foregroundColor: AppColors.textColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onBack();
              if (shouldPop && mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: kIsWeb
          ? _WebFallback(
              init: _init!,
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
      ),
    );
  }
}

class _WebFallback extends StatelessWidget {
  const _WebFallback({
    required this.init,
    required this.relaunch,
    required this.verifyNow,
  });

  final DonationInitData init;
  final Future<void> Function() relaunch;
  final Future<void> Function() verifyNow;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              init.donationTitle.isEmpty ? 'Donation' : init.donationTitle,
              style: AppTypography.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${init.currency} ${init.amount}',
              style: AppTypography.inter(
                fontSize: 13,
                color: const Color(0xFF6B5841),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.lock_outline,
                size: 48, color: Color(0xFFB10F33)),
            const SizedBox(height: 14),
            Text(
              'Complete the payment in the secure tab',
              textAlign: TextAlign.center,
              style: AppTypography.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flutter web cannot embed PayFast inline. The payment page '
              'opened in a new tab — finish there and we will detect it '
              'automatically when you come back.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF6B5841),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => verifyNow(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB10F33),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'I\'ve completed the payment',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => relaunch(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textColor,
                  side: const BorderSide(color: Color(0xFFE3D9C2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Re-open payment page',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Ref: ${init.reference}',
                style: AppTypography.inter(
                  fontSize: 11,
                  color: const Color(0xFF8C7A60),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
