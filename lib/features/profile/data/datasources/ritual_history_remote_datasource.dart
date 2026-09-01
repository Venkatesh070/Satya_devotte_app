import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';

class RitualHistoryRemoteDataSource {
  RitualHistoryRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getRitualHistory({
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.userRitualHistory,
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.userRitualSession(sessionId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startRitual(String ritualId) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.startUserRitual(ritualId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startDay(String sessionId) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.startRitualDay(sessionId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateProgress(
    String sessionId, {
    required int currentStep,
    int? currentDay,
  }) async {
    await _apiClient.dio.patch<dynamic>(
      ApiEndpoints.updateRitualProgress(sessionId),
      data: {
        'currentStep': currentStep,
        if (currentDay != null) 'currentDay': currentDay,
      },
    );
  }

  Future<Map<String, dynamic>> completeDay(String sessionId) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.completeRitualDay(sessionId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> finishRitual(String ritualId) async {
    await _apiClient.dio.post<dynamic>(
      ApiEndpoints.finishUserRitual(ritualId),
    );
  }

  Future<void> finishRitualBySession(String sessionId) async {
    await _apiClient.dio.post<dynamic>(
      ApiEndpoints.finishRitualBySession(sessionId),
    );
  }
}
