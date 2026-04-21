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
    // FIX: Removed Future.microtask(loadAll) from here.
    //
    // Previously this controller was registered with Get.put() in InitialBinding,
    // which meant onInit fired at app startup — before the user logged in and
    // before the auth token was available. The microtask ran immediately with a
    // null token, the API call failed silently, and data never appeared until a
    // manual refresh triggered loadAll() again.
    //
    // Now the controller is registered with Get.lazyPut(fenix: true), so onInit
    // only runs the first time Get.find<AdminController>() is called, which
    // happens when CmsAdminsContent is built — at that point the user is already
    // authenticated. loadAll() is called from CmsAdminsContent.initState() via
    // WidgetsBinding.addPostFrameCallback, giving full control to the UI layer.
  }

  // ── Load both lists independently so one failure doesn't block the other ──
  Future<void> loadAll() async {
    _isLoading.value = true;
    _error.value = null;
    await Future.wait([loadAdmins(), loadRegularUsers()]);
    _isLoading.value = false;
  }

  Future<void> loadAdmins() async {
    try {
      final result = await _dataSource.getAdminUsers();
      _admins.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
      print('loadAdmins error: $e');
    }
  }

  Future<void> loadRegularUsers() async {
    try {
      final result = await _dataSource.getRegularUsers();
      _regularUsers.assignAll(result);
    } catch (e) {
      _error.value = _parseError(e);
      print('loadRegularUsers error: $e');
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
      await _dataSource.removeAdmin(id);
      _ok('Admin role removed');
      // Reload both lists fresh from server
      await loadAll();
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
