import 'package:get/get.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';
import 'package:satya_devotte_app/core/services/location_service.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/core/services/notification_service.dart';
import 'package:satya_devotte_app/core/services/storage_service.dart';
import 'package:satya_devotte_app/core/services/sync_service.dart';
import 'package:satya_devotte_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:satya_devotte_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:satya_devotte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/controllers/forgot_password_controller.dart';
import 'package:satya_devotte_app/services/auth_service.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/pooja_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/admin_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/festival_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/deity_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/donation_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/sloka_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/product_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/donation_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/admin_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/sloka_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/festival_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/deity_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/pooja_controller.dart';
import 'package:satya_devotte_app/features/cms/presentation/controllers/product_controller.dart';
import 'package:satya_devotte_app/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:satya_devotte_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<FirebaseService>(FirebaseService(), permanent: true);
    Get.put<AuthSessionService>(AuthSessionService(), permanent: true);
    Get.put<ApiClient>(
      ApiClient(
        tokenProvider: () => Get.find<AuthSessionService>().getAccessToken(),
      ),
      permanent: true,
    );
    Get.put<AuthRemoteDataSource>(
      AuthRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<AuthRepository>(
      AuthRepositoryImpl(Get.find<AuthRemoteDataSource>()),
      permanent: true,
    );
    Get.put<NotificationService>(NotificationService(), permanent: true);
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<SyncService>(SyncService(), permanent: true);
    Get.put<AuthController>(
      AuthController(
        Get.find<FirebaseService>(),
        Get.find<AuthRepository>(),
        Get.find<AuthSessionService>(),
      ),
      permanent: true,
    );
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.lazyPut<ForgotPasswordController>(
      () => ForgotPasswordController(Get.find<AuthService>()),
      fenix: true,
    );
    Get.put<ProfileRemoteDataSource>(
      ProfileRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<ProfileRepository>(
      ProfileRepositoryImpl(Get.find<ProfileRemoteDataSource>()),
      permanent: true,
    );
    Get.put<ProfileController>(
      ProfileController(
        Get.find<ProfileRepository>(),
        Get.find<AuthSessionService>(),
      ),
      permanent: true,
    );
    Get.put<PoojaRemoteDataSource>(
      PoojaRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<PoojaController>(
      PoojaController(Get.find<PoojaRemoteDataSource>()),
      permanent: true,
    );
    // ── CMS Festivals ────────────────────────────────────────────
    Get.put<FestivalRemoteDataSource>(
      FestivalRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<FestivalController>(
      FestivalController(Get.find<FestivalRemoteDataSource>()),
      permanent: true,
    );
    Get.put<DeityRemoteDataSource>(
      DeityRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<DeityController>(
      DeityController(Get.find<DeityRemoteDataSource>()),
      permanent: true,
    );
    // ── CMS Admins ───────────────────────────────────────────────
    Get.put<AdminRemoteDataSource>(
      AdminRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<AdminController>(
      AdminController(Get.find<AdminRemoteDataSource>()),
      permanent: true,
    );
    // ── CMS Daily Slokas ─────────────────────────────────────────
    Get.put<SlokaRemoteDataSource>(
      SlokaRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<SlokaController>(
      SlokaController(Get.find<SlokaRemoteDataSource>()),
      permanent: true,
    );
    // ── CMS Donations ─────────────────────────────────────────────
    Get.put<DonationRemoteDataSource>(
      DonationRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<DonationController>(
      DonationController(Get.find<DonationRemoteDataSource>()),
      permanent: true,
    );
    // ── CMS Pooja Kit Products ───────────────────────────────────
    Get.put<ProductRemoteDataSource>(
      ProductRemoteDataSource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.lazyPut<ProductController>(
      () => ProductController(Get.find<ProductRemoteDataSource>()),
      fenix: true,
    );
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<MediaUploadService>(
      MediaUploadService(),
      permanent: true,
    ); // ← add this
    Get.put<LocationService>(LocationService(), permanent: true);
  }
}
