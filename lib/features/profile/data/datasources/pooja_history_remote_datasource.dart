import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';

class PoojaHistoryRemoteDataSource {
  PoojaHistoryRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getPoojaHistory({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    };

    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.userPoojaHistory,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPendingPoojas({int page = 1, int limit = 20}) async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.userPoojaHistoryPending,
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFinishedPoojas({int page = 1, int limit = 20}) async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.userPoojaHistoryFinished,
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startPooja(String poojaId) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.startUserPooja(poojaId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateProgress(String sessionId, int currentStep) async {
    await _apiClient.dio.patch<dynamic>(
      ApiEndpoints.updatePoojaProgress(sessionId),
      data: {'currentStep': currentStep},
    );
  }

  Future<void> finishPooja(String poojaId) async {
    await _apiClient.dio.post<dynamic>(
      ApiEndpoints.finishUserPooja(poojaId),
    );
  }

  Future<void> finishPoojaBySession(String sessionId) async {
    await _apiClient.dio.post<dynamic>(
      ApiEndpoints.finishPoojaBySession(sessionId),
    );
  }
}
