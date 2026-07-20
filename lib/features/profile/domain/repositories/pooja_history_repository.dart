import 'package:satya_devotte_app/features/profile/data/datasources/pooja_history_remote_datasource.dart';

class PoojaHistoryRepository {
  PoojaHistoryRepository(this._remoteDataSource);
  final PoojaHistoryRemoteDataSource _remoteDataSource;

  Future<Map<String, dynamic>> getPoojaHistory({String? status, int page = 1}) {
    return _remoteDataSource.getPoojaHistory(status: status, page: page);
  }

  Future<Map<String, dynamic>> getPendingPoojas({int page = 1}) {
    return _remoteDataSource.getPendingPoojas(page: page);
  }

  Future<Map<String, dynamic>> getFinishedPoojas({int page = 1}) {
    return _remoteDataSource.getFinishedPoojas(page: page);
  }

  Future<Map<String, dynamic>> startPooja(String poojaId, {String? scheduleId}) {
    return _remoteDataSource.startPooja(poojaId, scheduleId: scheduleId);
  }

  Future<void> updateProgress(String sessionId, int currentStep) {
    return _remoteDataSource.updateProgress(sessionId, currentStep);
  }

  Future<void> finishPooja(String poojaId, {String? scheduleId}) {
    return _remoteDataSource.finishPooja(poojaId, scheduleId: scheduleId);
  }

  Future<void> finishPoojaBySession(String sessionId) {
    return _remoteDataSource.finishPoojaBySession(sessionId);
  }
}
