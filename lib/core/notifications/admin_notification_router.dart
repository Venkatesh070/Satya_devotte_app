// Routes admin operational FCM payloads (orders, donations, refunds).
//
// Foreground: refresh Activity inbox + badge only — no navigation.
// Tap / cold-start: mark read (when id present) and deep-link in CMS shell.
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/core/notifications/notification_alert_sound.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/models/admin_notification_item.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/controllers/cms_admin_notifications_controller.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';

class AdminNotificationRouter {
  AdminNotificationRouter._();

  static const operationalTypes = <String>{
    'NEW_ORDER',
    'PAYMENT_SUCCESS',
    'REFUND_REQUEST',
    'REPLACEMENT_REQUEST',
  };

  static bool isOperationalType(String? type) =>
      operationalTypes.contains((type ?? '').toString().toUpperCase());

  static bool get _isAdminSession {
    if (!Get.isRegistered<AuthController>()) return false;
    return Get.find<AuthController>().isAdmin;
  }

  /// Returns `true` when the message was handled (admin operational type).
  static bool tryHandleData(
    Map<String, dynamic> data, {
    required bool fromTap,
    RemoteMessage? message,
  }) {
    if (!_isAdminSession) return false;
    if (!isOperationalType(data['type']?.toString())) return false;

    final item = fromFcmData(data, message: message);

    if (!fromTap) {
      _refreshActivityInbox();
      unawaited(
        playAdminNotificationAlert(
          title: item.title,
          body: item.body,
        ),
      );
      if (kDebugMode) {
        debugPrint('[admin-fcm] foreground ${item.type} — inbox refreshed');
      }
      return true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openFromTap(item));
    });
    return true;
  }

  static AdminNotificationItem fromFcmData(
    Map<String, dynamic> data, {
    RemoteMessage? message,
  }) {
    final notif = message?.notification;
    final id =
        (data['notificationId'] ?? data['id'] ?? message?.messageId ?? '')
            .toString()
            .trim();
    return AdminNotificationItem(
      id: id.isEmpty
          ? 'fcm-${message?.messageId ?? DateTime.now().millisecondsSinceEpoch}'
          : id,
      type: (data['type'] ?? '').toString(),
      title: (notif?.title ?? data['title'] ?? 'Notification').toString(),
      body: (notif?.body ?? data['body'] ?? '').toString(),
      data: data.map((k, v) => MapEntry(k.toString(), v)),
      read: false,
      createdAt: DateTime.now().toUtc(),
    );
  }

  static void _refreshActivityInbox() {
    if (!Get.isRegistered<CmsAdminNotificationsController>()) return;
    final ctrl = Get.find<CmsAdminNotificationsController>();
    unawaited(ctrl.refreshUnreadCount());
    unawaited(ctrl.loadFirstPage());
  }

  static Future<void> _openFromTap(AdminNotificationItem item) async {
    if (Get.isRegistered<CmsAdminNotificationsController>()) {
      await Get.find<CmsAdminNotificationsController>().markReadAndOpen(item);
      return;
    }
    CmsShellNavigation.openFromNotification(item);
  }
}
