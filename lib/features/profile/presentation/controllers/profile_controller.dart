import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/features/auth/presentation/controllers/auth_controller.dart';
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
    }
  }
}
