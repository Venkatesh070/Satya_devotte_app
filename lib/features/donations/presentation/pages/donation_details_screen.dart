// Single-donation detail screen reached from the home circle tile or
// from the donations list. Primary CTA opens [DonateAmountSheet].
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donate_amount_sheet.dart';

class DonationDetailsScreen extends StatelessWidget {
  const DonationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    if (arg is! Donation) {
      // Defensive: prevent a crash if navigated to without arguments.
      return Scaffold(
        backgroundColor: const Color(0xFFFAF1DD),
        appBar: AppBar(
          backgroundColor: AppColors.appBgColor,
          foregroundColor: AppColors.textColor,
          elevation: 0,
        ),
        body: const Center(child: Text('Donation not found.')),
      );
    }
    final donation = arg;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF1DD),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: AppColors.appBgColor,
            foregroundColor: AppColors.textColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(url: donation.imageUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.title,
                    style: AppTypography.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (donation.description.isNotEmpty)
                    Text(
                      donation.description,
                      style: AppTypography.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF4A1C00),
                      ),
                    )
                  else
                    Text(
                      'Support this cause and earn blessings.',
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B5841),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () =>
                  DonateAmountSheet.show(context, donation: donation),
              icon: const Icon(Icons.favorite_outline),
              label: const Text(
                'Donate now',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB10F33),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFEADCC3),
      alignment: Alignment.center,
      child: const Icon(
        Icons.volunteer_activism_outlined,
        size: 72,
        color: Color(0xFF8C5A2A),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    return Image.asset(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder);
  }
}
