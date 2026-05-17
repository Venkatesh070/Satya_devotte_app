import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

/// Figma About the app — scrollable body text.
class ProfileAboutPage extends StatelessWidget {
  const ProfileAboutPage({super.key});

  static const _body = '''
Sathya Devotee helps you stay connected with your spiritual practice through daily rituals, poojas, donations, and temple events.

Our mission is to make devotion accessible—whether you are at home or at the temple. Browse causes, offer seva, track your contributions, and grow through consistent practice.

This app is built with care for devotees worldwide. Thank you for being part of our community.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: 'About the app', onBack: Get.back),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Text(
          _body.trim(),
          style: AppTypography.inter(
            fontSize: 14,
            height: 1.6,
            color: DonationUi.textPrimary,
          ),
        ),
      ),
    );
  }
}
