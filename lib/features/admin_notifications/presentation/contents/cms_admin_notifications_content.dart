import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:satya_devotte_app/features/admin_notifications/data/models/admin_notification_item.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/controllers/cms_admin_notifications_controller.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/widgets/admin_notification_detail_sheet.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

/// CMS Activity inbox — operational alerts (orders, donations, refunds).
class CmsAdminNotificationsContent extends StatefulWidget {
  const CmsAdminNotificationsContent({super.key});

  @override
  State<CmsAdminNotificationsContent> createState() =>
      _CmsAdminNotificationsContentState();
}

class _CmsAdminNotificationsContentState
    extends State<CmsAdminNotificationsContent> {
  static const Color _navy = Color(0xFF1A2A4A);

  late final CmsAdminNotificationsController _ctrl;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<CmsAdminNotificationsController>();
    _scrollController.addListener(_onScroll);
    if (_ctrl.items.isEmpty && !_ctrl.isLoading.value) {
      Future.microtask(_ctrl.loadFirstPage);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max - 200) {
      _ctrl.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return RefreshIndicator(
        onRefresh: () async {
          await _ctrl.loadFirstPage();
          await _ctrl.refreshUnreadCount();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (_ctrl.isLoading.value && _ctrl.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_ctrl.error.value != null && _ctrl.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  message: _ctrl.error.value!,
                  onRetry: _ctrl.loadFirstPage,
                ),
              )
            else if (_ctrl.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _ctrl.items.length) {
                      return _ctrl.isLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    final item = _ctrl.items[index];
                    return _NotificationTile(
                      item: item,
                      onTap: () => _ctrl.markReadAndOpen(item),
                      onLongPress: () =>
                          AdminNotificationDetailSheet.show(context, item),
                    );
                  },
                  childCount: _ctrl.items.length +
                      (_ctrl.isLoadingMore.value ? 1 : 0),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Activity Alerts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
          ),
          Obx(() {
            if (_ctrl.isMarkingAll.value) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return TextButton(
              onPressed: _ctrl.unreadCount.value > 0
                  ? _ctrl.markAllRead
                  : null,
              child: const Text('Mark all read'),
            );
          }),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              await _ctrl.loadFirstPage();
              await _ctrl.refreshUnreadCount();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const chips = <(ActivityInboxFilter, String)>[
      (ActivityInboxFilter.all, 'All'),
      (ActivityInboxFilter.unread, 'Unread'),
      (ActivityInboxFilter.orders, 'Orders'),
      (ActivityInboxFilter.donations, 'Donations'),
      (ActivityInboxFilter.refunds, 'Refunds'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Obx(() {
        final selected = _ctrl.filter.value;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((c) {
            final isSelected = selected == c.$1;
            return FilterChip(
              label: Text(c.$2),
              selected: isSelected,
              onSelected: (_) => _ctrl.setFilter(c.$1),
              selectedColor: CmsColors.orange.withOpacity(0.2),
              checkmarkColor: CmsColors.orangeDark,
            );
          }).toList(),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  final AdminNotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final rel = _relativeTime(item.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CmsColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!item.read)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: const BoxDecoration(
                      color: CmsColors.orange,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 18),
                Icon(_iconForType(item.type), size: 22, color: _iconColor(item.type)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              item.read ? FontWeight.w500 : FontWeight.w700,
                          color: const Color(0xFF1A2A4A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt.toLocal());
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'NEW_ORDER':
        return Icons.receipt_long_outlined;
      case 'PAYMENT_SUCCESS':
        return Icons.volunteer_activism_outlined;
      case 'REFUND_REQUEST':
        return Icons.money_off_outlined;
      case 'REPLACEMENT_REQUEST':
        return Icons.assignment_return_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _iconColor(String type) {
    switch (type) {
      case 'NEW_ORDER':
        return CmsColors.orange;
      case 'PAYMENT_SUCCESS':
        return CmsColors.green;
      case 'REFUND_REQUEST':
      case 'REPLACEMENT_REQUEST':
        return CmsColors.red;
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            'No activity yet',
            style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
          ),
          SizedBox(height: 4),
          Text(
            'New orders, donations, and refund requests will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: CmsColors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
