import 'package:dio/dio.dart';
// lib/features/cms/data/datasources/festival_remote_datasource.dart
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/features/cms/models/festival_model.dart';

class FestivalRemoteDataSource {
  FestivalRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  // ── Extract list — handles { data: { festivals: [...] } } ─────
  List<dynamic> _list(Map<String, dynamic> body) {
    // Response shape: { "data": { "festivals": [...] } }
    final d = body['data'];
    if (d is List) return d;
    if (d is Map<String, dynamic>) {
      // Check known keys in data object
      for (final k in ['festivals', 'items', 'results', 'data']) {
        final v = d[k];
        if (v is List) return v;
      }
    }
    // Fallback: check top-level body
    for (final k in ['festivals', 'items', 'results', 'data']) {
      final v = body[k];
      if (v is List) return v;
    }
    return [];
  }

  // ── Extract single — handles { data: { festival: {...} } } ────
  Map<String, dynamic> _single(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) {
      // unwrap nested 'festival' key if present
      if (d.containsKey('festival') && d['festival'] is Map<String, dynamic>) {
        return d['festival'] as Map<String, dynamic>;
      }
      return d;
    }
    return body;
  }

  // ── GET /festivals/my — admin's own ──────────────────────────
  Future<List<FestivalModel>> getMyFestivals() async {
    final res = await _apiClient.dio.get('/api/v1/festivals/my');
    return _list(
      res.data as Map<String, dynamic>,
    ).map((e) => FestivalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /festivals/all — superadmin ──────────────────────────
  Future<List<FestivalModel>> getAllFestivals() async {
    final res = await _apiClient.dio.get('/api/v1/festivals/all');
    return _list(
      res.data as Map<String, dynamic>,
    ).map((e) => FestivalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── POST /festivals/create-festival — multipart/form-data ──────
  Future<FestivalModel> createFestival(Map<String, dynamic> body) async {
    // Swagger shows multipart/form-data — convert map to FormData
    final fields = <String, dynamic>{};
    body.forEach((k, v) {
      if (v != null) fields[k] = v is bool ? v.toString() : v.toString();
    });
    final res = await _apiClient.dio.post(
      '/api/v1/festivals/create-festival',
      data: FormData.fromMap(fields),
    );
    return FestivalModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  // ── PATCH /festivals/{id} ─────────────────────────────────────
  Future<FestivalModel> updateFestival(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res = await _apiClient.dio.patch('/api/v1/festivals/$id', data: body);
    return FestivalModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  // ── DELETE /festivals/{id} ────────────────────────────────────
  Future<void> deleteFestival(String id) async {
    await _apiClient.dio.delete('/api/v1/festivals/$id');
  }

  // ── PUT /festivals/review/{id} — superadmin ───────────────────
  Future<FestivalModel> reviewFestival(
    String id,
    String status, {
    String? reason,
  }) async {
    final res = await _apiClient.dio.put(
      '/api/v1/festivals/review/$id',
      data: {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return FestivalModel.fromJson(_single(res.data as Map<String, dynamic>));
  }
}
