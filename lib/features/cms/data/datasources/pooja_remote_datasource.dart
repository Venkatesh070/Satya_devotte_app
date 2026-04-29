import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
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

  // ── GET /deities — for Add Pooja dropdown ───────────────────
  Future<List<Map<String, String>>> getDeities() async {
    final response = await _apiClient.dio.get(ApiEndpoints.deities);
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

    return list.whereType<Map>().map((e) {
      final id = e['_id']?.toString() ?? e['id']?.toString() ?? '';
      final name =
          e['name']?.toString() ??
          e['title']?.toString() ??
          e['deityName']?.toString() ??
          '';
      return {'id': id.trim(), 'name': name.trim()};
    }).where((e) => e['id']!.isNotEmpty).toList();
  }

  // ── CREATE pooja — multipart/form-data with optional media files ──
  Future<PoojaModel> createPooja(
    PoojaModel pooja, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    final hasMedia = image != null || audio != null || video != null;
    if (!hasMedia) {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createPooja,
        data: pooja.toJson(),
      );
      return PoojaModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
    }

    final formMap = _toMultipartFields(pooja.toJson());
    if (image != null) {
      formMap['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    if (audio != null) {
      formMap['audio'] = MultipartFile.fromBytes(
        audio.bytes,
        filename: audio.filename,
      );
    }
    if (video != null) {
      formMap['video'] = MultipartFile.fromBytes(
        video.bytes,
        filename: video.filename,
      );
    }
    final response = await _apiClient.dio.post(
      ApiEndpoints.createPooja,
      data: FormData.fromMap(formMap),
    );
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── UPDATE pooja — PATCH with optional media files ──────────────
  Future<PoojaModel> updatePooja(
    String id,
    PoojaModel pooja, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    final hasMedia = image != null || audio != null || video != null;
    if (!hasMedia) {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updatePooja(id),
        data: pooja.toJson(),
      );
      return PoojaModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
    }

    final formMap = _toMultipartFields(pooja.toJson());
    if (image != null) {
      formMap['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    if (audio != null) {
      formMap['audio'] = MultipartFile.fromBytes(
        audio.bytes,
        filename: audio.filename,
      );
    }
    if (video != null) {
      formMap['video'] = MultipartFile.fromBytes(
        video.bytes,
        filename: video.filename,
      );
    }
    final response = await _apiClient.dio.patch(
      ApiEndpoints.updatePooja(id),
      data: FormData.fromMap(formMap),
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

  Map<String, dynamic> _toMultipartFields(Map<String, dynamic> source) {
    final out = <String, dynamic>{};

    void append(String key, dynamic value) {
      if (value == null) return;
      if (value is Map) {
        value.forEach((k, v) {
          append('$key[$k]', v);
        });
        return;
      }
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          append('$key[$i]', value[i]);
        }
        return;
      }
      out[key] = value;
    }

    source.forEach((k, v) => append(k, v));
    return out;
  }
}
