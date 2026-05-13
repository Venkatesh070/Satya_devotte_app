import 'package:satya_devotte_app/core/services/storage_service.dart';
import 'package:satya_devotte_app/core/services/sync_service.dart';
import 'package:satya_devotte_app/features/pujas/data/datasources/puja_local_datasource.dart';
import 'package:satya_devotte_app/features/pujas/data/datasources/puja_remote_datasource.dart';
import 'package:satya_devotte_app/features/pujas/data/models/puja_model.dart';
import 'package:satya_devotte_app/features/pujas/domain/entities/puja_entity.dart';
import 'package:satya_devotte_app/features/pujas/domain/repositories/puja_repository.dart';

class RitualRepositoryImpl implements RitualRepository {
  RitualRepositoryImpl({
    required RitualRemoteDataSource remoteDataSource,
    required RitualLocalDataSource localDataSource,
    required SyncService syncService,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncService = syncService,
        _storageService = storageService;

  final RitualRemoteDataSource _remoteDataSource;
  final RitualLocalDataSource _localDataSource;
  final SyncService _syncService;
  final StorageService _storageService;

  @override
  Future<List<RitualEntity>> getRituals({bool forceSync = false}) async {
    final local = await _localDataSource.getRituals();
    final online = await _syncService.hasConnection();
    if (!forceSync && local.isNotEmpty) {
      return local;
    }
    if (!online) {
      return local;
    }
    final remote = await _remoteDataSource.getRituals();
    await _localDataSource.saveRituals(remote);
    return remote;
  }

  @override
  Future<RitualEntity?> getRitualDetail(String ritualId) async {
    final local = await _localDataSource.getRitualDetail(ritualId);
    if (local != null) {
      return local;
    }
    return _remoteDataSource.getRitualDetail(ritualId);
  }

  @override
  Future<void> syncRituals() async {
    final remote = await _remoteDataSource.getRituals();
    await _localDataSource.saveRituals(remote);
  }

  Future<RitualModel> downloadMedia(RitualModel model) async {
    if (model.mediaUrl.isNotEmpty) {
      await _storageService.cacheFile(model.mediaUrl);
      return model.copyWith(offlineAvailable: true);
    }
    return model;
  }
}
