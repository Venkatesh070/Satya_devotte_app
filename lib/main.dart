// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satya_devotte_app/app.dart';
import 'package:satya_devotte_app/config/bindings/initial_binding.dart';
// import 'package:satya_devotte_app/config/firebase/firebase_options.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.ritualsBox);
  await Hive.openBox(AppConstants.cacheBox);
  InitialBinding().dependencies();
  runApp(const SathyaApp());
}
