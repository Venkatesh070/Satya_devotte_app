// Post-init "Confirming your donation…" screen.
//
// Why no in-app WebView? The project doesn't ship `webview_flutter` and the
// plan explicitly forbids unrelated new dependencies. We launch the
// Paystack URL via the existing `url_launcher` in an external browser /
// Custom Tab. Because we can't intercept the redirect, we make the verify
// endpoint the single source of truth (which the plan also mandates):
//
//   • when the user comes back to the app (`AppLifecycleState.resumed`)
//     we trigger an immediate verify;
//   • we also poll verify every 3s (up to ~1 min) so the UI completes
//     itself even if the user never re-focuses the app;
//   • a manual "I've completed the payment" button lets the user force
//     verify when they're ready.
//
// On any terminal verify (`success` / `failed` / `abandoned`) we route to
// the matching screen. `unknown` is treated as failed (with retry), per
// the plan's state machine.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_init_data.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donation_failed_screen.dart';
import 'package:satya_devotte_app/features/donations/state/donate_controller.dart';

class DonationConfirmingScreen extends StatefulWidget {
  const DonationConfirmingScreen({super.key});

  @override
  State<DonationConfirmingScreen> createState() =>
      _DonationConfirmingScreenState();
}

class _DonationConfirmingScreenState extends State<DonationConfirmingScreen>
    with WidgetsBindingObserver {
  late final DonationInitData _init;
  late final DonateController _ctrl;

  bool _completed = false;
  bool _launching = false;
  int _pollAttempts = 0;
  static const _maxPollAttempts = 20; // 20 × 3s ≈ 1 min auto-poll window.
  static const _pollEvery = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is! DonationInitData) {
      // Defensive — if we somehow landed here without args, just leave.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Get.back();
      });
      _init = const DonationInitData(
        reference: '',
        authorizationUrl: '',
        amount: 0,
        currency: 'ZAR',
        donationId: '',
        donationTitle: '',
        contributionId: '',
        contributionNumber: '',
      );
      _ctrl = Get.find<DonateController>();
      return;
    }
    _init = arg;
    _ctrl = Get.find<DonateController>();
    WidgetsBinding.instance.addObserver(this);
    // Kick off the external browser and start polling verify in parallel.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPaystack();
      _schedulePoll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_completed) {
      // User came back from the browser — verify immediately.
      _verifyNow();
    }
  }

  Future<void> _openPaystack() async {
    if (_init.authorizationUrl.isEmpty) return;
    setState(() => _launching = true);
    try {
      final uri = Uri.parse(_init.authorizationUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // If launch fails, the user can still tap "Open payment page" again.
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _schedulePoll() {
    Future.delayed(_pollEvery, () async {
      if (!mounted || _completed) return;
      if (_pollAttempts >= _maxPollAttempts) return;
      _pollAttempts++;
      await _verifyNow(silent: true);
      if (mounted && !_completed) _schedulePoll();
    });
  }

  Future<void> _verifyNow({bool silent = false}) async {
    if (_completed) return;
    if (_ctrl.isVerifying) return;
    if (_init.reference.isEmpty) return;
    final result = await _ctrl.verify(_init.reference);
    if (!mounted || _completed) return;
    if (result != null && _isTerminal(result)) {
      _completed = true;
      _routeFor(result);
    } else if (!silent && result == null) {
      // Surfaces the inline error via Obx — no popup spam.
      setState(() {});
    }
  }

  bool _isTerminal(VerifyResult r) {
    // success / failed / abandoned are terminal. `unknown` keeps polling
    // until the user explicitly gives up.
    return r.status == VerifyStatus.success ||
        r.status == VerifyStatus.failed ||
        r.status == VerifyStatus.abandoned;
  }

  void _routeFor(VerifyResult r) {
    if (r.isPaid) {
      Get.offNamed(AppRoutes.userDonationSuccess, arguments: r);
    } else {
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

  Future<bool> _handlePop() async {
    if (_completed) return true;
    // Plan: kick off verify before popping. Best-effort, non-blocking.
    await _verifyNow(silent: true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handlePop,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF1DD),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textColor,
                    onPressed: () async {
                      if (await _handlePop()) {
                        if (mounted) Get.back();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _Header(init: _init),
                const SizedBox(height: 24),
                const Center(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFB10F33),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confirming your donation…',
                  textAlign: TextAlign.center,
                  style: AppTypography.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete the payment in the browser window we just '
                  'opened. We will detect it automatically when you return.',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF6B5841),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final err = _ctrl.lastError;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      err,
                      textAlign: TextAlign.center,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: const Color(0xFFB10F1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
                _PrimaryButton(
                  label: 'I\'ve completed the payment',
                  onPressed: _completed ? null : () => _verifyNow(),
                  loading: false,
                ),
                const SizedBox(height: 10),
                _SecondaryButton(
                  label: _launching ? 'Opening…' : 'Open payment page',
                  onPressed: _launching ? null : _openPaystack,
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'Ref: ${_init.reference}',
                    style: AppTypography.inter(
                      fontSize: 11,
                      color: const Color(0xFF8C7A60),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.init});
  final DonationInitData init;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB10F33),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textColor,
          side: const BorderSide(color: Color(0xFFE3D9C2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
