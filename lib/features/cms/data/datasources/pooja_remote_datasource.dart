import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
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

  // ── GET /poojas/all — admin's own poojas (requires admin role) ──
  Future<List<PoojaModel>> getMyPoojas() async {
    final response = await _apiClient.dio.get(ApiEndpoints.allPoojas);
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
    final response = await _apiClient.dio.get(ApiEndpoints.allDeities);
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
        .map((e) {
          final id = e['_id']?.toString() ?? e['id']?.toString() ?? '';
          final name =
              e['name']?.toString() ??
              e['title']?.toString() ??
              e['deityName']?.toString() ??
              '';
          return {'id': id.trim(), 'name': name.trim()};
        })
        .where((e) => e['id']!.isNotEmpty)
        .toList();
  }

  // ── CREATE pooja — multipart/form-data with optional media files ──
  Future<PoojaModel> createPooja(
    PoojaModel pooja, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    final hasMedia = image != null || audio != null || video != null;
    final payload = Map<String, dynamic>.from(pooja.toJson());
    if (hasMedia) {
      _stripMediaSlotsReplacedByFiles(
        payload,
        image: image,
        audio: audio,
        video: video,
      );
    }
    if (!hasMedia) {
      if (kDebugMode) {
        debugPrint('[create-pooja] JSON payload: ${jsonEncode(payload)}');
      }
      final response = await _apiClient.dio.post(
        ApiEndpoints.createPooja,
        data: payload,
      );
      return PoojaModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
    }

    final formMap = _toMultipartFields(payload);
    if (image != null) {
      formMap['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
        contentType: MediaType.parse(image.mimeType),
      );
    }
    if (audio != null) {
      formMap['audio'] = MultipartFile.fromBytes(
        audio.bytes,
        filename: audio.filename,
        contentType: MediaType.parse(audio.mimeType),
      );
    }
    if (video != null) {
      formMap['video'] = MultipartFile.fromBytes(
        video.bytes,
        filename: video.filename,
        contentType: MediaType.parse(video.mimeType),
      );
    }
    if (kDebugMode) {
      final printable = <String, dynamic>{};
      formMap.forEach((key, value) {
        if (value is MultipartFile) {
          printable[key] = 'MultipartFile(filename: ${value.filename})';
        } else {
          printable[key] = value;
        }
      });
      debugPrint('[create-pooja] Multipart payload: ${jsonEncode(printable)}');
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
      final payload = Map<String, dynamic>.from(pooja.toJson());
      _applyExplicitMediaClearsForPatch(payload, pooja);
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updatePooja(id),
        data: payload,
      );
      return PoojaModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
    }

    final payload = Map<String, dynamic>.from(pooja.toJson());
    _stripMediaSlotsReplacedByFiles(
      payload,
      image: image,
      audio: audio,
      video: video,
    );
    final formMap = _toMultipartFields(payload);
    if (image != null) {
      formMap['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
        contentType: MediaType.parse(image.mimeType),
      );
    }
    if (audio != null) {
      formMap['audio'] = MultipartFile.fromBytes(
        audio.bytes,
        filename: audio.filename,
        contentType: MediaType.parse(audio.mimeType),
      );
    }
    if (video != null) {
      formMap['video'] = MultipartFile.fromBytes(
        video.bytes,
        filename: video.filename,
        contentType: MediaType.parse(video.mimeType),
      );
    }
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updatePooja(id),
        data: FormData.fromMap(formMap),
      );
      return PoojaModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('DioException in updatePooja:');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('Fields sent: ${formMap.keys}');
      rethrow;
    }
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

    source.forEach((k, v) {
      if (v == null) return;

      // Many backends expect complex objects (Maps and Lists) to be sent
      // as JSON strings in multipart/form-data requests to avoid
      // parsing issues with bracket notation.
      if (v is Map || v is List) {
        out[k] = jsonEncode(v);
      } else {
        out[k] = v.toString();
      }
    });

    return out;
  }

  /// Nested [media] must not keep old S3 URLs when a new file is sent for that slot.
  /// Also send empty top-level URL strings so multipart PATCH does not leave stale URLs.
  void _stripMediaSlotsReplacedByFiles(
    Map<String, dynamic> payload, {
    required PickedFile? image,
    required PickedFile? audio,
    required PickedFile? video,
  }) {
    if (image != null) {
      payload['imageUrl'] = '';
      _mediaMap(payload)['images'] = <String>[];
    }
    if (audio != null) {
      payload['audioUrl'] = '';
      _mediaMap(payload)['audio'] = <String>[];
    }
    if (video != null) {
      payload['videoUrl'] = '';
      _mediaMap(payload)['videos'] = <String>[];
    }
  }

  /// PATCH often treats omitted keys as "leave unchanged". The CMS form sends full
  /// state; [null] URL means the user cleared that slot — send empty strings / arrays.
  void _applyExplicitMediaClearsForPatch(
    Map<String, dynamic> payload,
    PoojaModel p,
  ) {
    if (p.imageUrl == null) {
      payload['imageUrl'] = '';
      _mediaMap(payload)['images'] = <String>[];
    }
    if (p.audioUrl == null) {
      payload['audioUrl'] = '';
      _mediaMap(payload)['audio'] = <String>[];
    }
    if (p.videoUrl == null) {
      payload['videoUrl'] = '';
      _mediaMap(payload)['videos'] = <String>[];
    }
  }

  Map<String, dynamic> _mediaMap(Map<String, dynamic> payload) {
    final raw = payload['media'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      payload['media'] = m;
      return m;
    }
    final fresh = <String, dynamic>{
      'images': <String>[],
      'audio': <String>[],
      'videos': <String>[],
    };
    payload['media'] = fresh;
    return fresh;
  }
}
