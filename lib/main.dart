import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satya_devotte_app/app.dart';
import 'package:satya_devotte_app/config/bindings/initial_binding.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';
import 'package:satya_devotte_app/core/services/notification_service.dart';
import 'package:satya_devotte_app/config/env/app_env.dart';
import 'package:satya_devotte_app/config/firebase/firebase_options.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/routing/hash_route_sync.dart';
import 'package:satya_devotte_app/core/url_strategy/url_strategy.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter web defaults to path-based URLs (`/login`). The browser then
  // requests `/login` as a real path; static/dev servers often have no
  // SPA fallback and return 404 ("Failed to load resource: login").
  // Hash strategy keeps routes in the fragment (`/#/login`) so only `/`
  // and asset files are fetched from the server. On native platforms
  // `configureUrlStrategy` resolves to a no-op stub via conditional import.
  configureUrlStrategy();
  if (kIsWeb) {
    // `initialRoute` renders `/login` but hash strategy may leave the URL at
    // `/#/` until the first GetX navigation. Normalise on cold start.
    final fragment = Uri.base.fragment;
    if (fragment.isEmpty || fragment == '/') {
      updateCmsHashRoute(AppRoutes.login);
    }
  }
  await _ensureFirebaseInitialized();
  if (kDebugMode) {
    debugPrint(
      'APP_ENV=${AppEnv.environment} '
      'api=${AppEnv.resolvedApiBaseUrl} '
      'firebase=${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
  }
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.ritualsBox);
  await Hive.openBox(AppConstants.cacheBox);
  await Hive.openBox('sync_queue');

  InitialBinding().dependencies();

  // Initialize notifications.
  final notifs = Get.find<NotificationService>();
  await notifs.initialize();

  runApp(SathyaApp());

  // Web uses login as initial route (no splash page), so handle cold-start
  // taps here. Native platforms do this in SplashPage to avoid a navigation
  // race with the splash->home redirect.
  if (kIsWeb) {
    notifs.handleColdStart();
  }
}

/// Initializes Firebase from Dart using env-specific [DefaultFirebaseOptions].
/// Native auto-init is disabled (Android manifest + iOS Info.plist) to avoid
/// `[core/duplicate-app]` vs `[core/no-app]` races.
Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // Native already configured (e.g. iOS Messaging before Dart init).
  }
}
