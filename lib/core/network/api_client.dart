import 'package:dio/dio.dart';
import 'package:satya_devotte_app/config/env/app_env.dart';
import 'package:satya_devotte_app/core/constants/app_constants.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';
import 'package:satya_devotte_app/core/services/api_loading_service.dart';

class ApiClient {
  ApiClient({
    required ApiLoadingService loadingService,
    Future<String?> Function()? tokenProvider,
  }) : dio = Dio(_baseOptions()) {
    dio.interceptors.add(ApiLoadingInterceptor(loadingService));
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
