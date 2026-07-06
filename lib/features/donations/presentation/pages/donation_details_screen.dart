import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/make_donation_screen.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/profile/presentation/widgets/profile_ui.dart';
import 'package:satya_devotte_app/shared/widgets/custom_button.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

class DonationDetailsScreen extends StatelessWidget {
  const DonationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;
    if (arg is! Donation) {
      return Scaffold(
        backgroundColor: DonationUi.background,
        appBar: DonationSimpleAppBar(title: 'Contribution', onBack: Get.back),
        body: const Center(child: Text('Contribution not found.')),
      );
    }
    final donation = arg;

    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: donation.title, onBack: Get.back),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: _HeroImage(url: donation.imageUrl),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: RichTextDisplay(
                      donation.description.isNotEmpty
                          ? donation.description
                          : null,
                      style: AppTypography.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: DonationUi.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: CustomButton(
                label: 'Contribute Now',
                textColor: Colors.white,
                gradientColors: kFigmaActionGradient,
                borderRadius: 14,
                onTap: () =>
                    MakeDonationScreen.show(context, donation: donation),
              ),
            ),
          ),
        ],
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
    return Image.asset(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
