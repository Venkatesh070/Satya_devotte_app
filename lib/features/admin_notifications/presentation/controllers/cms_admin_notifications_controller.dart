import 'dart:async';

import 'package:get/get.dart';

import 'package:satya_devotte_app/core/notifications/notification_alert_sound.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/admin_notifications_api.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/admin_notifications_exception.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/admin_notifications_repository.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/models/admin_notification_item.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

/// Inbox filter chips for the Activity tab.
enum ActivityInboxFilter {
  all,
  unread,
  orders,
  donations,
  refunds,
}

class CmsAdminNotificationsController extends GetxController {
  CmsAdminNotificationsController(this._repo);
  final AdminNotificationsRepository _repo;

  static const _pageSize = 20;

  final notifications = <AdminNotificationItem>[].obs;
  final unreadCount = 0.obs;
  final page = 1.obs;
  final totalPages = 1.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isMarkingAll = false.obs;
  final error = RxnString();

  final filter = ActivityInboxFilter.all.obs;

  /// Increments when [unreadCount] rises — drives bell badge pulse in the shell.
  final badgePulseTick = 0.obs;

  bool get hasMore => page.value < totalPages.value;

  List<AdminNotificationItem> get items => notifications;

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshUnreadCount());
  }

  Future<void> refreshUnreadCount() async {
    try {
      final next = await _repo.unreadCount();
      _applyUnreadCount(next);
    } catch (_) {
      // Badge refresh is best-effort; do not surface errors in the header.
    }
  }

  void _applyUnreadCount(int next) {
    final prev = unreadCount.value;
    if (next > prev) {
      badgePulseTick.value++;
      // Polling only — skip initial load (0 → N); FCM foreground plays via router.
      if (prev > 0) {
        unawaited(playAdminNotificationAlert());
      }
    }
    unreadCount.value = next;
  }

  Future<void> loadFirstPage() async {
    page.value = 1;
    totalPages.value = 1;
    isLoading.value = true;
    error.value = null;
    notifications.clear();
    try {
      final result = await _fetchPage(1);
      notifications.assignAll(result.items);
      page.value = result.page;
      totalPages.value = result.totalPages;
      if (result.unreadCount != null) {
        _applyUnreadCount(result.unreadCount!);
      }
    } on AdminNotificationsException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final next = page.value + 1;
      final result = await _fetchPage(next);
      notifications.addAll(result.items);
      page.value = result.page;
      totalPages.value = result.totalPages;
      if (result.unreadCount != null) {
        _applyUnreadCount(result.unreadCount!);
      }
    } on AdminNotificationsException catch (e) {
      showCmsSnackbar(title: 'Activity', message: e.message, isError: true);
    } catch (e) {
      showCmsSnackbar(title: 'Activity', message: e.toString(), isError: true);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setFilter(ActivityInboxFilter value) {
    if (filter.value == value) return;
    filter.value = value;
    unawaited(loadFirstPage());
  }

  Future<void> markAllRead() async {
    if (isMarkingAll.value) return;
    isMarkingAll.value = true;
    try {
      await _repo.markAllRead();
      unreadCount.value = 0;
      notifications.assignAll(
        notifications.map((n) => n.copyWith(read: true)).toList(),
      );
      showCmsSnackbar(
        title: 'Activity',
        message: 'All notifications marked as read.',
      );
    } on AdminNotificationsException catch (e) {
      showCmsSnackbar(title: 'Activity', message: e.message, isError: true);
    } catch (e) {
      showCmsSnackbar(title: 'Activity', message: e.toString(), isError: true);
    } finally {
      isMarkingAll.value = false;
    }
  }

  Future<void> markReadAndOpen(AdminNotificationItem item) async {
    if (!item.read) {
      try {
        await _repo.markRead(item.id);
        final idx = notifications.indexWhere((n) => n.id == item.id);
        if (idx >= 0) {
          notifications[idx] = item.copyWith(read: true);
        }
        if (unreadCount.value > 0) unreadCount.value--;
      } on AdminNotificationsException catch (e) {
        showCmsSnackbar(title: 'Activity', message: e.message, isError: true);
      }
    }
    CmsShellNavigation.openFromNotification(item);
  }

  Future<AdminNotificationsPage> _fetchPage(int pageNum) =>
      _repo.list(
        page: pageNum,
        limit: _pageSize,
        unreadOnly: filter.value == ActivityInboxFilter.unread,
        type: _apiTypeForFilter(filter.value),
      );

  String? _apiTypeForFilter(ActivityInboxFilter f) {
    switch (f) {
      case ActivityInboxFilter.orders:
        return 'NEW_ORDER';
      case ActivityInboxFilter.donations:
        return 'PAYMENT_SUCCESS';
      case ActivityInboxFilter.refunds:
        return 'REFUND_REQUEST';
      case ActivityInboxFilter.all:
      case ActivityInboxFilter.unread:
        return null;
    }
  }

}
