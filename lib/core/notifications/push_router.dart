// Maps an FCM `RemoteMessage`'s `data` payload to the user notifications
// screen. All user-facing notification types now open /notifications.
// Admin operational types (NEW_ORDER, PAYMENT_SUCCESS, etc.) are handled
// by [AdminNotificationRouter].
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/notifications/admin_notification_router.dart';

class PushRouter {
  PushRouter._();

  /// Resolves `data.type` to the route the user should land on. Returns
  /// `null` if no navigation should happen.
  static String? routeFor(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toUpperCase();
    switch (type) {
      case 'DONATION_RECEIVED':
      case 'ORDER_PLACED':
      case 'ADMIN_BROADCAST':
        return AppRoutes.notifications;
      default:
        // For unmapped types, still show the notifications page so the
        // user can see the notification in the list.
        return AppRoutes.notifications;
    }
  }

  /// Best-effort navigation. Safe to call from any lifecycle state.
  static void navigateFromData(Map<String, dynamic> data) {
    // Admin operational alerts are handled by [AdminNotificationRouter].
    if (AdminNotificationRouter.isOperationalType(data['type']?.toString())) {
      if (kDebugMode) {
        debugPrint('[push] skipping user route for admin operational type');
      }
      return;
    }
    final route = routeFor(data);
    if (route == null) {
      if (kDebugMode) {
        debugPrint('[push] no route mapped for data=$data');
      }
      return;
    }
    void go() {
      if (Get.currentRoute == route) return;
      try {
        Get.toNamed(route, arguments: data);
      } catch (e) {
        if (kDebugMode) debugPrint('[push] nav to $route failed: $e');
      }
    }

    // Defer one frame so `GetMaterialApp` has attached its navigator after
    // a cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) => go());
  }
}
