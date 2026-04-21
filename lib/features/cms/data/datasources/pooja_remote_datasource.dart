import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';

class PoojaRemoteDataSource {
  PoojaRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  // ── GET all poojas (optional filter by status / deity) ───────
  Future<List<PoojaModel>> getAllPoojas({
    String? status, // 'Published' | 'Draft' | 'Pending'
    String? deity,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/v1/poojas',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (deity != null && deity.isNotEmpty) 'deity': deity,
        'page': page,
        'limit': limit,
      },
    );

    final body = response.data as Map<String, dynamic>;
    final list = _extractList(body);
    return list
        .map((e) => PoojaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET single pooja ─────────────────────────────────────────
  Future<PoojaModel> getPoojaById(String id) async {
    final response = await _apiClient.dio.get('/api/v1/poojas/$id');
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── CREATE pooja ─────────────────────────────────────────────
  Future<PoojaModel> createPooja(PoojaModel pooja) async {
    final response = await _apiClient.dio.post(
      '/api/v1/poojas/create-pooja',
      data: pooja.toJson(),
    );
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── UPDATE pooja (PATCH — matches Swagger) ───────────────────
  Future<PoojaModel> updatePooja(String id, PoojaModel pooja) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/poojas/$id',
      data: pooja.toJson(),
    );
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── DELETE pooja ─────────────────────────────────────────────
  Future<void> deletePooja(String id) async {
    await _apiClient.dio.delete('/api/v1/poojas/$id');
  }

  // ── APPROVE pooja (superadmin only) ──────────────────────────
  Future<PoojaModel> approvePooja(String id) async {
    final response = await _apiClient.dio.patch('/api/v1/poojas/$id/approve');
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── REJECT pooja (superadmin only) ───────────────────────────
  Future<void> rejectPooja(String id, String reason) async {
    await _apiClient.dio.patch(
      '/api/v1/poojas/$id/reject',
      data: {'reason': reason},
    );
  }

  // ── Helpers to handle various response shapes ────────────────
  List<dynamic> _extractList(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is List) return d;
    if (d is Map) {
      for (final k in ['poojas', 'data', 'items', 'results']) {
        if (d[k] is List) return d[k] as List;
      }
    }
    for (final k in ['poojas', 'data', 'items', 'results']) {
      if (body[k] is List) return body[k] as List;
    }
    return const [];
  }

  Map<String, dynamic> _extractSingle(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) return d;
    return body;
  }
}
