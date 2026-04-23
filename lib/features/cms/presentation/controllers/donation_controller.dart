import 'package:satya_devotte_app/core/services/media_upload_service.dart';
// lib/features/cms/presentation/controllers/donation_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/donation_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/donation_model.dart';

class DonationController extends GetxController {
  DonationController(this._dataSource);
  final DonationRemoteDataSource _dataSource;

  final _donations = <DonationModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _filter = 'All'.obs;

  List<DonationModel> get donations => _donations;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  String get filter => _filter.value;

  List<DonationModel> get filteredDonations {
    if (_filter.value == 'All') return _donations.toList();
    return _donations.where((d) => d.status == _filter.value).toList();
  }

  int get pendingCount => _donations.where((d) => d.status == 'Pending').length;
  int get queuedCount => _donations.where((d) => d.status == 'Queued').length;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(loadDonations);
  }

  void setFilter(String f) => _filter.value = f;

  // ── LOAD ──────────────────────────────────────────────────────
  Future<void> loadDonations() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final auth = Get.find<AuthController>();
      final result = auth.isSuperAdmin
          ? await _dataSource.getAllDonations()
          : await _dataSource.getMyDonations();
      _donations.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  // ── CREATE ────────────────────────────────────────────────────
  Future<bool> createDonation({
    required String title,
    String description = '',
    PickedFile? image,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.createDonation(
        title: title,
        description: description,
        image: image,
      );
      await loadDonations();
      _ok('Donation submitted for review');
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
  Future<bool> updateDonation(
    String id,
    String title,
    String description,
    {PickedFile? image}
  ) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      await _dataSource.updateDonation(
        id,
        title,
        description,
        image: image,
      );
      await loadDonations();
      _ok('Donation updated — sent for re-approval');
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
  Future<bool> deleteDonation(String id) async {
    try {
      await _dataSource.deleteDonation(id);
      _donations.removeWhere((d) => d.id == id);
      _ok('Donation deleted');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  // ── APPROVE ───────────────────────────────────────────────────
  Future<bool> approveDonation(String id) async {
    try {
      final result = await _dataSource.reviewDonation(id, 'APPROVED');
      final idx = _donations.indexWhere((d) => d.id == id);
      if (idx != -1) _donations[idx] = result;
      _ok('Donation approved and published');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  Future<bool> queueDonation(String id) async {
    try {
      final result = await _dataSource.reviewDonation(id, 'QUEUED');
      final idx = _donations.indexWhere((d) => d.id == id);
      if (idx != -1) _donations[idx] = result;
      _ok('Donation moved to queue');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  // ── REJECT ────────────────────────────────────────────────────
  Future<bool> rejectDonation(String id, String reason) async {
    try {
      await _dataSource.reviewDonation(id, 'REJECTED', reason: reason);
      await loadDonations();
      _ok('Donation rejected');
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
    if (m.contains('404')) return 'Donation not found.';
    if (m.contains('401') || m.contains('403')) return 'Not authorised.';
    if (m.contains('500')) return 'Server error. Try again.';
    if (m.contains('SocketException') || m.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
