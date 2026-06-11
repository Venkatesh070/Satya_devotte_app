import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/models/deity_model.dart';

import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:satya_devotte_app/core/services/offline_service.dart';

class DeityRemoteDataSource {
  DeityRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<List<DeityModel>> getDeities({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final offlineService = Get.find<OfflineService>();
    final cacheKey = 'deities_list_${page}_${limit}_$status';

    try {
      dynamic raw;
      if (offlineService.isOnline.value) {
        final response = await _apiClient.dio.get(
          ApiEndpoints.allDeities,
          queryParameters: {
            'page': page,
            'limit': limit,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        );
        raw = response.data;
        await offlineService.cacheData(cacheKey, raw);
      } else {
        raw = offlineService.getCachedData(cacheKey);
      }

      List<dynamic> list = const [];
      if (raw is Map<String, dynamic>) {
        final d = raw['data'];
        if (d is List) list = d;
        if (d is Map && d['deities'] is List) list = d['deities'] as List;
        if (list.isEmpty && raw['deities'] is List)
          list = raw['deities'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return list
          .whereType<Map>()
          .map((e) => DeityModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('DeityRemoteDataSource: getDeities error: $e');
      final cached = offlineService.getCachedData(cacheKey);
      if (cached != null) {
        // ... parse cached data
      }
      rethrow;
    }
  }

  Future<DeityModel> getDeityById(String id) async {
    final offlineService = Get.find<OfflineService>();
    final cacheKey = 'deity_detail_$id';

    try {
      dynamic raw;
      if (offlineService.isOnline.value) {
        final response = await _apiClient.dio.get(ApiEndpoints.deity(id));
        raw = response.data;
        await offlineService.cacheData(cacheKey, raw);
      } else {
        raw = offlineService.getCachedData(cacheKey);
      }

      if (raw is Map<String, dynamic>) {
        final data = raw['data'] ?? raw;
        if (data is Map<String, dynamic>) {
          final deity = data['deity'];
          if (deity is Map<String, dynamic>) {
            return DeityModel.fromJson(deity);
          }
          return DeityModel.fromJson(data);
        }
        return DeityModel.fromJson(raw);
      }
      throw Exception('Deity not found');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createDeity(
    Map<String, dynamic> payload, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    final hasMedia = image != null || audio != null || video != null;
    if (!hasMedia) {
      if (kDebugMode) {
        debugPrint('[create-deity] JSON payload: ${jsonEncode(payload)}');
      }
      await _apiClient.dio.post(ApiEndpoints.createDeity, data: payload);
      return;
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
        printable[key] = value is MultipartFile
            ? 'MultipartFile(filename: ${value.filename})'
            : value;
      });
      debugPrint('[create-deity] Multipart payload: ${jsonEncode(printable)}');
    }
    await _apiClient.dio.post(
      ApiEndpoints.createDeity,
      data: FormData.fromMap(formMap),
    );
  }

  Future<void> updateDeity(
    String id,
    Map<String, dynamic> payload, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    final hasMedia = image != null || audio != null || video != null;
    if (!hasMedia) {
      await _apiClient.dio.patch(ApiEndpoints.updateDeity(id), data: payload);
      return;
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
    await _apiClient.dio.patch(
      ApiEndpoints.updateDeity(id),
      data: FormData.fromMap(formMap),
    );
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
}
