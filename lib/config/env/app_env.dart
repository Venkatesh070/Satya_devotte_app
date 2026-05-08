class AppEnv {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _productionApiBaseUrl =
      'https://satya-server-app-2.onrender.com';

  // Android emulator reaches host machine via 10.0.2.2.
  static String get resolvedApiBaseUrl => apiBaseUrl.isNotEmpty
      ? apiBaseUrl
      : (isProduction
            ? _productionApiBaseUrl
            : 'https://satya-server-app-2.onrender.com');

  static bool get isProduction => environment == 'prod';
}
