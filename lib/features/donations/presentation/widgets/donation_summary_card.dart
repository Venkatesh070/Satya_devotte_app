import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

/// Single stat — Figma: white card, muted label, large blue value.
class DonationSummaryMetricCard extends StatelessWidget {
  const DonationSummaryMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = DonationUi.amountBlue,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: DonationUi.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DonationUi.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: DonationUi.text,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF183EA4), Color(0xFFE35600)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              value,
              style: AppTypography.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: DonationUi.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// @deprecated Prefer [Row] of two [DonationSummaryMetricCard] (Figma split cards).
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DonationSummaryMetricCard(
            label: totalLabel,
            value: totalValue,
            valueColor: totalValueColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DonationSummaryMetricCard(
            label: countLabel,
            value: countValue,
            valueColor: DonationUi.amountBlue,
          ),
        ),
      ],
    );
  }
}
