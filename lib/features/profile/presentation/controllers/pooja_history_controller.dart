import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/pooja_history_repository.dart';

import 'package:satya_devotte_app/core/services/offline_service.dart';

class PoojaHistoryController extends GetxController {
  PoojaHistoryController(this._repository);
  final PoojaHistoryRepository _repository;

  final isLoading = false.obs;
  final error = RxnString();
  final history = <String, dynamic>{}.obs;
  final pendingPoojas = <dynamic>[].obs;
  final finishedPoojas = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    final offlineService = Get.find<OfflineService>();
    const cacheKey = 'pooja_history';
    try {
      isLoading.value = true;
      error.value = null;

      dynamic payload;
      if (offlineService.isOnline.value) {
        final data = await _repository.getPoojaHistory();
        payload = data['data'] ?? data;
        await offlineService.cacheData(cacheKey, payload);
      } else {
        payload = offlineService.getCachedData(cacheKey);
      }

      debugPrint('PoojaHistoryController.fetchHistory(): payload = $payload');

      if (payload is Map<String, dynamic>) {
        history.value = payload;
        final pending = payload['pending'];
        final Set<String> pendingPoojaIds = {};
        debugPrint('PoojaHistoryController.fetchHistory(): pending = $pending');
        if (pending is List) {
          pendingPoojas.assignAll(pending);
          for (final session in pending) {
            if (session is Map) {
              final p = session['pooja'];
              if (p is Map) {
                final id = (p['_id'] ?? p['id'] ?? '').toString();
                debugPrint('PoojaHistoryController.fetchHistory(): pending pooja id = $id');
                if (id.isNotEmpty) pendingPoojaIds.add(id);
              }
            }
          }
        } else {
          pendingPoojas.clear();
        }

        final finished = payload['finished'];
        debugPrint('PoojaHistoryController.fetchHistory(): finished = $finished');
        if (finished is List) {
          final Map<String, dynamic> uniqueFinished = {};
          for (final session in finished) {
            if (session is! Map) continue;
            final pooja = session['pooja'];
            if (pooja is! Map) continue;
            final id = (pooja['_id'] ?? pooja['id'] ?? '').toString();
            debugPrint('PoojaHistoryController.fetchHistory(): finished pooja id = $id');
            if (id.isEmpty || pendingPoojaIds.contains(id)) continue;
            if (!uniqueFinished.containsKey(id)) {
              uniqueFinished[id] = session;
            }
          }
          debugPrint('PoojaHistoryController.fetchHistory(): unique finished count = ${uniqueFinished.length}');
          finishedPoojas.assignAll(uniqueFinished.values.toList());
        } else {
          finishedPoojas.clear();
        }
      }
    } catch (e) {
      debugPrint('Error in fetchHistory: $e');
      error.value = 'Failed to load pooja history';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> startPooja(String poojaId) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      // Offline start: create a temporary session
      final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      await offlineService.queueAction('start_pooja', {
        'poojaId': poojaId,
        'tempId': tempId,
      });
      return {'_id': tempId, 'poojaId': poojaId, 'currentStep': 0};
    }
    try {
      final result = await _repository.startPooja(poojaId);
      return result['data'];
    } catch (e) {
      print('Error starting pooja: $e');
      return null;
    }
  }

  Future<void> updateProgress(String sessionId, int currentStep) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      await offlineService.queueAction('update_pooja_progress', {
        'sessionId': sessionId,
        'currentStep': currentStep,
      });
      return;
    }
    try {
      await _repository.updateProgress(sessionId, currentStep);
    } catch (e) {
      print('Error updating pooja progress: $e');
    }
  }

  Future<void> finishPooja(String poojaId) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      await offlineService.queueAction('finish_pooja', {'poojaId': poojaId});
      return;
    }
    try {
      await _repository.finishPooja(poojaId);
      fetchHistory();
    } catch (e) {
      print('Error finishing pooja: $e');
    }
  }

  Future<void> finishPoojaBySession(String sessionId) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      await offlineService.queueAction('finish_pooja', {
        'sessionId': sessionId,
      });
      return;
    }
    try {
      await _repository.finishPoojaBySession(sessionId);
      fetchHistory();
    } catch (e) {
      print('Error finishing pooja by session: $e');
    }
  }
}
