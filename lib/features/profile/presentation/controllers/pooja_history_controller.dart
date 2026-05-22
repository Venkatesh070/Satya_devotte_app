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
        if (pending is List) {
          pendingPoojas.assignAll(pending);
          print('DEBUG: Loaded ${pendingPoojas.length} pending items');
        } else {
          pendingPoojas.clear();
          print('DEBUG: No pending list found in payload');
        }

        final finished = payload['finished'];
        if (finished is List) {
          finishedPoojas.assignAll(finished);
          print('DEBUG: Loaded ${finishedPoojas.length} finished items');
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
