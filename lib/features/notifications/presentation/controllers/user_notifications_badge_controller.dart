import 'dart:async';

import 'package:get/get.dart';
import 'package:satya_devotte_app/features/notifications/data/user_notifications_repository.dart';

class UserNotificationsBadgeController extends GetxController {
  UserNotificationsBadgeController(this._repo);
  final UserNotificationsRepository _repo;

  final hasUnread = false.obs;

  Future<void> refreshUnreadBadge() async {
    try {
      final page = await _repo.list(page: 1, limit: 1);
      if (page.unreadCount != null) {
        hasUnread.value = page.unreadCount! > 0;
      } else {
        hasUnread.value = page.items.any((n) => !n.read);
      }
    } catch (_) {
      // Badge refresh is best-effort.
    }
  }

  void clearBadge() {
    hasUnread.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshUnreadBadge());
  }
}
