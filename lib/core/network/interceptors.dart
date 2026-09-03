import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:satya_devotte_app/core/network/device_timezone.dart';
import 'package:satya_devotte_app/core/services/api_loading_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';

/// Set on [RequestOptions.extra] to skip the global chakra loader for a call.
const String kSkipApiLoaderKey = 'skipApiLoader';

class TimezoneInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final timezone = await deviceIanaTimeZone();
    options.headers['X-Timezone'] = timezone;
    if (options.path.contains('user-home')) {
      options.queryParameters['timezone'] = timezone;
    }

    handler.next(options);
  }
}

class ApiLoadingInterceptor extends Interceptor {
  ApiLoadingInterceptor(this._loadingService);

  final ApiLoadingService _loadingService;

  bool _shouldSkip(RequestOptions options) {
    if (options.extra['showGlobalLoader'] == true) return false;
    if (options.extra[kSkipApiLoaderKey] == true) return true;
    // GET requests (queries / background fetches) should never show the full-screen
    // blocking chakra loader overlay over pages that already have loaded data.
    if (options.method.toUpperCase() == 'GET') return true;
    return false;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!_shouldSkip(options)) {
      _loadingService.onRequestStarted();
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_shouldSkip(response.requestOptions)) {
      _loadingService.onRequestFinished();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_shouldSkip(err.requestOptions)) {
      _loadingService.onRequestFinished();
    }
    handler.next(err);
  }
}

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
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path.toLowerCase();

    // Auto-logout user if server returns 401 Unauthorized on protected calls
    if (statusCode == 401 &&
        !path.contains('/login') &&
        !path.contains('/register') &&
        !path.contains('/auth/firebase-login')) {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isAuthenticated) {
          debugPrint(
            'ApiErrorInterceptor: 401 Unauthorized received on $path. Triggering automatic logout.',
          );
          Future.microtask(() {
            authController.handleExpiredToken(
              reason: 'Your session has expired. Please sign in again.',
            );
          });
        }
      }
    }

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
