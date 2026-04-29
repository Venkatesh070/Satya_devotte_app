// lib/features/cms/presentation/controllers/sloka_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/media_upload_service.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/sloka_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/sloka_model.dart';

class SlokaController extends GetxController {
  SlokaController(this._dataSource);
  final SlokaRemoteDataSource _dataSource;

  final _slokas = <SlokaModel>[].obs;
  final _todaySloka = Rxn<SlokaModel>();
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _selectedDate = DateTime.now().obs;

  List<SlokaModel> get slokas => _slokas;
  SlokaModel? get todaySloka => _todaySloka.value;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  DateTime get selectedDate => _selectedDate.value;

  // Format as DD-MM-YYYY (what the API expects)
  String get selectedDateStr => SlokaModel.formatDate(_selectedDate.value);

  @override
  void onInit() {
    super.onInit();
    // FIX: Removed duplicate @override and Future.microtask(loadAll) from here.
    //
    // Previously this controller was registered with Get.put() in InitialBinding,
    // so onInit fired at app startup before the user authenticated. The microtask
    // ran with a null token, the API call failed silently, and slokas never
    // appeared until a manual refresh.
    //
    // Now the controller uses Get.lazyPut(fenix: true) in InitialBinding, so
    // onInit only runs when CmsShlokaContent is first built (user already logged
    // in). loadAll() is called from CmsShlokaContent.initState() via
    // WidgetsBinding.addPostFrameCallback.
  }

  void setDate(DateTime d) {
    _selectedDate.value = d;
    loadSlokaForDate(SlokaModel.formatDate(d));
  }

  Future<void> loadAll() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final list = await _dataSource.getRecentSlokas();
      _slokas.assignAll(list);
      // Also load for selected date
      _todaySloka.value = await _dataSource.getSlokaByDate(selectedDateStr);
    } catch (e) {
      _error.value = _parseError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadSlokaForDate(String date) async {
    _isLoading.value = true;
    try {
      _todaySloka.value = await _dataSource.getSlokaByDate(date);
    } catch (e) {
      _error.value = _parseError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // ── Save sloka — POST { sloka, author, date } ─────────────────
  Future<bool> saveSloka({
    required String sloka,
    required String author,
    String? meaning,
    String? contemplation,
    String? prayer,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final model = SlokaModel(
        id: _todaySloka.value?.id ?? '',
        sloka: sloka,
        author: author,
        meaning: meaning,
        contemplation: contemplation,
        prayer: prayer,
        date: selectedDateStr, // DD-MM-YYYY
      );
      final result = await _dataSource.createOrUpdateSloka(model);
      _todaySloka.value = result;
      final idx = _slokas.indexWhere((s) => s.date == result.date);
      if (idx != -1)
        _slokas[idx] = result;
      else
        _slokas.insert(0, result);
      _ok(_todaySloka.value != null ? 'Sloka updated' : 'Sloka saved');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<bool> bulkImportSlokas(PickedFile file) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.bulkImportSlokas(file);
      await loadAll();
      _ok('Slokas imported successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
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
    if (m.contains('404')) return 'Sloka not found.';
    if (m.contains('401') || m.contains('403')) return 'Not authorised.';
    if (m.contains('500')) return 'Server error. Try again.';
    if (m.contains('SocketException') || m.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
