import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';

class PoojaRemoteDataSource {
  PoojaRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  // ── GET all poojas — public, no auth required ─────────────────
  Future<List<PoojaModel>> getAllPoojas({
    String? status,
    String? deity,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.poojas,
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

  // ── GET /poojas/my — admin's own poojas (requires admin role) ──
  Future<List<PoojaModel>> getMyPoojas() async {
    final response = await _apiClient.dio.get(ApiEndpoints.myPoojas);
    final body = response.data as Map<String, dynamic>;
    final list = _extractList(body);
    return list
        .map((e) => PoojaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /poojas/all — all poojas all statuses (requires super admin) ──
  Future<List<PoojaModel>> getAllPoojasSuperAdmin() async {
    final response = await _apiClient.dio.get(ApiEndpoints.allPoojas);
    final body = response.data as Map<String, dynamic>;
    final list = _extractList(body);
    return list
        .map((e) => PoojaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET single pooja ─────────────────────────────────────────
  Future<PoojaModel> getPoojaById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.pooja(id));
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── CREATE pooja (multipart/form-data, requires admin role) ──
  Future<PoojaModel> createPooja(PoojaModel pooja) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.createPooja,
      data: pooja.toJson(),
    );
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── UPDATE pooja — PATCH (requires admin role) ────────────────
  Future<PoojaModel> updatePooja(String id, PoojaModel pooja) async {
    final response = await _apiClient.dio.patch(
      ApiEndpoints.updatePooja(id),
      data: pooja.toJson(),
    );
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── DELETE pooja (requires admin role) ───────────────────────
  Future<void> deletePooja(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.deletePooja(id));
  }

  // ── REVIEW pooja — PUT /poojas/review/{id} (requires super admin) ──
  // Sets status to APPROVED or REJECTED per the new Swagger endpoint.
  Future<PoojaModel> reviewPooja(String id, String status) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.reviewPooja(id),
      data: {'status': status},
    );
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── Approve pooja — convenience wrapper around reviewPooja ───
  Future<PoojaModel> approvePooja(String id) async {
    return reviewPooja(id, 'APPROVED');
  }

  // ── Reject pooja — convenience wrapper around reviewPooja ────
  Future<void> rejectPooja(String id, String reason) async {
    await reviewPooja(id, 'REJECTED');
    // Note: if the API supports a rejection reason field, add it to the body
    // above once confirmed by the backend team.
  }

  // ── Helpers to handle various response shapes ─────────────────
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
