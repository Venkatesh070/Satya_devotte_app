import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

class ContributionTile extends StatelessWidget {
  const ContributionTile({super.key, required this.contribution});

  final DonationContribution contribution;

  @override
  Widget build(BuildContext context) {
    return RecordDonationTile(
      contribution: contribution,
      onTap:
          contribution.status == ContributionStatus.paid &&
              contribution.contributionNumber.isNotEmpty
          ? () => _showReceiptSheet(context, contribution)
          : null,
    );
  }

  void _showReceiptSheet(
    BuildContext context,
    DonationContribution contribution,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFCF7EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DonationUi.cardBorder,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: DonationUi.cardBorder, width: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Receipt',
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _ReceiptRow('Amount', contribution.formattedAmount),
            if (contribution.donationTitle.isNotEmpty)
              _ReceiptRow('Purpose', contribution.donationTitle),
            if (contribution.formattedDate.isNotEmpty)
              _ReceiptRow('Date', contribution.formattedDate),
            if (contribution.contributionNumber.isNotEmpty)
              _ReceiptRow('Receipt #', contribution.contributionNumber),
            const SizedBox(height: 20),
            DonationOrangeButton(label: 'Close', onPressed: Get.back),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.inter(
                fontSize: 13,
                color: DonationUi.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
