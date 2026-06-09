import 'package:get/get.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/pooja_history_repository.dart';

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
    try {
      isLoading.value = true;
      error.value = null;
      print('DEBUG: Fetching pooja history from API...');
      final data = await _repository.getPoojaHistory();
      print('DEBUG: Pooja history API response: $data');

      final payload = data['data'] ?? data;
      if (payload is Map<String, dynamic>) {
        history.value = payload;

        final pending = payload['pending'];
        final Set<String> pendingPoojaIds = {};
        if (pending is List) {
          pendingPoojas.assignAll(pending);
          for (final session in pending) {
            if (session is Map) {
              final p = session['pooja'];
              if (p is Map) {
                final id = (p['_id'] ?? p['id'] ?? '').toString();
                if (id.isNotEmpty) pendingPoojaIds.add(id);
              }
            }
          }
          print('DEBUG: Loaded ${pendingPoojas.length} pending items');
        } else {
          pendingPoojas.clear();
          print('DEBUG: No pending list found in payload');
        }

        final finished = payload['finished'];
        if (finished is List) {
          // Filter to show only the most recent completion per unique puja,
          // and only if it's NOT currently in progress (pending).
          final Map<String, dynamic> uniqueFinished = {};
          for (final session in finished) {
            if (session is! Map) continue;
            final pooja = session['pooja'];
            if (pooja is! Map) continue;

            final id = (pooja['_id'] ?? pooja['id'] ?? '').toString();
            if (id.isEmpty) continue;

            // If this puja is currently in progress, don't show its old finished version
            if (pendingPoojaIds.contains(id)) continue;

            // Since the API usually returns items sorted by date descending,
            // the first one we encounter for an ID is the most recent.
            if (!uniqueFinished.containsKey(id)) {
              uniqueFinished[id] = session;
            }
          }
          finishedPoojas.assignAll(uniqueFinished.values.toList());
          print('DEBUG: Loaded ${finishedPoojas.length} unique finished items');
        } else {
          finishedPoojas.clear();
          print('DEBUG: No finished list found in payload');
        }
      } else {
        print('DEBUG: API payload is not a Map: $payload');
        error.value = 'Invalid data format from server';
      }
    } catch (e) {
      print('DEBUG: Error in fetchHistory: $e');
      error.value = 'Failed to load pooja history';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> startPooja(String poojaId) async {
    try {
      final result = await _repository.startPooja(poojaId);
      return result['data'];
    } catch (e) {
      print('Error starting pooja: $e');
      return null;
    }
  }

  Future<void> updateProgress(String sessionId, int currentStep) async {
    try {
      await _repository.updateProgress(sessionId, currentStep);
    } catch (e) {
      print('Error updating pooja progress: $e');
    }
  }

  Future<void> finishPooja(String poojaId) async {
    try {
      await _repository.finishPooja(poojaId);
      fetchHistory(); // Refresh list
    } catch (e) {
      print('Error finishing pooja: $e');
    }
  }

  Future<void> finishPoojaBySession(String sessionId) async {
    try {
      await _repository.finishPoojaBySession(sessionId);
      fetchHistory(); // Refresh list
    } catch (e) {
      print('Error finishing pooja by session: $e');
    }
  }
}
