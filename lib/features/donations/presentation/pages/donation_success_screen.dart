// Terminal "success" screen after verify confirms a paid contribution.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';

class DonationSuccessScreen extends StatelessWidget {
  const DonationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    final VerifyResult? r = arg is VerifyResult ? arg : null;
    final amount = r?.amount;
    final currency = r?.currency ?? 'ZAR';
    final amountText = amount == null
        ? null
        : NumberFormat.currency(
            name: currency,
            symbol: '${currency == 'ZAR' ? 'R' : currency} ',
            decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
          ).format(amount);
    final title = r?.contribution?.donationTitle ?? 'Donation';
    final number = r?.contribution?.contributionNumber ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF1DD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7F6EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF1F8A4C),
                      size: 56,
                    ),
                  ),
                ),
              ),
              Text(
                'Thank you for your donation!',
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A1C00),
                ),
              ),
              if (amountText != null) ...[
                const SizedBox(height: 6),
                Text(
                  amountText,
                  textAlign: TextAlign.center,
                  style: AppTypography.lora(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB10F33),
                  ),
                ),
              ],
              if (number.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Receipt #$number',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: const Color(0xFF7F6C53),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Get.offAllNamed(AppRoutes.userDonations),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB10F33),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.userContributions),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textColor,
                    side: const BorderSide(color: Color(0xFFE3D9C2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View receipt',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
