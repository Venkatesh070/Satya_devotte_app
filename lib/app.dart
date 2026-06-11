import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_pages.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/core/theme/app_theme.dart';
import 'package:satya_devotte_app/shared/widgets/app_music_floating_button.dart';
import 'package:satya_devotte_app/shared/widgets/api_loading_overlay.dart';

import 'package:satya_devotte_app/features/offline/presentation/pages/no_internet_screen.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';

class SathyaApp extends StatelessWidget {
  const SathyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sathya App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: kIsWeb ? AppRoutes.login : AppRoutes.splash,
      getPages: AppPages.pages,
      routingCallback: (routing) {
        if (Get.isRegistered<AppMusicService>()) {
          Get.find<AppMusicService>().syncControlsVisibility(routing?.current);
        }
      },
      builder: (context, child) {
        if (kIsWeb || child == null) return child ?? const SizedBox.shrink();
        return Stack(
          children: [
            ApiLoadingOverlay(
              child: Stack(
                fit: StackFit.expand,
                children: [child, const AppMusicFloatingButton()],
              ),
            ),
            Obx(() {
              final offlineService = Get.find<OfflineService>();
              final showNoInternet = offlineService.showNoInternetScreen.value;

              if (showNoInternet) {
                // Check if current route is offline-supported
                final currentRoute = Get.currentRoute;
                final offlineSupportedRoutes = [
                  AppRoutes.home,
                  AppRoutes.rituals,
                  AppRoutes.ritualDetail,
                  AppRoutes.poojaHistory,
                  AppRoutes.poojaWizard,
                  AppRoutes.splash, // Usually okay to keep splash
                ];

                // REQ: We don't want to show the full screen overlay anymore
                // for these routes, and for other routes we might prefer a dialog.
                // Keeping it only as a fallback for truly unsupported routes if needed.
                if (offlineSupportedRoutes.contains(currentRoute)) {
                  return const SizedBox.shrink();
                }

                return const NoInternetScreen();
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }
}
