import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/deity_model.dart';

class DeityRemoteDataSource {
  DeityRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<List<DeityModel>> getDeities({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.allDeities,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final raw = response.data;
    List<dynamic> list = const [];
    if (raw is Map<String, dynamic>) {
      final d = raw['data'];
      if (d is List) list = d;
      if (d is Map && d['deities'] is List) list = d['deities'] as List;
      if (list.isEmpty && raw['deities'] is List) list = raw['deities'] as List;
    } else if (raw is List) {
      list = raw;
    }
    return list
        .whereType<Map>()
        .map((e) => DeityModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createDeity(Map<String, dynamic> payload) async {
    await _apiClient.dio.post(ApiEndpoints.createDeity, data: payload);
  }

  Future<void> updateDeity(String id, Map<String, dynamic> payload) async {
    await _apiClient.dio.patch(ApiEndpoints.updateDeity(id), data: payload);
  }

  Future<void> deleteDeity(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.deleteDeity(id));
  }

  Future<void> reviewDeity(String id, String status) async {
    await _apiClient.dio.put(
      ApiEndpoints.reviewDeity(id),
      data: {'status': status},
    );
  }

  Future<void> approveDeity(String id) async {
    await reviewDeity(id, 'APPROVED');
  }

  Future<void> rejectDeity(String id) async {
    await reviewDeity(id, 'REJECTED');
  }
}
