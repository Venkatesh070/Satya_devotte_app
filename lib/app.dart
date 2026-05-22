import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_pages.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/core/theme/app_theme.dart';
import 'package:satya_devotte_app/shared/widgets/app_music_floating_button.dart';
import 'package:satya_devotte_app/shared/widgets/api_loading_overlay.dart';

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
          fit: StackFit.expand,
          children: [
            child,
            const AppMusicFloatingButton(),
          ],
        );
      },
    );
  }
}
