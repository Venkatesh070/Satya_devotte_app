import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:satya_devotte_app/config/env/app_env.dart';

/// Firebase config selected at compile time via `--dart-define=APP_ENV=...`
/// (must match [config/app_env.default] when APP_ENV is not passed).
class DefaultFirebaseOptions {
  static const FirebaseOptions test = FirebaseOptions(
    apiKey: 'AIzaSyA-eEji6_kLAAN8nw6I-SuiYRfa84B58dU',
    authDomain: 'satya-devotte-app.firebaseapp.com',
    projectId: 'satya-devotte-app',
    storageBucket: 'satya-devotte-app.firebasestorage.app',
    messagingSenderId: '1053803605697',
    appId: '1:1053803605697:web:b3cddc97158a26852a6e40',
    measurementId: 'G-18Z1BB36SF',
  );

  static const FirebaseOptions testAndroid = FirebaseOptions(
    apiKey: 'AIzaSyCNHVrp9X3h6g4qFoOuNFWnyWvnOdcZu6U',
    authDomain: 'satya-devotte-app.firebaseapp.com',
    projectId: 'satya-devotte-app',
    storageBucket: 'satya-devotte-app.firebasestorage.app',
    messagingSenderId: '1053803605697',
    appId: '1:1053803605697:android:d5a06b41628f6c282a6e40',
  );

  static const FirebaseOptions testIos = FirebaseOptions(
    apiKey: 'AIzaSyBOXwi8rDmeDc0OhUxuvjOFqSWnsdzeh34',
    authDomain: 'satya-devotte-app.firebaseapp.com',
    projectId: 'satya-devotte-app',
    storageBucket: 'satya-devotte-app.firebasestorage.app',
    messagingSenderId: '1053803605697',
    appId: '1:1053803605697:ios:564a9932a15f0c9a2a6e40',
    iosBundleId: 'com.sathyaApp',
  );

  static const FirebaseOptions prod = FirebaseOptions(
    apiKey: 'AIzaSyBKd3xfIGpsxSUhsoNwPf5O3D4HQEc0QCs',
    authDomain: 'sathyatest-4b2b1.firebaseapp.com',
    projectId: 'sathyatest-4b2b1',
    storageBucket: 'sathyatest-4b2b1.firebasestorage.app',
    messagingSenderId: '460042314237',
    appId: '1:460042314237:android:2dfce106f585b513847994',
  );

  static const FirebaseOptions prodAndroid = FirebaseOptions(
    apiKey: 'AIzaSyBKd3xfIGpsxSUhsoNwPf5O3D4HQEc0QCs',
    authDomain: 'sathyatest-4b2b1.firebaseapp.com',
    projectId: 'sathyatest-4b2b1',
    storageBucket: 'sathyatest-4b2b1.firebasestorage.app',
    messagingSenderId: '460042314237',
    appId: '1:460042314237:android:2dfce106f585b513847994',
  );

  static const FirebaseOptions prodIos = FirebaseOptions(
    apiKey: 'AIzaSyBV-UG1q4LkNW4MT-w5XER5hgIChVr6C3w',
    authDomain: 'sathyatest-4b2b1.firebaseapp.com',
    projectId: 'sathyatest-4b2b1',
    storageBucket: 'sathyatest-4b2b1.firebasestorage.app',
    messagingSenderId: '460042314237',
    appId: '1:460042314237:ios:9af2f73207cf26e5847994',
    iosBundleId: 'com.sathyaApp',
  );

  static bool get _isProd => AppEnv.environment == 'prod';

  static FirebaseOptions get web => _isProd ? prod : test;

  static FirebaseOptions get android => _isProd ? prodAndroid : testAndroid;

  static FirebaseOptions get ios => _isProd ? prodIos : testIos;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }
}
