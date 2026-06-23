// lib/features/cms/presentation/controllers/admin_controller.dart
import 'package:get/get.dart';
import 'package:satya_devotte_app/features/cms/data/datasources/admin_remote_datasource.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';
import 'package:satya_devotte_app/features/cms/models/invite_admin_result.dart';

import 'package:satya_devotte_app/features/cms/presentation/widgets/cms_shared_widgets.dart';

class AdminController extends GetxController {
  AdminController(this._dataSource);
  final AdminRemoteDataSource _dataSource;

  final _admins = <AdminModel>[].obs;
  final _regularUsers = <AdminModel>[].obs;
  final _isLoadingAdmins = false.obs;
  final _isLoadingRegularUsers = false.obs;
  final _isSubmitting = false.obs;
  final _error = RxnString();
  final _adminsPage = 1.obs;
  final _adminsPageSize = 20.obs;
  final _adminsTotal = 0.obs;
  final _adminsTotalPages = 1.obs;
  final _adminsSearch = ''.obs;
  final _regularUsersPage = 1.obs;
  final _regularUsersPageSize = 10.obs;
  final _regularUsersTotal = 0.obs;
  final _regularUsersTotalPages = 1.obs;
  // Admin IDs that are currently mid-flight for the panel-access toggle.
  // The UI watches this set to disable / spin the corresponding switch.
  final _panelAccessPendingIds = <String>{}.obs;
  final _passwordResetPendingIds = <String>{}.obs;

  List<AdminModel> get admins => _admins;
  List<AdminModel> get regularUsers => _regularUsers;
  bool get isLoadingAdmins => _isLoadingAdmins.value;
  bool get isLoadingRegularUsers => _isLoadingRegularUsers.value;
  bool get isLoading => _isLoadingAdmins.value || _isLoadingRegularUsers.value;
  bool get isSubmitting => _isSubmitting.value;
  String? get error => _error.value;
  int get adminsPage => _adminsPage.value;
  int get adminsPageSize => _adminsPageSize.value;
  int get adminsTotal => _adminsTotal.value;
  int get adminsTotalPages => _adminsTotalPages.value;
  String get adminsSearch => _adminsSearch.value;
  int get regularUsersPage => _regularUsersPage.value;
  int get regularUsersPageSize => _regularUsersPageSize.value;
  int get regularUsersTotal => _regularUsersTotal.value;
  int get regularUsersTotalPages => _regularUsersTotalPages.value;
  bool isPanelAccessPending(String id) => _panelAccessPendingIds.contains(id);
  bool isPasswordResetPending(String id) =>
      _passwordResetPendingIds.contains(id);

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
    _error.value = null;
    await Future.wait([loadAdmins(), loadRegularUsers()]);
  }

  Future<void> loadAdmins({
    bool showLoadingIndicator = true,
    int? page,
    int? limit,
    String? search,
  }) async {
    final hadData = _admins.isNotEmpty;
    if (showLoadingIndicator && !hadData) {
      _isLoadingAdmins.value = true;
    }
    _error.value = null;
    final targetPage = page ?? _adminsPage.value;
    final targetLimit = limit ?? _adminsPageSize.value;
    final targetSearch = search ?? _adminsSearch.value;
    try {
      final result = await _dataSource.getAdminUsersPage(
        page: targetPage,
        limit: targetLimit,
        search: targetSearch.trim().isEmpty ? null : targetSearch.trim(),
      );
      _admins.assignAll(
        result.items.where((a) => a.role.toLowerCase() != 'superadmin'),
      );
      _adminsPage.value = result.page;
      _adminsPageSize.value = result.limit;
      _adminsTotal.value = result.total;
      _adminsTotalPages.value = result.totalPages;
      _adminsSearch.value = targetSearch;
    } catch (e) {
      _error.value = _parseError(e);
      print('loadAdmins error: $e');
    } finally {
      _isLoadingAdmins.value = false;
    }
  }

  void setAdminsSearch(String value) {
    if (_adminsSearch.value == value) return;
    loadAdmins(page: 1, search: value);
  }

  Future<void> setAdminsPage(int page) async {
    final target = page.clamp(1, _adminsTotalPages.value);
    if (target == _adminsPage.value) return;
    await loadAdmins(page: target);
  }

  Future<void> setAdminsPageSize(int size) async {
    if (size <= 0 || size == _adminsPageSize.value) return;
    await loadAdmins(page: 1, limit: size);
  }

  Future<void> loadRegularUsers({int? page, int? limit}) async {
    _isLoadingRegularUsers.value = true;
    final targetPage = page ?? _regularUsersPage.value;
    final targetLimit = limit ?? _regularUsersPageSize.value;
    try {
      final result = await _dataSource.getRegularUsersPage(
        page: targetPage,
        limit: targetLimit,
      );
      _regularUsers.assignAll(result.items);
      _regularUsersPage.value = result.page;
      _regularUsersPageSize.value = result.limit;
      _regularUsersTotal.value = result.total;
      _regularUsersTotalPages.value = result.totalPages;
    } catch (e) {
      _error.value = _parseError(e);
      print('loadRegularUsers error: $e');
    } finally {
      _isLoadingRegularUsers.value = false;
    }
  }

  Future<void> setRegularUsersPage(int page) async {
    final target = page.clamp(1, _regularUsersTotalPages.value);
    if (target == _regularUsersPage.value) return;
    await loadRegularUsers(page: target);
  }

  Future<void> setRegularUsersPageSize(int size) async {
    if (size <= 0 || size == _regularUsersPageSize.value) return;
    await loadRegularUsers(page: 1, limit: size);
  }

  /// Invites a new admin via Super Admin API `POST /superadmin/admins`.
  /// Returns result for UI (email sent vs password reset link); `null` on error.
  Future<InviteAdminResult?> inviteAdmin({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    _isSubmitting.value = true;
    _error.value = null;
    try {
      final result = await _dataSource.inviteAdmin(
        fullName: fullName,
        email: email,
        phone: phone,
      );
      await loadAdmins();
      return result;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return null;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // ── Legacy: promote existing user by email (non-invite flow) ──
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

  /// Generates a new password reset link for an existing admin.
  /// Returns the link on success, or `null` if the request failed.
  Future<String?> resendPasswordResetLink(String id) async {
    if (id.trim().isEmpty) {
      _err('Cannot generate reset link: admin id is missing.');
      return null;
    }
    _passwordResetPendingIds.add(id);
    try {
      final link = await _dataSource.resendPasswordResetLink(id);
      _ok('Password reset link generated');
      return link;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return null;
    } finally {
      _passwordResetPendingIds.remove(id);
    }
  }

  /// Toggle whether an admin can sign in to the admin panel.
  /// Performs an optimistic update so the toggle feels instant and reverts
  /// on failure.
  Future<bool> setPanelAccess({
    required String id,
    required bool canLoginAdminPanel,
  }) async {
    final index = _admins.indexWhere((a) => a.id == id);
    if (index == -1) return false;

    final previous = _admins[index];
    if (previous.canLoginAdminPanel == canLoginAdminPanel) return true;

    _admins[index] = previous.copyWith(
      canLoginAdminPanel: canLoginAdminPanel,
    );
    _panelAccessPendingIds.add(id);

    try {
      final updated = await _dataSource.setPanelAccess(
        id: id,
        canLoginAdminPanel: canLoginAdminPanel,
      );
      final freshIndex = _admins.indexWhere((a) => a.id == id);
      if (freshIndex != -1) {
        _admins[freshIndex] = previous.copyWith(
          canLoginAdminPanel: updated.canLoginAdminPanel,
          name: updated.name.isNotEmpty ? updated.name : previous.name,
          email: updated.email.isNotEmpty ? updated.email : previous.email,
          role: updated.role.isNotEmpty ? updated.role : previous.role,
          phone: updated.phone ?? previous.phone,
          profileImage: updated.profileImage ?? previous.profileImage,
          isActive: updated.isActive,
        );
      }
      _ok(
        canLoginAdminPanel
            ? '${previous.displayName} can now access the admin panel'
            : '${previous.displayName} can no longer access the admin panel',
      );
      return true;
    } catch (e) {
      // Revert optimistic update.
      final freshIndex = _admins.indexWhere((a) => a.id == id);
      if (freshIndex != -1) {
        _admins[freshIndex] = previous;
      }
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    } finally {
      _panelAccessPendingIds.remove(id);
    }
  }

  // ── Demote admin → user ───────────────────────────────────────
  Future<bool> removeAdmin(String id) async {
    try {
      await _dataSource.removeAdmin(id);
      _ok('Admin removed');
      // Reload both lists fresh from server
      await loadAll();
      return true;
    } catch (e) {
      _error.value = _parseError(e);
      _err(_error.value!);
      return false;
    }
  }

  void _ok(String msg) => showCmsSnackbar(title: 'Success', message: msg);

  void _err(String msg) =>
      showCmsSnackbar(title: 'Error', message: msg, isError: true);

  String _parseError(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) {
      return s.substring('Exception: '.length);
    }
    if (s.contains('404')) return 'User not found.';
    if (s.contains('401') || s.contains('403')) return 'Not authorised.';
    if (s.contains('500')) return 'Server error. Try again.';
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
