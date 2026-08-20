import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';
import 'package:satya_devotte_app/features/cms/data/models/cms_paged_result.dart';

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
    final offlineService = Get.isRegistered<OfflineService>() ? Get.find<OfflineService>() : null;
    dynamic body;
    if (offlineService != null && offlineService.isOnline.value) {
      try {
        final response = await _apiClient.dio.get(
          ApiEndpoints.poojas,
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
            if (deity != null && deity.isNotEmpty) 'deity': deity,
            'page': page,
            'limit': limit,
          },
        );
        body = response.data;
      } catch (_) {
        body = offlineService.getCachedData('all_poojas');
      }
    } else if (offlineService != null) {
      body = offlineService.getCachedData('all_poojas');
    }

    if (body == null) {
      try {
        final response = await _apiClient.dio.get(
          ApiEndpoints.poojas,
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
            if (deity != null && deity.isNotEmpty) 'deity': deity,
            'page': page,
            'limit': limit,
          },
        );
        body = response.data;
      } catch (_) {
        return const [];
      }
    }

    final list = _extractList(body is Map ? Map<String, dynamic>.from(body) : const {});
    return list
        .whereType<Map>()
        .map((e) => PoojaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET `/poojas` — approved pujas for logged-in users, with pagination.
  Future<CmsPagedResult<PoojaModel>> getApprovedPoojasPage({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final offlineService = Get.isRegistered<OfflineService>() ? Get.find<OfflineService>() : null;
    dynamic body;
    bool isFromOnlineApi = false;

    if (offlineService != null && offlineService.isOnline.value) {
      try {
        final response = await _apiClient.dio.get(
          ApiEndpoints.poojas,
          queryParameters: {
            'page': page,
            'limit': limit,
            if (search != null && search.isNotEmpty) 'search': search,
          },
        );
        body = response.data;
        isFromOnlineApi = true;
        if (page == 1 && (search == null || search.isEmpty)) {
          await offlineService.cacheData('all_poojas', body);
        }
      } catch (_) {
        body = offlineService.getCachedData('all_poojas');
      }
    } else if (offlineService != null) {
      body = offlineService.getCachedData('all_poojas');
    }

    if (body == null) {
      try {
        final response = await _apiClient.dio.get(
          ApiEndpoints.poojas,
          queryParameters: {
            'page': page,
            'limit': limit,
            if (search != null && search.isNotEmpty) 'search': search,
          },
        );
        body = response.data;
        isFromOnlineApi = true;
      } catch (_) {
        if (offlineService != null) {
          body = offlineService.getCachedData('all_poojas');
        }
      }
    }

    final list = _extractList(body is Map ? Map<String, dynamic>.from(body) : const {});
    var items = list
        .whereType<Map>()
        .map((e) => PoojaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    int total;
    int totalPages;

    if (isFromOnlineApi) {
      final pagination = CmsPaginationParser.fromBody(
        body,
        requestedPage: page,
        requestedLimit: limit,
        itemCount: items.length,
      );
      total = pagination.total;
      totalPages = pagination.totalPages < 1 ? 1 : pagination.totalPages;
    } else {
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        items = items.where((p) => p.title.toLowerCase().contains(q) || p.description.toLowerCase().contains(q)).toList();
      }

      total = items.length;
      totalPages = (total / limit).ceil() < 1 ? 1 : (total / limit).ceil();
      final startIndex = (page - 1) * limit;
      if (startIndex < items.length) {
        final endIndex = (startIndex + limit) > items.length ? items.length : startIndex + limit;
        items = items.sublist(startIndex, endIndex);
      } else {
        items = [];
      }
    }

    return CmsPagedResult<PoojaModel>(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  // ── GET /poojas/all or /poojas/my — paginated CMS list ───────
  Future<CmsPagedResult<PoojaModel>> getPoojasPage({
    required bool superAdmin,
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    final endpoint = ApiEndpoints.allPoojas;
    final response = await _apiClient.dio.get(
      endpoint,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final body = response.data;
    final list = _extractList(body is Map<String, dynamic> ? body : const {});
    final items = list
        .map((e) => PoojaModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = CmsPaginationParser.fromBody(
      body,
      requestedPage: page,
      requestedLimit: limit,
      itemCount: items.length,
    );
    return CmsPagedResult<PoojaModel>(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
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

  /// Fetch all created poojas across all pages for dropdowns/selectors
  Future<List<PoojaModel>> getAllPoojasForSelector({required bool superAdmin}) async {
    final firstPage = await getPoojasPage(
      superAdmin: superAdmin,
      page: 1,
      limit: 10,
    );
    final allItems = List<PoojaModel>.from(firstPage.items);
    if (firstPage.totalPages > 1) {
      for (int p = 2; p <= firstPage.totalPages; p++) {
        final pageResult = await getPoojasPage(
          superAdmin: superAdmin,
          page: p,
          limit: 10,
        );
        allItems.addAll(pageResult.items);
      }
    }
    return allItems;
  }

  // ── GET single pooja ─────────────────────────────────────────
  Future<PoojaModel> getPoojaById(String id) async {
    final offlineService = Get.isRegistered<OfflineService>() ? Get.find<OfflineService>() : null;
    if (offlineService != null && offlineService.isOnline.value) {
      try {
        final response = await _apiClient.dio.get(ApiEndpoints.pooja(id));
        final payload = response.data as Map<String, dynamic>;
        await offlineService.cacheData('pooja_detail_$id', payload);
        return PoojaModel.fromJson(_extractSingle(payload));
      } catch (_) {}
    }

    if (offlineService != null) {
      final cached = offlineService.getCachedData('pooja_detail_$id');
      if (cached is Map) {
        final map = Map<String, dynamic>.from(cached);
        return PoojaModel.fromJson(_extractSingle(map));
      }
      final allCached = offlineService.getCachedData('all_poojas');
      if (allCached is Map) {
        final list = _extractList(Map<String, dynamic>.from(allCached));
        for (final item in list) {
          if (item is Map && (item['_id'] ?? item['id'])?.toString() == id) {
            return PoojaModel.fromJson(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    final response = await _apiClient.dio.get(ApiEndpoints.pooja(id));
    return PoojaModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  // ── GET /deities — for CMS dropdowns (optional status filter) ─
  Future<List<Map<String, String>>> getDeities({String? status}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.allDeities,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': 100,
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

    final statusFilter = status?.trim().toUpperCase();

    return list
        .whereType<Map>()
        .where((e) {
          if (statusFilter == null || statusFilter.isEmpty) return true;
          final itemStatus = (e['status'] ?? '').toString().toUpperCase();
          return itemStatus == statusFilter;
        })
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
    List<List<PickedFile>> stepImagesByStep = const [],
  }) async {
    final hasStepImages = stepImagesByStep.any((files) => files.isNotEmpty);
    final hasMedia =
        image != null || audio != null || video != null || hasStepImages;
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

    final formData = _buildFormData(
      _toMultipartFields(payload),
      image: image,
      audio: audio,
      video: video,
      stepImagesByStep: stepImagesByStep,
    );
    if (kDebugMode) {
      debugPrint('[create-pooja] Multipart payload: ${_describeFormData(formData)}');
    }
    final response = await _apiClient.dio.post(
      ApiEndpoints.createPooja,
      data: formData,
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
    List<List<PickedFile>> stepImagesByStep = const [],
  }) async {
    final hasStepImages = stepImagesByStep.any((files) => files.isNotEmpty);
    final hasMedia =
        image != null || audio != null || video != null || hasStepImages;
    if (!hasMedia) {
      final payload = Map<String, dynamic>.from(pooja.toJson());
      _applyExplicitMediaClearsForPatch(payload, pooja);
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updatePooja(id),
        data: payload,
      );
      final result = PoojaModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
      if (image == null && result.imageUrl == null && pooja.imageUrl != null) {
        return result.copyWith(imageUrl: pooja.imageUrl);
      }
      return result;
    }

    final payload = Map<String, dynamic>.from(pooja.toJson());
    _stripMediaSlotsReplacedByFiles(
      payload,
      image: image,
      audio: audio,
      video: video,
    );
    final formData = _buildFormData(
      _toMultipartFields(payload),
      image: image,
      audio: audio,
      video: video,
      stepImagesByStep: stepImagesByStep,
    );
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updatePooja(id),
        data: formData,
      );
      final result = PoojaModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
      if (image == null && result.imageUrl == null && pooja.imageUrl != null) {
        return result.copyWith(imageUrl: pooja.imageUrl);
      }
      return result;
    } on DioException catch (e) {
      debugPrint('DioException in updatePooja:');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('Fields sent: ${_describeFormData(formData)}');
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
      payload['image'] = '';
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
      payload['image'] = '';
      _mediaMap(payload)['images'] = <String>[];
    } else {
      payload['imageUrl'] = p.imageUrl;
      payload['image'] = p.imageUrl;
      _mediaMap(payload)['images'] = [p.imageUrl!];
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

  FormData _buildFormData(
    Map<String, dynamic> formMap, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
    List<List<PickedFile>> stepImagesByStep = const [],
  }) {
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

    final stepImageMeta = <Map<String, int>>[];
    final stepImageFiles = <MultipartFile>[];
    for (var stepIdx = 0; stepIdx < stepImagesByStep.length; stepIdx++) {
      for (final file in stepImagesByStep[stepIdx]) {
        stepImageMeta.add({'stepNumber': stepIdx + 1});
        stepImageFiles.add(
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.filename,
            contentType: MediaType.parse(file.mimeType),
          ),
        );
      }
    }
    if (stepImageMeta.isNotEmpty) {
      formMap['stepImageMeta'] = jsonEncode(stepImageMeta);
    }

    final formData = FormData.fromMap(formMap);
    for (final file in stepImageFiles) {
      formData.files.add(MapEntry('stepImage', file));
    }
    return formData;
  }

  String _describeFormData(FormData formData) {
    final printable = <String, dynamic>{};
    for (final field in formData.fields) {
      printable[field.key] = field.value;
    }
    final stepImageCount = formData.files
        .where((entry) => entry.key == 'stepImage')
        .length;
    if (stepImageCount > 0) {
      printable['stepImage'] = 'MultipartFile x$stepImageCount';
    }
    for (final file in formData.files) {
      if (file.key == 'stepImage') continue;
      printable[file.key] = 'MultipartFile(filename: ${file.value.filename})';
    }
    return jsonEncode(printable);
  }
}
