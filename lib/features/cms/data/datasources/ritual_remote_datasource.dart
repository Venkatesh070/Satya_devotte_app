// lib/features/cms/data/datasources/ritual_remote_datasource.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/interceptors.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/cms/data/models/cms_paged_result.dart';

class RitualRemoteDataSource {
  RitualRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<List<RitualModel>> getAllRituals({
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
          ApiEndpoints.rituals,
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
            if (deity != null && deity.isNotEmpty) 'deity': deity,
            'page': page,
            'limit': limit,
          },
        );
        body = response.data;
      } catch (_) {
        body = offlineService.getCachedData('all_rituals');
      }
    } else if (offlineService != null) {
      body = offlineService.getCachedData('all_rituals');
    }

    if (body == null) {
      try {
        final response = await _apiClient.dio.get(
          ApiEndpoints.rituals,
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
        .map((e) => RitualModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET `/rituals` — approved rituals for logged-in users, with pagination.
  Future<CmsPagedResult<RitualModel>> getApprovedRitualsPage({
    int page = 1,
    int limit = 10,
    String? search,
    bool skipLoader = false,
  }) async {
    final offlineService = Get.isRegistered<OfflineService>() ? Get.find<OfflineService>() : null;
    dynamic body;
    bool isFromOnlineApi = false;
    final options = skipLoader ? Options(extra: {kSkipApiLoaderKey: true}) : null;

    if (offlineService != null && offlineService.isOnline.value) {
      try {
        final response = await _apiClient.dio.get(
          ApiEndpoints.rituals,
          queryParameters: {
            'page': page,
            'limit': limit,
            if (search != null && search.isNotEmpty) 'search': search,
          },
          options: options,
        );
        body = response.data;
        isFromOnlineApi = true;
        if (page == 1 && (search == null || search.isEmpty)) {
          await offlineService.cacheData('all_rituals', body);
        }
      } catch (_) {
        body = offlineService.getCachedData('all_rituals');
      }
    } else if (offlineService != null) {
      body = offlineService.getCachedData('all_rituals');
    }

    if (body == null) {
      try {
        final response = await _apiClient.dio.get(
          ApiEndpoints.rituals,
          queryParameters: {
            'page': page,
            'limit': limit,
            if (search != null && search.isNotEmpty) 'search': search,
          },
          options: options,
        );
        body = response.data;
        isFromOnlineApi = true;
      } catch (_) {
        if (offlineService != null) {
          body = offlineService.getCachedData('all_rituals');
        }
      }
    }

    final list = _extractList(body is Map ? Map<String, dynamic>.from(body) : const {});
    var items = list
        .whereType<Map>()
        .map((e) => RitualModel.fromJson(Map<String, dynamic>.from(e)))
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
        items = items.where((r) => r.title.toLowerCase().contains(q) || (r.description ?? '').toLowerCase().contains(q)).toList();
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

    return CmsPagedResult<RitualModel>(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  Future<CmsPagedResult<RitualModel>> getRitualsPage({
    required bool superAdmin,
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    final endpoint = ApiEndpoints.allRituals;
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
        .map((e) => RitualModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = CmsPaginationParser.fromBody(
      body,
      requestedPage: page,
      requestedLimit: limit,
      itemCount: items.length,
    );
    return CmsPagedResult<RitualModel>(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  Future<List<RitualModel>> getMyRituals() async {
    final response = await _apiClient.dio.get(ApiEndpoints.allRituals);
    final body = response.data as Map<String, dynamic>;
    final list = _extractList(body);
    return list
        .map((e) => RitualModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RitualModel>> getAllRitualsSuperAdmin() async {
    final response = await _apiClient.dio.get(ApiEndpoints.allRituals);
    final body = response.data as Map<String, dynamic>;
    final list = _extractList(body);
    return list
        .map((e) => RitualModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RitualModel> getRitualById(String id) async {
    final offlineService = Get.isRegistered<OfflineService>() ? Get.find<OfflineService>() : null;
    if (offlineService != null && offlineService.isOnline.value) {
      try {
        final response = await _apiClient.dio.get(ApiEndpoints.ritual(id));
        final payload = response.data as Map<String, dynamic>;
        await offlineService.cacheData('ritual_detail_$id', payload);
        return RitualModel.fromJson(_extractSingle(payload));
      } catch (_) {}
    }

    if (offlineService != null) {
      final cached = offlineService.getCachedData('ritual_detail_$id');
      if (cached is Map) {
        final map = Map<String, dynamic>.from(cached);
        return RitualModel.fromJson(_extractSingle(map));
      }
      final allCached = offlineService.getCachedData('all_rituals');
      if (allCached is Map) {
        final list = _extractList(Map<String, dynamic>.from(allCached));
        for (final item in list) {
          if (item is Map && (item['_id'] ?? item['id'])?.toString() == id) {
            return RitualModel.fromJson(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    final response = await _apiClient.dio.get(ApiEndpoints.ritual(id));
    return RitualModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  Future<RitualModel> createRitual(
    RitualModel ritual, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
    List<List<PickedFile>> stepImagesByDay = const [],
  }) async {
    final hasStepImages = stepImagesByDay.any((files) => files.isNotEmpty);
    final hasMedia = _hasMediaFiles(image: image, audio: audio, video: video);
    final payload = Map<String, dynamic>.from(ritual.toJson());
    if (hasMedia) {
      _stripMediaSlotsReplacedByFiles(
        payload,
        image: image,
        audio: audio,
        video: video,
      );
    }

    if (!hasMedia && !hasStepImages) {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createRitual,
        data: payload,
      );
      return RitualModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
    }

    final formMap = _toMultipartFields(payload);
    final formData = _buildFormData(
      formMap,
      image: image,
      audio: audio,
      video: video,
      stepImagesByDay: stepImagesByDay,
    );

    final response = await _apiClient.dio.post(
      ApiEndpoints.createRitual,
      data: formData,
    );
    return RitualModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  Future<RitualModel> updateRitual(
    String id,
    RitualModel ritual, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
    List<List<PickedFile>> stepImagesByDay = const [],
  }) async {
    final hasStepImages = stepImagesByDay.any((files) => files.isNotEmpty);
    final hasMedia = _hasMediaFiles(image: image, audio: audio, video: video);
    if (!hasMedia && !hasStepImages) {
      final payload = Map<String, dynamic>.from(ritual.toJson());
      _applyExplicitMediaClearsForPatch(payload, ritual);
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updateRitual(id),
        data: payload,
      );
      return RitualModel.fromJson(
        _extractSingle(response.data as Map<String, dynamic>),
      );
    }

    final payload = Map<String, dynamic>.from(ritual.toJson());
    _stripMediaSlotsReplacedByFiles(
      payload,
      image: image,
      audio: audio,
      video: video,
    );
    final formMap = _toMultipartFields(payload);
    final formData = _buildFormData(
      formMap,
      image: image,
      audio: audio,
      video: video,
      stepImagesByDay: stepImagesByDay,
    );

    final response = await _apiClient.dio.patch(
      ApiEndpoints.updateRitual(id),
      data: formData,
    );
    return RitualModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  Future<void> deleteRitual(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.deleteRitual(id));
  }

  Future<RitualModel> reviewRitual(String id, String status) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.reviewRitual(id),
      data: {'status': status},
    );
    return RitualModel.fromJson(
      _extractSingle(response.data as Map<String, dynamic>),
    );
  }

  List<dynamic> _extractList(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is List) return d;
    if (d is Map) {
      for (final k in ['rituals', 'poojas', 'data', 'items', 'results']) {
        if (d[k] is List) return d[k] as List;
      }
    }
    for (final k in ['rituals', 'poojas', 'data', 'items', 'results']) {
      if (body[k] is List) return body[k] as List;
    }
    return const [];
  }

  Map<String, dynamic> _extractSingle(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) {
      if (d['ritual'] is Map) {
        return Map<String, dynamic>.from(d['ritual'] as Map);
      }
      return d;
    }
    if (body['ritual'] is Map) {
      return Map<String, dynamic>.from(body['ritual'] as Map);
    }
    return body;
  }

  Map<String, dynamic> _toMultipartFields(Map<String, dynamic> source) {
    final out = <String, dynamic>{};
    source.forEach((k, v) {
      if (v == null) return;
      if (v is Map || v is List) {
        out[k] = jsonEncode(v);
      } else {
        out[k] = v.toString();
      }
    });
    return out;
  }

  bool _pickedHasBytes(PickedFile? f) => f != null && f.bytes.isNotEmpty;

  bool _hasMediaFiles({
    required PickedFile? image,
    required PickedFile? audio,
    required PickedFile? video,
  }) =>
      _pickedHasBytes(image) || _pickedHasBytes(audio) || _pickedHasBytes(video);

  void _stripMediaSlotsReplacedByFiles(
    Map<String, dynamic> payload, {
    required PickedFile? image,
    required PickedFile? audio,
    required PickedFile? video,
  }) {
    if (_pickedHasBytes(image)) {
      payload['imageUrl'] = '';
      _mediaMap(payload)['images'] = <String>[];
    }
    if (_pickedHasBytes(audio)) {
      payload['audioUrl'] = '';
      _mediaMap(payload)['audio'] = <String>[];
    }
    if (_pickedHasBytes(video)) {
      payload['videoUrl'] = '';
      _mediaMap(payload)['videos'] = <String>[];
    }
  }

  void _applyExplicitMediaClearsForPatch(
    Map<String, dynamic> payload,
    RitualModel ritual,
  ) {
    if (ritual.imageUrl == null) {
      payload['imageUrl'] = '';
      _mediaMap(payload)['images'] = <String>[];
    }
    if (ritual.audioUrl == null) {
      payload['audioUrl'] = '';
      _mediaMap(payload)['audio'] = <String>[];
    }
    if (ritual.videoUrl == null) {
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
    List<List<PickedFile>> stepImagesByDay = const [],
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
    for (var dayIdx = 0; dayIdx < stepImagesByDay.length; dayIdx++) {
      for (final file in stepImagesByDay[dayIdx]) {
        stepImageMeta.add({'stepNumber': dayIdx + 1});
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
}
