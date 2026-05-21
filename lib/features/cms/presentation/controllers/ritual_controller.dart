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

  List<RitualModel> get rituals => _rituals;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  String get filter => _filter.value;
  String get search => _search.value;
  List<Map<String, String>> get deities => _deities;

  void setSearch(String q) => _search.value = q.trim().toLowerCase();

  List<RitualModel> get filteredRituals {
    var list = _rituals.toList();
    if (_filter.value != 'All') {
      list = list
          .where((r) => r.status == _filter.value.toUpperCase())
          .toList();
    }
    final q = _search.value;
    if (q.isNotEmpty) {
      list = list
          .where(
            (r) =>
                r.title.toLowerCase().contains(q) ||
                (r.slug ?? '').toLowerCase().contains(q) ||
                (r.category ?? '').toLowerCase().contains(q) ||
                (r.purpose ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async {
      await loadRituals(showErrorSnackbar: false);
      await loadDeities();
    });
  }

  void setFilter(String f) => _filter.value = f;

  Future<void> loadRituals({bool showErrorSnackbar = true}) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final auth = Get.find<AuthController>();
      List<RitualModel> result;
      if (auth.isSuperAdmin) {
        result = await _dataSource.getAllRitualsSuperAdmin();
      } else {
         result = await _dataSource.getAllRitualsSuperAdmin();
      }
      _rituals.assignAll(result);
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
    try {
      final result = await _poojaDataSource.getDeities();
      _deities.assignAll(result);
    } catch (_) {}
  }

  Future<bool> createRitual({
    required String title,
    required String deity,
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
        deity: deity,
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
