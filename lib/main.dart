import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satya_devotte_app/app.dart';
import 'package:satya_devotte_app/config/bindings/initial_binding.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.ritualsBox);
  await Hive.openBox(AppConstants.cacheBox);
  InitialBinding().dependencies();
  runApp(const SathyaApp());
}
