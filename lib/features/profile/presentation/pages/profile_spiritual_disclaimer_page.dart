import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

/// Screen displaying the Spiritual Disclaimer for the Sathya App.
class ProfileSpiritualDisclaimerPage extends StatelessWidget {
  const ProfileSpiritualDisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(
        title: 'Our Spiritual Disclaimer',
        onBack: Get.back,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Spiritual Disclaimer',
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The Sathya App has been created to simplify and encourage a deeper understanding of Hindu practices, traditions, festivals, deities and spiritual teachings.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hinduism is an immense, ancient and diverse spiritual tradition. The app presents only a small fraction of its many deities, traditions, philosophies and teachings, and does not claim to represent Hinduism in its entirety.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The content reflects Sathya’s interpretation and understanding of the Vedas, spiritual scriptures and traditional teachings. Different communities, traditions and individuals may hold different interpretations and follow different practices, and we deeply respect these diverse expressions of faith.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The Sathya App is intended for learning, reflection and spiritual exploration. It does not seek to prescribe or establish any single definitive interpretation of Hinduism.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'With respect for every path, every tradition and every spiritual experience. 🙏',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: DonationUi.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
