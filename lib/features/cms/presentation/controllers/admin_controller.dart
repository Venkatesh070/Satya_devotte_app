// lib/features/cms/presentation/controllers/admin_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/admin_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';

class AdminController extends GetxController {
  AdminController(this._dataSource);
  final AdminRemoteDataSource _dataSource;

  final _admins = <AdminModel>[].obs;
  final _regularUsers = <AdminModel>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();

  List<AdminModel> get admins => _admins;
  List<AdminModel> get regularUsers => _regularUsers;
  bool get isLoading => _isLoading.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  // ── Load both lists ───────────────────────────────────────────
  Future<void> loadAll() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final results = await Future.wait([
        _dataSource.getAdminUsers(),
        _dataSource.getRegularUsers(),
      ]);
      _admins.assignAll(results[0]);
      _regularUsers.assignAll(results[1]);
    } catch (e) {
      _error.value = _parseError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadAdmins() async {
    try {
      final result = await _dataSource.getAdminUsers();
      _admins.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
    }
  }

  Future<void> loadRegularUsers() async {
    try {
      final result = await _dataSource.getRegularUsers();
      _regularUsers.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
    }
  }

  // ── Promote user → admin ──────────────────────────────────────
  Future<bool> promoteToAdmin(String emailOrId) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.createAdmin(emailOrId);
      // Move from regularUsers to admins
      _regularUsers.removeWhere(
        (u) => u.id == result.id || u.email == result.email,
      );
      // Add to admins if not already there
      if (!_admins.any((a) => a.id == result.id)) {
        _admins.insert(0, result);
      }
      _ok('${result.displayName} promoted to Admin');
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── Demote admin → user ───────────────────────────────────────
  Future<bool> removeAdmin(String id) async {
    try {
      final result = await _dataSource.removeAdmin(id);
      // Remove from admins list
      _admins.removeWhere((a) => a.id == id);
      // Add back to regular users
      if (!_regularUsers.any((u) => u.id == id)) {
        _regularUsers.insert(0, result);
      }
      _ok('Admin role removed');
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
    if (m.contains('404')) return 'User not found.';
    if (m.contains('401') || m.contains('403')) return 'Not authorised.';
    if (m.contains('500')) return 'Server error. Try again.';
    if (m.contains('SocketException') || m.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
