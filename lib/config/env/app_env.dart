class AppEnv {
  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static bool get isProduction => environment == 'prod';
}
