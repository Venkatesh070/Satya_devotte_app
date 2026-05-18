import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

/// Split summary — Total Donated | Contributions (Figma Donations screen).
class DonationSummaryCard extends StatelessWidget {
  const DonationSummaryCard({
    super.key,
    required this.totalLabel,
    required this.totalValue,
    required this.countLabel,
    required this.countValue,
    this.totalValueColor = DonationUi.amountBlue,
  });

  final String totalLabel;
  final String totalValue;
  final String countLabel;
  final String countValue;
  final Color totalValueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: DonationUi.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DonationUi.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalLabel,
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: DonationUi.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalValue,
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: totalValueColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: DonationUi.cardBorder,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countLabel,
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: DonationUi.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countValue,
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DonationUi.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
