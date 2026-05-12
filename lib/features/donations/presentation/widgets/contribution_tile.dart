import 'package:flutter/material.dart';

import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/status_badge.dart';

class ContributionTile extends StatelessWidget {
  const ContributionTile({super.key, required this.contribution});

  final DonationContribution contribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE3D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  contribution.donationTitle.isEmpty
                      ? 'Donation'
                      : contribution.donationTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: contribution.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                contribution.formattedAmount,
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
              ),
              const Spacer(),
              if (contribution.contributionNumber.isNotEmpty)
                Text(
                  '#${contribution.contributionNumber}',
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7F6C53),
                  ),
                ),
            ],
          ),
          if (contribution.formattedDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contribution.formattedDate,
              style: AppTypography.inter(
                fontSize: 11,
                color: const Color(0xFF8C7A60),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
