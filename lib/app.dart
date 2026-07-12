import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_pages.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/routing/hash_route_sync.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/core/theme/app_theme.dart';
import 'package:satya_devotte_app/shared/widgets/app_music_floating_button.dart';
import 'package:satya_devotte_app/shared/widgets/api_loading_overlay.dart';

import 'package:satya_devotte_app/features/offline/presentation/pages/no_internet_screen.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';

class _DialogObserver extends NavigatorObserver {
  final RxBool hasActiveDialog = RxBool(false);
  final List<Route> _routeStack = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    _routeStack.add(route);
    _updateHasActiveDialog();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _routeStack.remove(route);
    _updateHasActiveDialog();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _routeStack.remove(route);
    _updateHasActiveDialog();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute != null) _routeStack.remove(oldRoute);
    if (newRoute != null) _routeStack.add(newRoute);
    _updateHasActiveDialog();
  }

  void _updateHasActiveDialog() {
    // Check if there are any modal routes that are not the first route (dialogs/pickers)
    final hasModal = _routeStack.any(
      (route) =>
          !route.isFirst &&
          route is ModalRoute &&
          route.overlayEntries.isNotEmpty,
    );
    hasActiveDialog.value = hasModal;
  }
}

class SathyaApp extends StatelessWidget {
  SathyaApp({super.key});
  final _dialogObserver = _DialogObserver();
  static bool _imagesPrecached = false;

  void _precacheChakraImages(BuildContext context) {
    if (_imagesPrecached) return;
    _imagesPrecached = true;
    precacheImage(const AssetImage('assets/images/chakra1.png'), context);
    precacheImage(const AssetImage('assets/images/chakra2.png'), context);
    precacheImage(const AssetImage('assets/images/chakra3.png'), context);
    precacheImage(const AssetImage('assets/images/chakra4.png'), context);
    precacheImage(const AssetImage('assets/images/onBoardBgOverlay.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sathya App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: kIsWeb ? AppRoutes.login : AppRoutes.splash,
      getPages: AppPages.pages,
      navigatorObservers: [_dialogObserver],
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en'),
      ],
      routingCallback: (routing) {
        if (kIsWeb) {
          final current = routing?.current?.trim();
          if (current != null && current.isNotEmpty) {
            updateCmsHashRoute(current);
          }
        }
        if (Get.isRegistered<AppMusicService>()) {
          Get.find<AppMusicService>().syncControlsVisibility(routing?.current);
        }
      },
      builder: (context, child) {
        _precacheChakraImages(context);
        if (kIsWeb || child == null) return child ?? const SizedBox.shrink();
        return Stack(
          children: [
            ApiLoadingOverlay(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  Obx(() {
                    // Hide FAB if there's an active dialog/picker
                    if (_dialogObserver.hasActiveDialog.value)
                      return const SizedBox.shrink();
                    return const AppMusicFloatingButton();
                  }),
                ],
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
