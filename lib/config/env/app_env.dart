class AppEnv {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Web Push VAPID **public** key (Firebase Console → Cloud Messaging →
  /// Web configuration → Key pair). Usually ~88 chars, often starts with `B`.
  /// Pass at run/build: `--dart-define=FIREBASE_VAPID_KEY=<full public key>`
  static const String firebaseVapidKey = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
    defaultValue:
        'BAQl5XzrLFPnWDA9nuf2a2KG6IM2wYaEcQrqMpj4CiELt_RtaHXyKj1KKy-08CzZymNY-fCaEIIHfF05cPx3Pis',
  );

  /// Rough sanity check — invalid keys cause PushManager subscribe errors.
  static bool get hasPlausibleFirebaseVapidKey {
    final k = firebaseVapidKey.trim();
    return k.length >= 80 && !k.contains(' ');
  }
  static const String _productionApiBaseUrl =
      'https://satya-server-app-2.onrender.com';
  static const String _testApiBaseUrl = 'http://18.209.102.86';
  static const String _uatApiBaseUrl = 'https://satya-server-app.onrender.com';

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
}
