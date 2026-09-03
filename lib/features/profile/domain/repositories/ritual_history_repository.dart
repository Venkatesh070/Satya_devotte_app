import 'package:satya_devotte_app/features/profile/data/datasources/ritual_history_remote_datasource.dart';

class RitualHistoryRepository {
  RitualHistoryRepository(this._remoteDataSource);
  final RitualHistoryRemoteDataSource _remoteDataSource;

  Future<Map<String, dynamic>> getRitualHistory({
    String? status,
    int page = 1,
    bool skipLoader = false,
  }) {
    return _remoteDataSource.getRitualHistory(
      status: status,
      page: page,
      skipLoader: skipLoader,
    );
  }

  Future<Map<String, dynamic>> getSession(String sessionId) {
    return _remoteDataSource.getSession(sessionId);
  }

  Future<Map<String, dynamic>> startRitual(String ritualId) {
    return _remoteDataSource.startRitual(ritualId);
  }

  Future<Map<String, dynamic>> startDay(String sessionId) {
    return _remoteDataSource.startDay(sessionId);
  }

  Future<void> updateProgress(
    String sessionId, {
    required int currentStep,
    int? currentDay,
  }) {
    return _remoteDataSource.updateProgress(
      sessionId,
      currentStep: currentStep,
      currentDay: currentDay,
    );
  }

  Future<Map<String, dynamic>> completeDay(String sessionId) {
    return _remoteDataSource.completeDay(sessionId);
  }

  Future<void> finishRitual(String ritualId) {
    return _remoteDataSource.finishRitual(ritualId);
  }

  Future<void> finishRitualBySession(String sessionId) {
    return _remoteDataSource.finishRitualBySession(sessionId);
  }
}
