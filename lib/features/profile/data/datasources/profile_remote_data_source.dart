import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.dio.get<dynamic>(ApiEndpoints.profile);
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Profile API failed with status ${response.statusCode}.',
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'data': data};
  }
}
