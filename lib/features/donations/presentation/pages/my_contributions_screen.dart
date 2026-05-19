// Figma "My Contributions" / Record of Donations — history list.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/contribution_tile.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/donation_ui.dart';
import 'package:satya_devotte_app/features/donations/state/my_contributions_controller.dart';

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
      backgroundColor: const Color(0xFFFEF9F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF9F3),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3B1E08)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'History of Donations',
          style: AppTypography.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B1E08),
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
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ContributionTile(contribution: _ctrl.items[i]),
                    childCount: _ctrl.items.length,
                  ),
                ),
                if (_ctrl.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
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
