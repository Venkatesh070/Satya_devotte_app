import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satya_devotte_app/app.dart';
import 'package:satya_devotte_app/config/bindings/initial_binding.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';
import 'package:satya_devotte_app/core/services/notification_service.dart';
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
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA-eEji6_kLAAN8nw6I-SuiYRfa84B58dU",
        authDomain: "satya-devotte-app.firebaseapp.com",
        projectId: "satya-devotte-app",
        storageBucket: "satya-devotte-app.firebasestorage.app",
        messagingSenderId: "1053803605697",
        appId: "1:1053803605697:web:b3cddc97158a26852a6e40",
        measurementId: "G-18Z1BB36SF",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.ritualsBox);
  await Hive.openBox(AppConstants.cacheBox);
  await Hive.openBox('sync_queue');

  InitialBinding().dependencies();

  // Initialize notifications.
  final notifs = Get.find<NotificationService>();
  await notifs.initialize();

  runApp(const SathyaApp());

  // Handle cold-start taps AFTER `runApp` so GetX routing is ready to
  // accept `Get.toNamed`. Fire-and-forget; failures are logged inside.
  notifs.handleColdStart();
}
