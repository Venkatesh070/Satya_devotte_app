import 'package:get/get.dart';
import 'package:satya_devotte_app/features/pujas/domain/entities/puja_entity.dart';
import 'package:satya_devotte_app/features/pujas/domain/usecases/get_puja_detail_usecase.dart';
import 'package:satya_devotte_app/features/pujas/domain/usecases/get_pujas_usecase.dart';
import 'package:satya_devotte_app/features/pujas/domain/usecases/sync_pujas_usecase.dart';

class RitualController extends GetxController {
  RitualController(
    this._getRitualsUseCase,
    this._getRitualDetailUseCase,
    this._syncRitualsUseCase,
  );

  final GetRitualsUseCase _getRitualsUseCase;
  final GetRitualDetailUseCase _getRitualDetailUseCase;
  final SyncRitualsUseCase _syncRitualsUseCase;

  final rituals = <RitualEntity>[].obs;
  final selectedRitual = Rxn<RitualEntity>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRituals();
  }

  Future<void> loadRituals({bool forceSync = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      rituals.assignAll(await _getRitualsUseCase(forceSync: forceSync));
    } catch (_) {
      errorMessage.value = 'Unable to load rituals';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRitualDetail(String ritualId) async {
    try {
      isLoading.value = true;
      selectedRitual.value = await _getRitualDetailUseCase(ritualId);
    } catch (_) {
      errorMessage.value = 'Unable to load ritual detail';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncRituals() async {
    await _syncRitualsUseCase();
    await loadRituals(forceSync: true);
  }
}
