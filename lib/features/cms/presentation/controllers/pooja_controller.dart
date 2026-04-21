import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/pooja_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/pooja_model.dart';

class PoojaController extends GetxController {
  PoojaController(this._dataSource);
  final PoojaRemoteDataSource _dataSource;

  // ── State ────────────────────────────────────────────────────
  final _poojas = <PoojaModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _filter = 'All'.obs;

  List<PoojaModel> get poojas => _poojas;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  String get filter => _filter.value;

  // Client-side filter applied on top of whatever is in _poojas.
  // This ensures the UI is always correct whether data came from
  // loadPoojas() (filtered) or loadAllPoojas() (all statuses).
  List<PoojaModel> get filteredPoojas {
    if (_filter.value == 'All') return _poojas;
    return _poojas.where((p) => p.status == _filter.value).toList();
  }

  // Pending poojas count — shown on dashboard (best-effort across current list)
  int get pendingCount => _poojas.where((p) => p.status == 'Pending').length;

  @override
  void onInit() {
    super.onInit();
    loadPoojas();
  }

  // ── Set filter → fetch from server with status param ─────────
  void setFilter(String f) {
    _filter.value = f;
    loadPoojas();
  }

  /// Called when entering Manage Poojas tab — resets to All and reloads.
  /// Use this instead of setFilter('All') when navigating back from Approvals
  /// so stale loadAllPoojas data is replaced with properly filtered data.
  void resetAndLoad() {
    _filter.value = 'All';
    loadPoojas();
  }

  // ── Load all poojas (filtered by _filter.value) ──────────────
  Future<void> loadPoojas() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final status = _filter.value == 'All' ? null : _filter.value;
      final result = await _dataSource.getAllPoojas(status: status);
      _poojas.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load ALL poojas regardless of active filter — used by super admin Approvals tab.
  Future<void> loadAllPoojas() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.getAllPoojas(); // no status param
      _poojas.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // ── Create pooja ─────────────────────────────────────────────
  Future<bool> createPooja({
    required String title,
    required String deity,
    required String category,
    required String difficulty,
    required String duration,
    required String description,
    required List<String> steps,
    required List<String> requiredItems,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
    String status = 'Pending',
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final pooja = PoojaModel(
        id: '',
        title: title,
        deity: deity,
        category: category,
        difficulty: difficulty,
        duration: duration,
        description: description,
        status: status,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        videoUrl: videoUrl,
        steps: steps,
        requiredItems: requiredItems,
      );
      final created = await _dataSource.createPooja(pooja);
      // Only insert into current list if it matches the active filter
      if (_filter.value == 'All' || _filter.value == created.status) {
        _poojas.insert(0, created);
      }
      _snackOk('Pooja submitted successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _snackErr(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── Update pooja ─────────────────────────────────────────────
  Future<bool> updatePooja(String id, PoojaModel updated) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.updatePooja(id, updated);
      final index = _poojas.indexWhere((p) => p.id == id);
      if (index != -1) {
        // If status changed and no longer matches filter, drop it
        if (_filter.value != 'All' && result.status != _filter.value) {
          _poojas.removeAt(index);
        } else {
          _poojas[index] = result;
        }
      }
      _snackOk('Pooja updated successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _snackErr(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── Delete pooja ─────────────────────────────────────────────
  Future<bool> deletePooja(String id) async {
    try {
      await _dataSource.deletePooja(id);
      _poojas.removeWhere((p) => p.id == id);
      _snackOk('Pooja deleted successfully');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _snackErr(_error.value!);
      return false;
    }
  }

  // ── Approve pooja (superadmin) ───────────────────────────────
  Future<bool> approvePooja(String id) async {
    try {
      final result = await _dataSource.approvePooja(id);
      final index = _poojas.indexWhere((p) => p.id == id);
      if (index != -1) {
        // Use API result if valid, otherwise patch status locally
        _poojas[index] = result.status.isNotEmpty
            ? result
            : _poojas[index].copyWith(status: 'Published');
      }
      _snackOk('Pooja approved and published');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _snackErr(_error.value!);
      return false;
    }
  }

  // ── Reject pooja (superadmin) ────────────────────────────────
  Future<bool> rejectPooja(String id, String reason) async {
    try {
      await _dataSource.rejectPooja(id, reason);
      // Remove from list immediately — rejected goes back to admin
      _poojas.removeWhere((p) => p.id == id);
      _snackOk('Pooja rejected and sent back to admin');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _snackErr(_error.value!);
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  void _snackOk(String msg) => Get.snackbar(
    'Success',
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFF4CAF50),
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
  );

  void _snackErr(String msg) => Get.snackbar(
    'Error',
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFFE53935),
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
  );

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('404')) return 'Pooja not found.';
    if (msg.contains('401') || msg.contains('403')) return 'Not authorised.';
    if (msg.contains('500')) return 'Server error. Please try again.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
