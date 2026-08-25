import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/pooja_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satya_devotte_app/core/services/offline_service.dart';

class PoojaHistoryController extends GetxController {
  PoojaHistoryController(this._repository);
  final PoojaHistoryRepository _repository;

  final isLoading = false.obs;
  final error = RxnString();
  final history = <String, dynamic>{}.obs;
  final pendingPoojas = <dynamic>[].obs;
  final finishedPoojas = <dynamic>[].obs;
  final sessionDates = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSessionDates();
    fetchHistory();

    if (Get.isRegistered<OfflineService>()) {
      ever(Get.find<OfflineService>().isOnline, (isOnline) {
        if (isOnline == true) {
          fetchHistory();
        }
      });
    }
  }

  Future<void> _saveSessionDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pooja_session_dates_map',
        jsonEncode(sessionDates.value),
      );
    } catch (_) {}
  }

  Future<void> _loadSessionDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pooja_session_dates_map');
      if (raw != null) {
        final Map decoded = jsonDecode(raw);
        sessionDates.assignAll(
          decoded.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    } catch (_) {}
  }

  Future<void> fetchHistory({bool skipLoader = false}) async {
    final offlineService = Get.find<OfflineService>();
    const cacheKey = 'pooja_history';
    try {
      isLoading.value = true;
      error.value = null;

      dynamic payload;
      if (offlineService.isOnline.value) {
        try {
          final data = await _repository.getPoojaHistory(skipLoader: skipLoader);
          payload = data['data'] ?? data;
          await offlineService.cacheData(cacheKey, payload);
        } catch (_) {
          payload = offlineService.getCachedData(cacheKey);
        }
      } else {
        payload = offlineService.getCachedData(cacheKey);
      }

      debugPrint('PoojaHistoryController.fetchHistory(): payload = $payload');

      if (payload is Map) {
        history.value = Map<String, dynamic>.from(payload);
        final pending = payload['pending'];
        final Set<String> pendingPoojaIds = {};
        debugPrint('PoojaHistoryController.fetchHistory(): pending = $pending');
        if (pending is List) {
          final sortedPending = List<dynamic>.from(pending)
            ..sort((a, b) => _comparePoojaDates(a, b));
          pendingPoojas.assignAll(sortedPending);
          for (final session in sortedPending) {
            if (session is Map) {
              final p = session['pooja'];
              if (p is Map) {
                final id = (p['_id'] ?? p['id'] ?? '').toString();
                debugPrint(
                  'PoojaHistoryController.fetchHistory(): pending pooja id = $id',
                );
                if (id.isNotEmpty) pendingPoojaIds.add(id);
              }
            }
          }
        } else {
          pendingPoojas.clear();
        }

        final finished = payload['finished'];
        debugPrint(
          'PoojaHistoryController.fetchHistory(): finished = $finished',
        );
        if (finished is List) {
          final Map<String, dynamic> uniqueFinished = {};
          for (final session in finished) {
            if (session is! Map) continue;
            final pooja = session['pooja'];
            if (pooja is! Map) continue;
            final id = (pooja['_id'] ?? pooja['id'] ?? '').toString();
            debugPrint(
              'PoojaHistoryController.fetchHistory(): finished pooja id = $id',
            );
            if (id.isEmpty || pendingPoojaIds.contains(id)) continue;
            if (!uniqueFinished.containsKey(id)) {
              uniqueFinished[id] = session;
            }
          }
          debugPrint(
            'PoojaHistoryController.fetchHistory(): unique finished count = ${uniqueFinished.length}',
          );
          final sortedFinished = List<dynamic>.from(uniqueFinished.values)
            ..sort((a, b) => _comparePoojaDates(a, b));
          finishedPoojas.assignAll(sortedFinished);
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

  int _comparePoojaDates(dynamic a, dynamic b) {
    try {
      final aDate = _extractPoojaDate(a);
      final bDate = _extractPoojaDate(b);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1; // Put null dates at the end
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // Most recent first
    } catch (e) {
      return 0;
    }
  }

  DateTime? _extractPoojaDate(dynamic session) {
    if (session is! Map) return null;
    // Try common date fields in order of priority
    final dateFields = [
      'poojaDate',
      'scheduledDate',
      'date',
      'scheduledAt',
      'finishedAt',
      'createdAt',
    ];
    for (final field in dateFields) {
      final raw = session[field] ?? session['pooja']?[field];
      if (raw != null) {
        try {
          return DateTime.parse(raw.toString());
        } catch (_) {}
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> startPooja(
    String poojaId, {
    String? scheduleDate,
    String? scheduleId,
  }) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      // Offline start: create a temporary session
      final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      await offlineService.queueAction('start_pooja', {
        'poojaId': poojaId,
        'tempId': tempId,
        if (scheduleId != null) 'scheduleId': scheduleId,
      });
      final data = {'_id': tempId, 'poojaId': poojaId, 'currentStep': 0};
      if (scheduleDate != null) {
        sessionDates[tempId] = scheduleDate;
        await _saveSessionDates();
      }
      return data;
    }
    try {
      final result = await _repository.startPooja(
        poojaId,
        scheduleId: scheduleId,
      );
      final data = result['data'] ?? result;
      debugPrint('[History Controller Debug] startPooja data = $data');
      if (data is Map && scheduleDate != null) {
        final sId = (data['_id'] ?? data['id'] ?? '').toString();
        debugPrint(
          '[History Controller Debug] startPooja sId = $sId | scheduleDate = $scheduleDate',
        );
        if (sId.isNotEmpty) {
          sessionDates[sId] = scheduleDate;
          await _saveSessionDates();
        }
      }
      return data as Map<String, dynamic>?;
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

  Future<void> finishPooja(String poojaId, {String? scheduleId}) async {
    final offlineService = Get.find<OfflineService>();
    if (!offlineService.isOnline.value) {
      await offlineService.queueAction('finish_pooja', {
        'poojaId': poojaId,
        if (scheduleId != null) 'scheduleId': scheduleId,
      });
      _markLocalPoojaFinished(poojaId);
      return;
    }
    try {
      await _repository.finishPooja(poojaId, scheduleId: scheduleId);
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
      _markLocalSessionFinished(sessionId);
      return;
    }
    try {
      await _repository.finishPoojaBySession(sessionId);
      fetchHistory();
    } catch (e) {
      print('Error finishing pooja by session: $e');
    }
  }

  void _markLocalPoojaFinished(String poojaId) {
    final session = {
      '_id': 'offline_finished_${DateTime.now().millisecondsSinceEpoch}',
      'pooja': {'_id': poojaId, 'id': poojaId},
      'status': 'FINISHED',
      'finishedAt': DateTime.now().toIso8601String(),
    };
    finishedPoojas.add(session);
    finishedPoojas.refresh();
  }

  void _markLocalSessionFinished(String sessionId) {
    Map? target;
    pendingPoojas.removeWhere((item) {
      if (item is Map && (item['_id'] ?? item['id'])?.toString() == sessionId) {
        target = item;
        return true;
      }
      return false;
    });
    if (target != null) {
      final updated = Map<String, dynamic>.from(target!)
        ..['status'] = 'FINISHED'
        ..['finishedAt'] = DateTime.now().toIso8601String();
      finishedPoojas.add(updated);
    } else {
      _markLocalPoojaFinished(sessionId);
    }
    pendingPoojas.refresh();
    finishedPoojas.refresh();
  }
}
