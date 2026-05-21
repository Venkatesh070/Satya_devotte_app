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
  ApiErrorInterceptor(this._dio);

  final Dio _dio;
  static const int _maxRateLimitRetries = 2;

  int _retryCount(RequestOptions options) =>
      (options.extra['rateLimitRetryCount'] as int?) ?? 0;

  bool _canRetry(DioException err) {
    final code = err.response?.statusCode;
    if (code != 429) return false;
    // Retry only idempotent reads to avoid duplicate writes.
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    return _retryCount(err.requestOptions) < _maxRateLimitRetries;
  }

  Duration _retryDelay(DioException err) {
    final retryAfter = err.response?.headers.value('retry-after');
    final seconds = int.tryParse((retryAfter ?? '').trim());
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds);
    }
    final attempt = _retryCount(err.requestOptions);
    return Duration(seconds: attempt + 1);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_canRetry(err)) {
      final options = err.requestOptions;
      final nextRetryCount = _retryCount(options) + 1;
      await Future.delayed(_retryDelay(err));
      try {
        final response = await _dio.request<dynamic>(
          options.path,
          data: options.data,
          queryParameters: options.queryParameters,
          cancelToken: options.cancelToken,
          onReceiveProgress: options.onReceiveProgress,
          onSendProgress: options.onSendProgress,
          options: Options(
            method: options.method,
            headers: Map<String, dynamic>.from(options.headers),
            responseType: options.responseType,
            contentType: options.contentType,
            followRedirects: options.followRedirects,
            receiveDataWhenStatusError: options.receiveDataWhenStatusError,
            validateStatus: options.validateStatus,
            extra: Map<String, dynamic>.from(options.extra)
              ..['rateLimitRetryCount'] = nextRetryCount,
          ),
        );
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        handler.next(e);
        return;
      }
    }
    handler.next(err);
  }
}
