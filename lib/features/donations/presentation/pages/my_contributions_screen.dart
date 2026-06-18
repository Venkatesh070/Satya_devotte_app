// Figma "My Contributions" / Record of Donations — history list.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/contribution_tile.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/donations/state/my_contributions_controller.dart';
import 'package:satya_devotte_app/shared/widgets/chakra_loading_indicator.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  final _scrollCtrl = ScrollController();
  late final MyContributionsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<MyContributionsController>();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _ctrl.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationUi.background,
      appBar: AppBar(
        backgroundColor: DonationUi.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: DonationUi.textPrimary,
          onPressed: () => Get.back(),
        ),
        title: Text(
          'History of Contributions',
          style: AppTypography.lora(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: DonationUi.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _ctrl.refreshContributions,
        child: Obx(() {
          return CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_ctrl.isLoading && _ctrl.items.isEmpty)
                const SliverFillRemaining(child: _Skeleton())
              else if (_ctrl.error != null && _ctrl.items.isEmpty)
                SliverFillRemaining(
                  child: _ErrorState(
                    message: _ctrl.error!,
                    onRetry: _ctrl.refreshContributions,
                  ),
                )
              else if (_ctrl.isEmpty)
                const SliverFillRemaining(child: _EmptyState())
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final item = _ctrl.items[i];
                    return ContributionTile(contribution: item);
                  }, childCount: _ctrl.items.length),
                ),
                if (_ctrl.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: ChakraLoadingIndicator(size: 22),
                        ),
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No contributions yet',
        style: AppTypography.inter(color: DonationUi.textMuted),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE6D2),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
