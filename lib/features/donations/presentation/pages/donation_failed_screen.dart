// Failure / abandoned state for a donation reference.
//
// Args are passed via `Get.arguments` as [DonationFailedArgs]. The screen
// is a dead-end on its own — the user can retry the same donation (which
// re-opens the amount sheet for it), re-verify the same reference (safe
// because backend is idempotent), or go back to the donations list.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';
import 'package:satya_devotte_app/features/donations/state/donate_controller.dart';

class DonationFailedArgs {
  const DonationFailedArgs({
    required this.reference,
    required this.status,
    this.message,
  });
  final String reference;
  final VerifyStatus status;
  final String? message;
}

class DonationFailedScreen extends StatefulWidget {
  const DonationFailedScreen({super.key});

  @override
  State<DonationFailedScreen> createState() => _DonationFailedScreenState();
}

class _DonationFailedScreenState extends State<DonationFailedScreen> {
  late final DonationFailedArgs _args;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    _args = arg is DonationFailedArgs
        ? arg
        : const DonationFailedArgs(
            reference: '',
            status: VerifyStatus.unknown,
          );
  }

  String _label() {
    switch (_args.status) {
      case VerifyStatus.failed:
        return 'Payment failed';
      case VerifyStatus.abandoned:
        return 'Payment was cancelled';
      case VerifyStatus.unknown:
        return 'We couldn\'t confirm your payment';
      case VerifyStatus.success:
        return 'Something looks off';
    }
  }

  String _subtitle() {
    switch (_args.status) {
      case VerifyStatus.failed:
        return 'Your bank declined the transaction. No money was taken.';
      case VerifyStatus.abandoned:
        return 'You closed the payment page before completing it. '
            'You can try again any time.';
      case VerifyStatus.unknown:
        return _args.message ??
            'Your payment may still be processing. You can verify again '
                'safely — duplicates are prevented.';
      case VerifyStatus.success:
        return 'Please reach out to support if you see anything unexpected.';
    }
  }

  Future<void> _retryVerify() async {
    if (_args.reference.isEmpty) return;
    final ctrl = Get.find<DonateController>();
    final result = await ctrl.verify(_args.reference);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.lastError ?? 'Could not verify yet.')),
      );
      return;
    }
    if (result.isPaid) {
      Get.offNamed(AppRoutes.userDonationSuccess, arguments: result);
    } else {
      setState(() {}); // refresh subtitle / status label
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF1DD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDECEC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFB10F1A),
                  size: 56,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _label(),
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _subtitle(),
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF6B5841),
                  ),
                ),
              ),
              if (_args.reference.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Ref: ${_args.reference}',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: const Color(0xFF8C7A60),
                  ),
                ),
              ],
              const Spacer(),
              Obx(() {
                final ctrl = Get.find<DonateController>();
                final loading = ctrl.isVerifying;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        (loading || _args.reference.isEmpty) ? null : _retryVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB10F33),
                      foregroundColor: Color(0xFFFCF7EF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Color(0xFFFCF7EF),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Try again',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () =>
                      Get.offAllNamed(AppRoutes.userDonations),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textColor,
                    side: const BorderSide(color: Color(0xFFE3D9C2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to donations',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
