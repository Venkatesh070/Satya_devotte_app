import 'package:dio/dio.dart';
import 'package:satya_devotte_app/config/env/app_env.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';

class ApiClient {
  ApiClient({Future<String?> Function()? tokenProvider})
      : dio = Dio(_baseOptions()) {
    if (tokenProvider != null) {
      dio.interceptors.add(AuthTokenInterceptor(tokenProvider));
    }
    dio.interceptors.add(ApiErrorInterceptor(dio));
  }

  final Dio dio;

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: AppEnv.resolvedApiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      contentType: Headers.jsonContentType,
    );
  }
}
