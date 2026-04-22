// lib/features/cms/presentation/controllers/festival_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/festival_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/festival_model.dart';

class FestivalController extends GetxController {
  FestivalController(this._dataSource);
  final FestivalRemoteDataSource _dataSource;

  final _festivals = <FestivalModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _filter = 'All'.obs;
  final _selectedMonth = DateTime.now().month.obs;

  List<FestivalModel> get festivals => _festivals;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  String get filter => _filter.value;
  int get selectedMonth => _selectedMonth.value;

  List<FestivalModel> get filteredFestivals {
    var list = _festivals.toList();
    if (_filter.value != 'All') {
      list = list
          .where((f) => f.status.toLowerCase() == _filter.value.toLowerCase())
          .toList();
    }
    return list;
  }

  List<FestivalModel> get festivalsByMonth {
    final auth = Get.find<AuthController>();
    // SuperAdmin sees ALL months always — month picker is for admin only
    if (auth.isSuperAdmin) return filteredFestivals;
    // Admin — filter by selected month
    return filteredFestivals
        .where((f) => f.monthNumber == _selectedMonth.value)
        .toList();
  }

  int get pendingCount => _festivals.where((f) => f.status == 'Pending').length;

  @override
  @override
  void onInit() {
    super.onInit();
    Future.microtask(loadFestivals);
  }

  void setFilter(String f) => _filter.value = f;
  void setMonth(int m) => _selectedMonth.value = m;

  // ── LOAD ──────────────────────────────────────────────────────
  Future<void> loadFestivals() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final auth = Get.find<AuthController>();
      final result = auth.isSuperAdmin
          ? await _dataSource.getAllFestivals()
          : await _dataSource.getMyFestivals();
      _festivals.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // ── CREATE ────────────────────────────────────────────────────
  Future<bool> createFestival(Map<String, dynamic> body) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.createFestival(body);
      await loadFestivals();
      _ok('Festival submitted for review');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────
  Future<bool> updateFestival(String id, Map<String, dynamic> body) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.updateFestival(id, body);
      await loadFestivals();
      _ok('Festival updated');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────
  Future<bool> deleteFestival(String id) async {
    try {
      await _dataSource.deleteFestival(id);
      _festivals.removeWhere((f) => f.id == id);
      _ok('Festival deleted');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  // ── APPROVE ───────────────────────────────────────────────────
  Future<bool> approveFestival(String id) async {
    try {
      final result = await _dataSource.reviewFestival(id, 'APPROVED');
      final idx = _festivals.indexWhere((f) => f.id == id);
      if (idx != -1) _festivals[idx] = result;
      _ok('Festival approved and published');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  // ── REJECT ────────────────────────────────────────────────────
  Future<bool> rejectFestival(String id, String reason) async {
    try {
      await _dataSource.reviewFestival(id, 'REJECTED', reason: reason);
      _festivals.removeWhere((f) => f.id == id);
      _ok('Festival rejected');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  void _ok(String msg) => Get.snackbar(
    'Success',
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFF4CAF50),
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
  );

  void _err(String msg) => Get.snackbar(
    'Error',
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFFE53935),
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
  );

  String _parseError(Object e) {
    final m = e.toString();
    if (m.contains('404')) return 'Festival not found.';
    if (m.contains('401') || m.contains('403')) return 'Not authorised.';
    if (m.contains('500')) return 'Server error. Try again.';
    if (m.contains('SocketException') || m.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
