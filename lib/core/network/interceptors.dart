import 'package:dio/dio.dart';

class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._tokenProvider);
  final Future<String?> Function() _tokenProvider;

  bool _hasAuthorizationHeader(RequestOptions options) {
    final existingHeader = options.headers.entries.firstWhere(
      (entry) => entry.key.toLowerCase() == 'authorization',
      orElse: () => const MapEntry('', null),
    );
    final value = existingHeader.value;
    return value != null && value.toString().trim().isNotEmpty;
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Keep explicitly set auth headers (e.g. Firebase token on /auth/login).
    if (_hasAuthorizationHeader(options)) {
      handler.next(options);
      return;
    }

    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
