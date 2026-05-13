// Maps an FCM `RemoteMessage`'s `data` payload to an in-app route.
//
// The backend sends one of these `data.type` values:
//
//   • ADMIN_BROADCAST    — admin push (no user-facing inbox yet → home)
//   • ORDER_PLACED       — devotee order paid (no user orders screen yet → home)
//   • DONATION_RECEIVED  — donation paid → /donations/contributions
//
// New types can be added in the switch without touching the caller.
// Routing happens via GetX so we don't need a `navigatorKey`.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:satya_devotte_app/config/routes/app_routes.dart';

class PushRouter {
  PushRouter._();

  /// Resolves `data.type` to the route the user should land on. Returns
  /// `null` if no navigation should happen (e.g. unknown type and we
  /// prefer to leave the user where they are).
  static String? routeFor(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toUpperCase();
    switch (type) {
      case 'DONATION_RECEIVED':
        return AppRoutes.userContributions;
      case 'ORDER_PLACED':
        // No user-facing Orders screen exists yet — fall back to home so
        // the tap still feels responsive instead of opening nothing.
        return AppRoutes.home;
      case 'ADMIN_BROADCAST':
        // No user-facing inbox is wired yet. Land on home; once an inbox
        // route exists, swap this for it.
        return AppRoutes.home;
      default:
        return null;
    }
  }

  /// Best-effort navigation. Safe to call from any lifecycle state.
  static void navigateFromData(Map<String, dynamic> data) {
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
