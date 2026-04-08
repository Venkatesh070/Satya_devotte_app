import 'package:dio/dio.dart';
import 'package:satya_devotte_app/config/env/app_env.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';

class ApiClient {
  ApiClient() : dio = Dio(_baseOptions()) {
    dio.interceptors.add(ApiErrorInterceptor());
  }

  final Dio dio;

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      contentType: Headers.jsonContentType,
    );
  }
}
