class AppEnv {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'test',
  );
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
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
