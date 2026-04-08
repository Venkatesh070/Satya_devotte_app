import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/storage_service.dart';
import 'package:satya_devotte_app/core/services/sync_service.dart';
import 'package:satya_devotte_app/features/rituals/data/datasources/ritual_local_datasource.dart';
import 'package:satya_devotte_app/features/rituals/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/features/rituals/data/repositories/ritual_repository_impl.dart';
import 'package:satya_devotte_app/features/rituals/domain/repositories/ritual_repository.dart';
import 'package:satya_devotte_app/features/rituals/domain/usecases/get_ritual_detail_usecase.dart';
import 'package:satya_devotte_app/features/rituals/domain/usecases/get_rituals_usecase.dart';
import 'package:satya_devotte_app/features/rituals/domain/usecases/sync_rituals_usecase.dart';
import 'package:satya_devotte_app/features/rituals/presentation/controllers/ritual_controller.dart';

class RitualBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RitualLocalDataSource>(RitualLocalDataSource.new);
    Get.lazyPut<RitualRemoteDataSource>(
      RitualRemoteDataSource.new,
    );
    Get.lazyPut<RitualRepository>(
      () => RitualRepositoryImpl(
        remoteDataSource: Get.find<RitualRemoteDataSource>(),
        localDataSource: Get.find<RitualLocalDataSource>(),
        syncService: Get.find<SyncService>(),
        storageService: Get.find<StorageService>(),
      ),
    );
    Get.lazyPut<GetRitualsUseCase>(
      () => GetRitualsUseCase(Get.find<RitualRepository>()),
    );
    Get.lazyPut<GetRitualDetailUseCase>(
      () => GetRitualDetailUseCase(Get.find<RitualRepository>()),
    );
    Get.lazyPut<SyncRitualsUseCase>(
      () => SyncRitualsUseCase(Get.find<RitualRepository>()),
    );
    Get.lazyPut<RitualController>(
      () => RitualController(
        Get.find<GetRitualsUseCase>(),
        Get.find<GetRitualDetailUseCase>(),
        Get.find<SyncRitualsUseCase>(),
      ),
    );
  }
}
