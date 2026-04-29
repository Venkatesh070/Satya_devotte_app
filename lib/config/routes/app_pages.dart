import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/config/routes/route_guard.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/login_page.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/web_login_page.dart';
import 'package:satya_devotte_app/features/cms/presentation/pages/cms_shell_page.dart';
import 'package:satya_devotte_app/features/home/presentation/pages/bottom_tab_page.dart';
import 'package:satya_devotte_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:satya_devotte_app/features/rituals/bindings/ritual_binding.dart';
import 'package:satya_devotte_app/features/rituals/presentation/pages/ritual_detail_page.dart';
import 'package:satya_devotte_app/features/rituals/presentation/pages/ritual_list_page.dart';
import 'package:satya_devotte_app/features/splash/presentation/pages/splash_page.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    // ─── App flow ───────────────────────────────────────────────
    GetPage(name: AppRoutes.splash, page: SplashPage.new),
    GetPage(name: AppRoutes.onboarding, page: OnboardingPage.new),
    GetPage(name: AppRoutes.login, page: () => kIsWeb ? const WebLoginPage() : const LoginPage()),
    GetPage(
      name: AppRoutes.home,
      page: BottomTabPage.new,
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.rituals,
      page: RitualListPage.new,
      binding: RitualBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.ritualDetail,
      page: RitualDetailPage.new,
      binding: RitualBinding(),
      middlewares: [AuthGuard()],
    ),

    // ─── CMS (admin + superadmin) ───────────────────────────────
    GetPage(
      name: AppRoutes.cms,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsDeities,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsRituals,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsRitualCreate,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsRitualEdit,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsFestivals,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsUsers,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsNotifications,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsAnalytics,
      page: CmsShellPage.new,
      middlewares: [AdminGuard()],
    ),

    // ─── Super Admin only ───────────────────────────────────────
    GetPage(
      name: AppRoutes.cmsApproval,
      page: CmsShellPage.new,
      middlewares: [SuperAdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsAdmins,
      page: CmsShellPage.new,
      middlewares: [SuperAdminGuard()],
    ),
    GetPage(
      name: AppRoutes.cmsShlokas,
      page: CmsShellPage.new,
      middlewares: [SuperAdminGuard()],
    ),
  ];
}
