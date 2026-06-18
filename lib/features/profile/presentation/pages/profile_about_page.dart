import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';

/// Figma About the app — scrollable body text.
class ProfileAboutPage extends StatelessWidget {
  const ProfileAboutPage({super.key});

  static const _body = '''
About the App

Short Description

Streamline your daily prayers, track moon phases, and get Puja Kits delivered.

Long Description

Experience Spiritual Alignment Every Day with the Sathya Application.

Sathya is your personal digital sanctuary, designed to bridge ancient Vedic traditions with modern convenience. Whether you are seeking to maintain a consistent daily ritual practice, track significant astronomical shifts, or easily source authentic spiritual items, Sathya provides a streamlined, secure ecosystem to guide your journey.

Operated under RedIn Consulting, our platform offers verified, end-to-end solutions for contemporary devotees seeking structure, precision, and authenticity in their spiritual lifestyles.

Key Features Built for Your Practice:

Panchang & Precision Astronomical Tracking: Powered by integration with advanced space agency data streams, Sathya calculates highly accurate lunar calendars, planetary movements, and moon phases. Plan your shlokas, fasts, and festival observances with absolute astronomical confidence.

Automated Device Calendar Synchronization: Never miss an auspicious date again. With our native device calendar integration, you can instantly sync ritual timelines, upcoming festivals, and personalized alerts directly to your smartphone's built-in calendar.

The Authentic Puja Store: Sourcing individual items for specific prayers can be challenging. Our built-in e-commerce interface allows you to browse and purchase complete, pre-packaged Puja Kits as single, integrated units. Every kit is curated to ensure compliance with ritual specifications.

Reliable Warehouse-to-Door Logistics: Through our dedicated shipping partnership with The Courier Guy, all ordered Puja Kits are securely dispatched from our production centers and delivered straight to your home address with real-time tracking and automated waybill generation.

Secure Payment Architecture & Streamlined Administration: Enjoy complete peace of mind during transactions. Whether purchasing a ritual kit or making a voluntary spiritual contributions, all financial data is safely encrypted and processed via our verified payment gateway partner, Paystack.

Operational Transparency & Control:

Manage your spiritual journey with a platform designed for clarity. Sathya includes transparent built-in systems for tracking your order lifecycle, managing account profiles, and logging administrative reviews for product replacements or pre-dispatch order cancellations.

Step into a more organized, deeply connected spiritual routine. Download the Sathya Application today to invite structure and authentic ritual alignment into your modern home.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: DonationSimpleAppBar(title: 'About the app', onBack: Get.back),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About the App
            Text(
              'About the App',
              style: AppTypography.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Short Description
            // Text(
            //   'Short Description',
            //   style: AppTypography.lora(
            //     fontSize: 16,
            //     fontWeight: FontWeight.w600,
            //     color: DonationUi.textPrimary,
            //   ),
            // ),
            // const SizedBox(height: 8),
            Text(
              'Streamline your daily prayers, track moon phases, and get Puja Kits delivered.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Long Description
            // Text(
            //   'Long Description',
            //   style: AppTypography.lora(
            //     fontSize: 16,
            //     fontWeight: FontWeight.w600,
            //     color: DonationUi.textPrimary,
            //   ),
            // ),
            // const SizedBox(height: 8),
            Text(
              'Experience Spiritual Alignment Every Day with the Sathya Application.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sathya is your personal digital sanctuary, designed to bridge ancient Vedic traditions with modern convenience. Whether you are seeking to maintain a consistent daily ritual practice, track significant astronomical shifts, or easily source authentic spiritual items, Sathya provides a streamlined, secure ecosystem to guide your journey.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Operated under RedIn Consulting, our platform offers verified, end-to-end solutions for contemporary devotees seeking structure, precision, and authenticity in their spiritual lifestyles.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Key Features
            Text(
              'Key Features Built for Your Practice:',
              style: AppTypography.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Feature 1
            Text(
              '• Panchang & Precision Astronomical Tracking',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by integration with advanced space agency data streams, Sathya calculates highly accurate lunar calendars, planetary movements, and moon phases. Plan your shlokas, fasts, and festival observances with absolute astronomical confidence.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Feature 2
            Text(
              '• Automated Device Calendar Synchronization',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Never miss an auspicious date again. With our native device calendar integration, you can instantly sync ritual timelines, upcoming festivals, and personalized alerts directly to your smartphone\'s built-in calendar.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Feature 3
            Text(
              '• The Authentic Puja Store',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sourcing individual items for specific prayers can be challenging. Our built-in e-commerce interface allows you to browse and purchase complete, pre-packaged Puja Kits as single, integrated units. Every kit is curated to ensure compliance with ritual specifications.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Feature 4
            Text(
              '• Reliable Warehouse-to-Door Logistics',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Through our dedicated shipping partnership with The Courier Guy, all ordered Puja Kits are securely dispatched from our production centers and delivered straight to your home address with real-time tracking and automated waybill generation.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Feature 5
            Text(
              '• Secure Payment Architecture & Streamlined Administration',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enjoy complete peace of mind during transactions. Whether purchasing a ritual kit or making a voluntary spiritual contribution, all financial data is safely encrypted and processed via our verified payment gateway partner, Paystack.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Operational Transparency
            Text(
              'Operational Transparency & Control:',
              style: AppTypography.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your spiritual journey with a platform designed for clarity. Sathya includes transparent built-in systems for tracking your order lifecycle, managing account profiles, and logging administrative reviews for product replacements or pre-dispatch order cancellations.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Closing
            Text(
              'Step into a more organized, deeply connected spiritual routine. Download the Sathya Application today to invite structure and authentic ritual alignment into your modern home.',
              style: AppTypography.inter(
                fontSize: 14,
                height: 1.6,
                color: DonationUi.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
