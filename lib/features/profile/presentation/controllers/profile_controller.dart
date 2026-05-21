import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:satya_devotte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:satya_devotte_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._profileRepository, this._authSessionService);

  final ProfileRepository _profileRepository;
  final AuthSessionService _authSessionService;

  final _isLoading = false.obs;
  final _profile = Rxn<Map<String, dynamic>>();
  final _error = RxnString();
  final _sessionUser = Rxn<Map<String, dynamic>>();

  bool get isLoading => _isLoading.value;
  Map<String, dynamic>? get profile => _profile.value;
  String? get error => _error.value;
  Map<String, dynamic>? get sessionUser => _sessionUser.value;

  /// Best-effort display name from login/session user or GET /profile payload.
  static String displayNameFromUserMap(Map<String, dynamic>? u) {
    if (u == null || u.isEmpty) return 'User';
    String? t(dynamic v) {
      final s = v?.toString().trim();
      if (s == null || s.isEmpty) return null;
      return s;
    }

    String? fromFirstLast() {
      final fn = t(u['firstName']);
      final ln = t(u['lastName']);
      if (fn == null && ln == null) return null;
      return '${fn ?? ''} ${ln ?? ''}'.trim();
    }

    String? fromEmail() {
      final email = t(u['email']);
      if (email == null) return null;
      final at = email.indexOf('@');
      if (at <= 0) return email;
      return email.substring(0, at);
    }

    return t(u['fullName']) ??
        t(u['name']) ??
        t(u['displayName']) ??
        fromFirstLast() ??
        fromEmail() ??
        'User';
  }

  /// Session user merged with GET /profile user (profile wins on duplicate keys).
  Map<String, dynamic>? get resolvedUser => _mergedUserPayload;

  Map<String, dynamic>? get _mergedUserPayload {
    final session = _sessionUser.value;
    final root = _profile.value;
    Map<String, dynamic>? fromProfile;
    if (root != null) {
      final u = root['user'];
      if (u is Map<String, dynamic>) {
        fromProfile = u;
      } else {
        final data = root['data'];
        if (data is Map<String, dynamic>) {
          final du = data['user'];
          if (du is Map<String, dynamic>) {
            fromProfile = du;
          } else {
            fromProfile = data;
          }
        } else {
          fromProfile = root;
        }
      }
    }
    if ((session == null || session.isEmpty) &&
        (fromProfile == null || fromProfile.isEmpty)) {
      return null;
    }
    final merged = <String, dynamic>{};
    if (session != null && session.isNotEmpty) merged.addAll(session);
    if (fromProfile != null && fromProfile.isNotEmpty)
      merged.addAll(fromProfile);
    return merged.isEmpty ? null : merged;
  }

  String get userName {
    final name = displayNameFromUserMap(_mergedUserPayload);
    if (name != 'User') return name;
    return 'Devotee';
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(loadSessionUser());
    unawaited(_maybeLoadProfile());
  }

  /// Admin/superadmin CMS on web uses login session data only — not `/auth/profile`.
  Future<bool> _shouldSkipProfileApi() async {
    if (!kIsWeb) return false;

    await _authSessionService.getUserData();
    if (_authSessionService.isAdmin) return true;

    if (Get.isRegistered<AuthController>() && Get.find<AuthController>().isAdmin) {
      return true;
    }

    final route = Get.currentRoute;
    return route == AppRoutes.cms || route.startsWith('${AppRoutes.cms}/');
  }

  Future<void> _maybeLoadProfile() async {
    if (await _shouldSkipProfileApi()) return;
    await loadProfile();
  }

  Future<void> loadSessionUser() async {
    final user = await _authSessionService.getUserData();
    _sessionUser.value = user;
    update();
  }

  /// Clears cached user after logout so UI (e.g. home greeting) resets.
  void clearCachedUser() {
    _sessionUser.value = null;
    _profile.value = null;
    _error.value = null;
    update();
  }

  Future<void> loadProfile() async {
    if (await _shouldSkipProfileApi()) return;

    // ── DEBUG: Print Bearer Token for manual API testing ──
    if (kDebugMode) {
      final token = await _authSessionService.getAccessToken();
      print('╔══════════════════════════════════════════════════════════╗');
      print('║             CURRENT USER BEARER TOKEN                    ║');
      print('╠══════════════════════════════════════════════════════════╣');
      print('  $token');
      print('╚══════════════════════════════════════════════════════════╝');
    }

    _isLoading.value = true;
    _error.value = null;
    try {
      final data = await _profileRepository.getProfile();
      _profile.value = data;
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 401) {
        _error.value = 'Session expired. Please login again.';
      } else {
        _error.value = 'Failed to load profile.';
      }
    } finally {
      _isLoading.value = false;
      update();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading.value = true;
    _error.value = null;
    try {
      // Find the repository and call update
      final authRepo = Get.find<AuthRepository>();
      await authRepo.updateProfile(profileData);
      await loadProfile(); // Refresh
      return true;
    } catch (error) {
      _error.value = 'Failed to update profile.';
      return false;
    } finally {
      _isLoading.value = false;
      update();
    }
  }
}
