// lib/features/cms/presentation/controllers/ritual_controller.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/ritual_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/pooja_remote_datasource.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/models/ritual_model.dart';
import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class RitualController extends GetxController {
  RitualController(this._dataSource, this._poojaDataSource);
  final RitualRemoteDataSource _dataSource;
  final PoojaRemoteDataSource _poojaDataSource;

  final _rituals = <RitualModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _filter = 'All'.obs;
  final _search = ''.obs;
  final _deities = <Map<String, String>>[].obs;
  final _isLoadingDeities = false.obs;
  final _deitiesLoaded = false.obs;
  final _page = 1.obs;
  final _limit = 10.obs;
  final _total = 0.obs;
  final _totalPages = 1.obs;

  List<RitualModel> get rituals => _rituals;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  String get filter => _filter.value;
  String get search => _search.value;
  int get page => _page.value;
  int get limit => _limit.value;
  int get total => _total.value;
  int get totalPages => _totalPages.value;
  List<Map<String, String>> get deities => _deities;
  bool get isLoadingDeities => _isLoadingDeities.value;
  bool get deitiesLoaded => _deitiesLoaded.value;

  void setSearch(String value) {
    final q = value.trim();
    if (_search.value == q) return;
    _search.value = q;
    loadRituals(page: 1);
  }

  List<RitualModel> get filteredRituals => _rituals.toList();

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      await loadRituals(showErrorSnackbar: false);
      await loadDeities();
    });
  }

  void setFilter(String f) {
    if (_filter.value == f) return;
    _filter.value = f;
    loadRituals(page: 1);
  }

  Future<void> goToPage(int target) async {
    final p = target.clamp(1, _totalPages.value);
    if (p == _page.value && _rituals.isNotEmpty) return;
    await loadRituals(page: p);
  }

  Future<void> setPageSize(int size) async {
    if (size <= 0 || size == _limit.value) return;
    _limit.value = size;
    await loadRituals(page: 1);
  }

  Future<void> loadRituals({bool showErrorSnackbar = true, int? page}) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final auth = Get.find<AuthController>();
      final status =
          _filter.value == 'All' ? null : _filter.value.toUpperCase();
      final result = await _dataSource.getRitualsPage(
        superAdmin: auth.isSuperAdmin,
        page: page ?? _page.value,
        limit: _limit.value,
        status: status,
        search: _search.value.trim().isEmpty ? null : _search.value.trim(),
      );
      _rituals.assignAll(result.items);
      _page.value = result.page;
      _limit.value = result.limit;
      _total.value = result.total;
      _totalPages.value = result.totalPages;
    } catch (e) {
      _error.value = _parseError(e);
      if (showErrorSnackbar) {
        showCmsSnackbar(
          title: 'Error',
          message: 'Failed to load rituals: ${_error.value}',
          isError: true,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadDeities() async {
    if (_isLoadingDeities.value) return;
    _isLoadingDeities.value = true;
    try {
      final result = await _poojaDataSource.getDeities(status: 'APPROVED');
      _deities.assignAll(result);
    } catch (_) {
      _deities.clear();
    } finally {
      _isLoadingDeities.value = false;
      _deitiesLoaded.value = true;
    }
  }

  Future<bool> createRitual({
    required String title,
    required List<String> deities,
    required String description,
    required List<RitualDay> days,
    required List<RitualSection> sections,
    String? slug,
    String? category,
    String? purpose,
    String? startingDay,
    int? ritualDays,
    String? bestDayTime,
    String accessType = 'FREE',
    num price = 0,
    String currency = 'ZAR',
    String difficulty = 'BEGINNER',
    bool isFeatured = false,
    String status = 'PENDING',
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final ritual = RitualModel(
        id: '',
        title: title,
        slug: slug,
        deities: deities,
        description: description,
        days: days,
        sections: sections,
        category: category,
        purpose: purpose,
        startingDay: startingDay,
        ritualDays: ritualDays ?? days.length,
        bestDayTime: bestDayTime,
        accessType: accessType,
        price: price,
        currency: currency,
        difficulty: difficulty,
        isFeatured: isFeatured,
        status: status,
      );
      final created = await _dataSource.createRitual(
        ritual,
        image: image,
        audio: audio,
        video: video,
      );
      _rituals.insert(0, created);
      showCmsSnackbar(title: 'Success', message: 'Ritual created successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to create ritual: ${_error.value}',
        isError: true,
      );
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<bool> updateRitual(
    String id,
    RitualModel updated, {
    PickedFile? image,
    PickedFile? audio,
    PickedFile? video,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.updateRitual(
        id,
        updated,
        image: image,
        audio: audio,
        video: video,
      );
      final index = _rituals.indexWhere((r) => r.id == id);
      if (index != -1) {
        _rituals[index] = result;
      }
      showCmsSnackbar(title: 'Success', message: 'Ritual updated successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to update ritual: ${_error.value}',
        isError: true,
      );
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<bool> deleteRitual(String id) async {
    try {
      await _dataSource.deleteRitual(id);
      _rituals.removeWhere((r) => r.id == id);
      showCmsSnackbar(title: 'Success', message: 'Ritual deleted successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to delete ritual: ${_error.value}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> approveRitual(String id) async {
    try {
      await _dataSource.reviewRitual(id, 'APPROVED');
      showCmsSnackbar(title: 'Success', message: 'Ritual approved');
      await loadRituals();
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to approve ritual: ${_error.value}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> rejectRitual(String id, String reason) async {
    try {
      await _dataSource.reviewRitual(id, 'REJECTED');
      showCmsSnackbar(title: 'Success', message: 'Ritual rejected');
      await loadRituals();
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      showCmsSnackbar(
        title: 'Error',
        message: 'Failed to reject ritual: ${_error.value}',
        isError: true,
      );
      return false;
    }
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return e.toString();
  }
}
