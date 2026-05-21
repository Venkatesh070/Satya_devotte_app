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
      body: Obx(() {
        final items = ctrl.items;
        final loading = ctrl.isLoading;
        final error = ctrl.error;
        final total = ctrl.totalDonated;
        final count = ctrl.contributionsCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FigmaDonationsHeader(
              onBack: () => Get.back(),
              onHistory: () => Get.toNamed(AppRoutes.userContributions),
            ),
            Expanded(
              child: RefreshIndicator(
                color: DonationUi.amountBlue,
                onRefresh: () async {
                  await ctrl.refreshDonations();
                  await ctrl.fetchContributions();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Text(
                          'Donations',
                          textAlign: TextAlign.left,
                          style: AppTypography.lora(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: DonationUi.textPrimary,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DonationSummaryCard(
                          totalLabel: 'Total Donated',
                          totalValue: DonationUi.formatCurrency(total),
                          countLabel: 'Contributions',
                          countValue: '$count',
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 22)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Offer your donations to',
                          style: AppTypography.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: DonationUi.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (loading && items.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(child: _ListSkeleton()),
                      )
                    else if (error != null && items.isEmpty)
                      SliverToBoxAdapter(
                        child: _ErrorState(
                          message: error,
                          onRetry: ctrl.refreshDonations,
                        ),
                      )
                    else if (items.isEmpty)
                      const SliverToBoxAdapter(child: _EmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((_, i) {
                            final d = items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DonationCard(
                                donation: d,
                                onTap: () => MakeDonationScreen.show(
                                  context,
                                  donation: d,
                                ),
                              ),
                            );
                          }, childCount: items.length),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
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
