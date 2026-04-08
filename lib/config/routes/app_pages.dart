import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/config/routes/route_guard.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/login_page.dart';
import 'package:satya_devotte_app/features/rituals/bindings/ritual_binding.dart';
import 'package:satya_devotte_app/features/rituals/presentation/pages/ritual_detail_page.dart';
import 'package:satya_devotte_app/features/rituals/presentation/pages/ritual_list_page.dart';
import 'package:satya_devotte_app/features/splash/presentation/pages/splash_page.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashPage.new,
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginPage.new,
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
  ];
}
