import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/utils/shop_region_access.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';

/// Blocks Shop / Pooja Kit ecommerce when GPS is not in South Africa.
class ShopRegionGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!ShopRegionAccess.available) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}

/// Blocks unauthenticated users — redirects to login.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// Blocks regular users from CMS — admin and superadmin only.
class AdminGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (!auth.isAdmin) {
      // Regular user — send to app home
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}

/// Blocks admin — superadmin only pages.
class SuperAdminGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (!auth.isSuperAdmin) {
      // Admin but not superadmin — send to CMS home
      return const RouteSettings(name: AppRoutes.cms);
    }
    return null;
  }
}
