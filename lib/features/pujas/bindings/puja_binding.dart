import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/storage_service.dart';
import 'package:satya_devotte_app/core/services/sync_service.dart';
import 'package:satya_devotte_app/features/pujas/data/datasources/puja_local_datasource.dart';
import 'package:satya_devotte_app/features/pujas/data/datasources/puja_remote_datasource.dart';
import 'package:satya_devotte_app/features/pujas/data/repositories/puja_repository_impl.dart';
import 'package:satya_devotte_app/features/pujas/domain/repositories/puja_repository.dart';
import 'package:satya_devotte_app/features/pujas/domain/usecases/get_puja_detail_usecase.dart';
import 'package:satya_devotte_app/features/pujas/domain/usecases/get_pujas_usecase.dart';
import 'package:satya_devotte_app/features/pujas/domain/usecases/sync_pujas_usecase.dart';
import 'package:satya_devotte_app/features/pujas/presentation/controllers/puja_controller.dart';

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
