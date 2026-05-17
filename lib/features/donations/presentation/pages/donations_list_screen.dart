import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_card.dart';
import 'package:satya_devotte_app/features/donations/state/donations_list_controller.dart';

class DonationsListScreen extends StatelessWidget {
  const DonationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DonationsListController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9F3),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ctrl.refreshDonations();
                await ctrl.fetchContributions();
              },
              child: Obx(() {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(child: _buildSummaryCard(ctrl)),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Offer your donations to',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B1E08),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    if (ctrl.isLoading && ctrl.items.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _ListSkeleton(),
                        ),
                      )
                    else if (ctrl.error != null && ctrl.items.isEmpty)
                      SliverToBoxAdapter(
                        child: _ErrorState(
                          message: ctrl.error!,
                          onRetry: ctrl.refreshDonations,
                        ),
                      )
                    else if (ctrl.isEmpty)
                      const SliverToBoxAdapter(child: _EmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((_, i) {
                            final d = ctrl.items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DonationCard(
                                donation: d,
                                onTap: () => _openDetails(d),
                              ),
                            );
                          }, childCount: ctrl.items.length),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
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
                      Text(
                        'Donations',
                        style: AppTypography.lora(
                          fontSize: 22,
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'History',
                            style: AppTypography.inter(
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
    final total = NumberFormat.currency(
      symbol: 'R ',
      decimalDigits: ctrl.totalDonated.truncateToDouble() == ctrl.totalDonated
          ? 0
          : 2,
    ).format(ctrl.totalDonated);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E5D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'total donated',
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: const Color(0xFF8A6B4A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total,
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F4CB7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFFF3E5D0),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'contributions',
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: const Color(0xFF8A6B4A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ctrl.contributionsCount}',
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3B1E08),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(Donation donation) {
    Get.toNamed(AppRoutes.userDonationDetails, arguments: donation);
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

class _TempleHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    final controlPoint1 = Offset(size.width * 0.25, size.height);
    final endPoint1 = Offset(size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(
      controlPoint1.dx,
      controlPoint1.dy,
      endPoint1.dx,
      endPoint1.dy,
    );

    final controlPoint2 = Offset(size.width * 0.75, size.height - 60);
    final endPoint2 = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint2.dx,
      endPoint2.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
