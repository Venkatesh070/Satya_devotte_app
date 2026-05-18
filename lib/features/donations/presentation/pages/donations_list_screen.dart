import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
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
      backgroundColor: const Color(0xFFFEF9F3),
      body: Obx(() {
        // Explicitly access observables to ensure Obx tracks them
        final items = ctrl.items;
        final loading = ctrl.isLoading;
        final error = ctrl.error;
        // Trigger listeners for summary getters
        final total = ctrl.totalDonated;
        final count = ctrl.contributionsCount;

        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ctrl.refreshDonations();
                  await ctrl.fetchContributions();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(child: _buildSummaryCard(ctrl)),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Offer your donations to',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B1E08),
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
                              padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/appHeaderImg.png'),
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      const Text(
                        'Donations',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Lora',
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.userContributions),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'History',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(DonationsListController ctrl) {
    return DonationSummaryCard(
      totalLabel: 'total donated',
      totalValue: DonationUi.formatCurrency(ctrl.totalDonated),
      countLabel: 'contributions',
      countValue: '${ctrl.contributionsCount}',
    );
  }
}

class _TempleHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);

    // Create a scalloped arch with 3 curves
    final scallopWidth = size.width / 3;
    for (var i = 0; i < 3; i++) {
      final xStart = i * scallopWidth;
      final xEnd = (i + 1) * scallopWidth;
      path.quadraticBezierTo(
        xStart + scallopWidth / 2,
        size.height + 10,
        xEnd,
        size.height - 30,
      );
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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
              color: const Color(0xFF3B1E08),
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
