class AppEnv {
  /// Switch environment by editing [config/app_env.json] (`APP_ENV`: `prod`|`test`|`uat`).
  /// Cursor/VS Code picks it up via `dart.flutterRunAdditionalArgs` in `.vscode/settings.json`.
  /// CLI: `flutter run --dart-define-from-file=config/app_env.json`
  /// Keep [config/app_env.default] in sync for native-only builds without dart-defines.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'test',
  );
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _testFirebaseVapidKey =
      'BAQl5XzrLFPnWDA9nuf2a2KG6IM2wYaEcQrqMpj4CiELt_RtaHXyKj1KKy-08CzZymNY-fCaEIIHfF05cPx3Pis';
  static const String _prodFirebaseVapidKey =
      'BJL_cbHU5oarw58Cl5wsUFtWD_38YRJmoF2CxSRFNxx36ntfXPbD3GHCHqe_lBWp48Nr95-DKquJPUkkhDNYotI';

  /// Web Push VAPID **public** key (Firebase Console → Cloud Messaging →
  /// Web configuration → Key pair). Usually ~88 chars, often starts with `B`.
  /// Pass at run/build: `--dart-define=FIREBASE_VAPID_KEY=<full public key>`
  static const String firebaseVapidKey = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
    defaultValue: environment == 'prod'
        ? _prodFirebaseVapidKey
        : _testFirebaseVapidKey,
  );

  /// Rough sanity check — invalid keys cause PushManager subscribe errors.
  static bool get hasPlausibleFirebaseVapidKey {
    final k = firebaseVapidKey.trim();
    return k.length >= 80 && !k.contains(' ');
  }

  static const String _productionApiBaseUrl = 'https://api.sathya.co.za';
  static const String _testApiBaseUrl = 'https://api-test.sathya.co.za';
  static const String _uatApiBaseUrl =
      'https://satya-server-app-snqq.onrender.com';

  // Android emulator reaches host machine via 10.0.2.2.
  static String get resolvedApiBaseUrl => apiBaseUrl.isNotEmpty
      ? apiBaseUrl
      : (isProduction
            ? _productionApiBaseUrl
            : isUat
            ? _uatApiBaseUrl
            : _testApiBaseUrl);

  static bool get isProduction => environment == 'prod';
  static bool get isTest => environment == 'test';
  static bool get isUat => environment == 'uat';

  /// Google Sign-In web OAuth client (Firebase Console → Authentication → Google).
  /// `prod` → `sathyatest-4b2b1`; `test` / `uat` → `satya-devotte-app`.
  /// Android: Gradle copies `google-services.prod.json` or
  /// `google-services(test).json` → `google-services.json` using the same
  /// `APP_ENV` dart-define before each build.
  /// iOS: Xcode run script copies `GoogleService-Info.prod.plist` or
  /// `GoogleService-Info(test).plist` → `Runner/GoogleService-Info.plist`.
  /// Override: `--dart-define=GOOGLE_WEB_CLIENT_ID=<client id>`
  static const String _testWebGoogleClientId =
      '1053803605697-a4fp6shgdolcbrmag6iteadjaf1du6ug.apps.googleusercontent.com';
  static const String _prodWebGoogleClientId =
      '460042314237-bofm6ss9p4jur0vko6mqfujupdrrl6aa.apps.googleusercontent.com';

  /// Web OAuth client id (Flutter web Google Sign-In popup).
  static const String googleWebClientId = environment == 'prod'
      ? _prodWebGoogleClientId
      : _testWebGoogleClientId;

  /// Firebase Auth on Android — web client id from the same Firebase project.
  static const String androidGoogleServerClientId = googleWebClientId;
}
