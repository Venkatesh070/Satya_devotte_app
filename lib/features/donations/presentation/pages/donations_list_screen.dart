// User-facing list of approved donations. Tapping a card opens the
// details screen; tapping "Donate" jumps straight into the amount sheet.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/pages/donate_amount_sheet.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_card.dart';
import 'package:satya_devotte_app/features/donations/state/donations_list_controller.dart';

class DonationsListScreen extends StatelessWidget {
  const DonationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DonationsListController>();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF1DD),
      appBar: AppBar(
        title: const Text('Donations'),
        backgroundColor: AppColors.appBgColor,
        foregroundColor: AppColors.textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'My contributions',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Get.toNamed(AppRoutes.userContributions),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ctrl.refreshDonations,
        child: Obx(() {
          if (ctrl.isLoading && ctrl.items.isEmpty) {
            return const _ListSkeleton();
          }
          if (ctrl.error != null && ctrl.items.isEmpty) {
            return _ErrorState(
              message: ctrl.error!,
              onRetry: ctrl.refreshDonations,
            );
          }
          if (ctrl.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: ctrl.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final d = ctrl.items[i];
              return DonationCard(
                donation: d,
                onTap: () => _openDetails(d),
                onDonate: () => _openAmountSheet(context, d),
              );
            },
          );
        }),
      ),
    );
  }

  void _openDetails(Donation donation) {
    Get.toNamed(AppRoutes.userDonationDetails, arguments: donation);
  }

  void _openAmountSheet(BuildContext context, Donation donation) {
    DonateAmountSheet.show(context, donation: donation);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.volunteer_activism_outlined,
          size: 56,
          color: Color(0xFFB18A55),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'No donations available',
            style: AppTypography.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Check back soon — new causes are approved regularly.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 13,
                color: const Color(0xFF6B5841),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.error_outline,
            size: 56, color: Color(0xFFB10F1A)),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Something went wrong',
            style: AppTypography.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 13,
                color: const Color(0xFF6B5841),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFEFE6D2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
