import 'package:get/get.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';
import 'package:satya_devotte_app/core/services/location_service.dart';
import 'package:satya_devotte_app/core/services/notification_service.dart';
import 'package:satya_devotte_app/core/services/storage_service.dart';
import 'package:satya_devotte_app/core/services/sync_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiClient>(ApiClient(), permanent: true);
    Get.put<FirebaseService>(FirebaseService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<SyncService>(SyncService(), permanent: true);
    Get.put<AuthController>(AuthController(Get.find<FirebaseService>()),
        permanent: true);
  }
}
