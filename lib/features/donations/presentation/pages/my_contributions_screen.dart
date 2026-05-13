// Paginated, filterable history of the signed-in user's contributions.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/features/donations/presentation/widgets/contribution_tile.dart';
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

  String _labelFor(String f) {
    switch (f) {
      case 'PAID':
        return 'Paid';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF1DD),
      appBar: AppBar(
        title: const Text('My Contributions'),
        backgroundColor: AppColors.appBgColor,
        foregroundColor: AppColors.textColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _FilterBar(
            filters: MyContributionsController.filters,
            labelFor: _labelFor,
            ctrl: _ctrl,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _ctrl.refreshContributions,
              child: Obx(() {
                if (_ctrl.isLoading && _ctrl.items.isEmpty) {
                  return const _Skeleton();
                }
                if (_ctrl.error != null && _ctrl.items.isEmpty) {
                  return _ErrorState(
                    message: _ctrl.error!,
                    onRetry: _ctrl.refreshContributions,
                  );
                }
                if (_ctrl.isEmpty) {
                  return const _EmptyState();
                }
                final showFooter =
                    _ctrl.isLoadingMore || _ctrl.hasMore;
                return ListView.builder(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _ctrl.items.length + (showFooter ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= _ctrl.items.length) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _ctrl.isLoadingMore
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4),
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    }
                    return ContributionTile(
                        contribution: _ctrl.items[i]);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.labelFor,
    required this.ctrl,
  });
  final List<String> filters;
  final String Function(String) labelFor;
  final MyContributionsController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.appBgColor,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final selected = ctrl.filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(labelFor(f)),
                  selected: selected,
                  onSelected: (_) => ctrl.setFilter(f),
                  selectedColor: const Color(0xFFB10F33),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE3D9C2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
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
        const Icon(Icons.receipt_long_outlined,
            size: 56, color: Color(0xFFB18A55)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No contributions yet',
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
              'Once you donate to a cause it will show up here.',
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 14),
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

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (_, __) => Container(
        height: 96,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFE6D2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
