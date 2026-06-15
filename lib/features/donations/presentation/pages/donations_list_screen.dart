import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_card.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/make_donation_screen.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_summary_card.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/donations/state/donations_list_controller.dart';

class DonationsListScreen extends StatelessWidget {
  const DonationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DonationsListController>();

    return Scaffold(
      backgroundColor: DonationUi.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FigmaDonationsHeader(
            onBack: () => Get.back(),
            onHistory: () => Get.toNamed(AppRoutes.userContributions),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contributions',
                    style: AppTypography.lora(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: DonationUi.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _GeneralDonationCard(
                    onDonate: () => MakeDonationScreen.show(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralDonationCard extends StatelessWidget {
  const _GeneralDonationCard({required this.onDonate});

  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF421204), Color(0xFF8B2C0F), Color(0xFFC04E15)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make Contribution',
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Help us give you an outstanding experience for the applications',
            style: AppTypography.lora(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your donation helps us improve the experience limitlessly without',
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: onDonate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE87C3E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                'Contribute Now',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma: cream bar, back + History pill, no hero image.
class _FigmaDonationsHeader extends StatelessWidget {
  const _FigmaDonationsHeader({required this.onBack, required this.onHistory});

  final VoidCallback onBack;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DonationUi.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_sharp,
                    size: 20,
                    color: DonationUi.textPrimary,
                  ),
                  onPressed: onBack,
                ),
              ),
              const Spacer(),
              DonationHistoryChip(onTap: onHistory),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.volunteer_activism_outlined,
            size: 56,
            color: Color(0xFFB18A55),
          ),
          const SizedBox(height: 12),
          Text(
            'No donations available',
            textAlign: TextAlign.center,
            style: AppTypography.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DonationUi.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE6D2),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
