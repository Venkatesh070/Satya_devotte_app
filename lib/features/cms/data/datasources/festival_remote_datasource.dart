import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
// lib/features/cms/data/datasources/festival_remote_datasource.dart
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/models/festival_model.dart';
import 'package:satya_devotte_app/features/cms/data/models/cms_paged_result.dart';

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

  // ── GET /festivals/all or /festivals/my — paginated CMS list ──
  Future<CmsPagedResult<FestivalModel>> getFestivalsPage({
    required bool superAdmin,
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    final endpoint = '/api/v1/festivals/all';
    final res = await _apiClient.dio.get(
      endpoint,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final body = res.data;
    final list = _list(body is Map<String, dynamic> ? body : const {});
    final items = list
        .map((e) => FestivalModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = CmsPaginationParser.fromBody(
      body,
      requestedPage: page,
      requestedLimit: limit,
      itemCount: items.length,
    );
    return CmsPagedResult<FestivalModel>(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
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
  Future<FestivalModel> createFestival(
    Map<String, dynamic> body, {
    PickedFile? image,
  }) async {
    final fields = <String, dynamic>{};
    body.forEach((k, v) {
      if (v == null) return;
      if (v is Map || v is List) {
        fields[k] = jsonEncode(v);
      } else if (v is bool) {
        fields[k] = v.toString();
      } else {
        fields[k] = v.toString();
      }
    });
    // Add image bytes directly in create request
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    final res = await _apiClient.dio.post(
      '/api/v1/festivals/create-festival',
      data: FormData.fromMap(fields),
    );
    return FestivalModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  // ── PATCH /festivals/{id} — multipart when replacing the image ─
  Future<FestivalModel> updateFestival(
    String id,
    Map<String, dynamic> body, {
    PickedFile? image,
  }) async {
    final fields = <String, dynamic>{};
    body.forEach((k, v) {
      if (v == null) return;
      if (v is Map || v is List) {
        fields[k] = jsonEncode(v);
      } else if (v is bool) {
        fields[k] = v.toString();
      } else {
        fields[k] = v.toString();
      }
    });
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    final res = await _apiClient.dio.patch(
      '/api/v1/festivals/$id',
      data: image != null ? FormData.fromMap(fields) : body,
    );
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
