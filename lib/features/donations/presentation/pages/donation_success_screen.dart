import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/verify_result.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';

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
    final date = r?.contribution?.formattedDate ?? '';

    return Scaffold(
      backgroundColor: DonationUi.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F6EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: DonationUi.successGreen,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Thank you for your donation!',
                textAlign: TextAlign.center,
                style: AppTypography.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: DonationUi.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DonationUi.cardFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DonationUi.cardBorder),
                ),
                child: Column(
                  children: [
                    _Row('Purpose', title),
                    if (amountText != null) ...[
                      const SizedBox(height: 12),
                      _Row('Amount', amountText),
                    ],
                    if (number.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Row('Receipt', '#$number'),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Row('Date', date),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              CustomButton(
                label: 'Back to Home',
                textColor: Colors.white,
                gradientColors: kFigmaActionGradient,
                borderRadius: 14,
                onTap: () => Get.offAllNamed(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 13,
            color: DonationUi.textMuted,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DonationUi.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
