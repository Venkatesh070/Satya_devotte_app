import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/offline_service.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/ritual_history_repository.dart';

class RitualHistoryController extends GetxController {
  RitualHistoryController(this._repository);
  final RitualHistoryRepository _repository;

  final isLoading = false.obs;
  final error = RxnString();
  final pendingRituals = <dynamic>[].obs;
  final finishedRituals = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
    if (Get.isRegistered<OfflineService>()) {
      ever(Get.find<OfflineService>().isOnline, (isOnline) {
        if (isOnline == true) fetchHistory();
      });
    }
  }

  Future<void> fetchHistory() async {
    final offlineService = Get.find<OfflineService>();
    const cacheKey = 'ritual_history';
    try {
      isLoading.value = true;
      error.value = null;

      dynamic payload;
      if (offlineService.isOnline.value) {
        try {
          final data = await _repository.getRitualHistory();
          payload = data['data'] ?? data;
          await offlineService.cacheData(cacheKey, payload);
        } catch (_) {
          payload = offlineService.getCachedData(cacheKey);
        }
      } else {
        payload = offlineService.getCachedData(cacheKey);
      }

      if (payload is Map) {
        final pending = payload['pending'];
        if (pending is List) {
          pendingRituals.assignAll(pending);
        } else {
          pendingRituals.clear();
        }

        final finished = payload['finished'];
        if (finished is List) {
          // One entry per ritual. Keep finished even if the user restarted
          // the same ritual (PENDING) so completed count matches achievements.
          final unique = <String, dynamic>{};
          for (final session in finished) {
            if (session is! Map) continue;
            final id = _ritualIdFromSession(session);
            if (id.isEmpty) continue;
            // Skip sessions whose ritual was deleted / failed to populate.
            final ritual = session['ritual'];
            if (ritual is! Map) continue;
            unique.putIfAbsent(id, () => session);
          }
          finishedRituals.assignAll(unique.values);
        } else {
          finishedRituals.clear();
        }
      }
    } catch (e) {
      debugPrint('RitualHistoryController.fetchHistory: $e');
      error.value = 'Failed to load ritual history';
    } finally {
      isLoading.value = false;
    }
  }

  String _ritualIdFromSession(Map session) {
    final ritual = session['ritual'];
    if (ritual is Map) {
      return (ritual['_id'] ?? ritual['id'] ?? '').toString();
    }
    return (session['ritual'] ?? '').toString();
  }

  Map<String, dynamic>? findPendingSession(String ritualId) {
    for (final session in pendingRituals) {
      if (session is Map && _ritualIdFromSession(session) == ritualId) {
        return Map<String, dynamic>.from(session);
      }
    }
    return null;
  }

  bool isRitualFinished(String ritualId) {
    return finishedRituals.whereType<Map>().any(
      (session) => _ritualIdFromSession(session) == ritualId,
    );
  }

  Future<Map<String, dynamic>?> startRitual(String ritualId) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      await offlineService.queueAction('start_ritual', {
        'ritualId': ritualId,
        'tempId': tempId,
      });
      return {
        'session': {
          '_id': tempId,
          'ritual': ritualId,
          'currentDay': 1,
          'currentStep': 0,
        },
      };
    }
    try {
      final result = await _repository.startRitual(ritualId);
      final data = result['data'] ?? result;
      await fetchHistory();
      return data is Map<String, dynamic> ? data : null;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      debugPrint('Error starting ritual: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> startDay(String sessionId) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      await offlineService.queueAction('start_ritual_day', {
        'sessionId': sessionId,
      });
      return {'session': {'_id': sessionId}};
    }
    try {
      final result = await _repository.startDay(sessionId);
      return (result['data'] ?? result) as Map<String, dynamic>?;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      debugPrint('Error starting ritual day: $e');
      return null;
    }
  }

  Future<void> updateProgress(
    String sessionId,
    int currentStep, {
    int? currentDay,
  }) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      await offlineService.queueAction('update_ritual_progress', {
        'sessionId': sessionId,
        'currentStep': currentStep,
        if (currentDay != null) 'currentDay': currentDay,
      });
      return;
    }
    try {
      await _repository.updateProgress(
        sessionId,
        currentStep: currentStep,
        currentDay: currentDay,
      );
    } catch (e) {
      debugPrint('Error updating ritual progress: $e');
    }
  }

  Future<Map<String, dynamic>?> completeDay(String sessionId) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      await offlineService.queueAction('complete_ritual_day', {
        'sessionId': sessionId,
      });
      return null;
    }
    try {
      final result = await _repository.completeDay(sessionId);
      await fetchHistory();
      return (result['data'] ?? result) as Map<String, dynamic>?;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    } catch (e) {
      debugPrint('Error completing ritual day: $e');
      return null;
    }
  }

  void _handleDioError(DioException e) {
    final status = e.response?.statusCode;
    final message = e.response?.data is Map
        ? (e.response!.data['message'] ?? e.response!.data['error'])
              ?.toString()
        : null;
    if (status == 409 && message != null) {
      Get.snackbar(
        'Ritual restarted',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
      fetchHistory();
    } else if (message != null && message.isNotEmpty) {
      Get.snackbar('Ritual', message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
