import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/notifications/fcm_bootstrap.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';
import 'package:satya_devotte_app/core/services/app_music_service.dart';
import 'package:satya_devotte_app/features/admin_notifications/presentation/controllers/cms_admin_notifications_controller.dart';
import 'package:satya_devotte_app/features/auth/domain/entities/auth_login_result.dart';
import 'package:satya_devotte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/create_account_page.dart';
import 'package:satya_devotte_app/features/auth/presentation/pages/email_verification_page.dart';
import 'package:satya_devotte_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:satya_devotte_app/features/poojakit/state/cart_controller.dart';

class AuthController extends GetxController {
  AuthController(
    this._firebaseService,
    this._authRepository,
    this._authSessionService,
  );

  final FirebaseService _firebaseService;
  final AuthRepository _authRepository;
  final AuthSessionService _authSessionService;

  // Temporary storage for profile data while waiting for email verification
  Map<String, dynamic>? _pendingProfileData;

  final _isAuthenticated = false.obs;
  final _isGoogleSignInLoading = false.obs;
  final _isEmailSignInLoading = false.obs;
  final _lastAuthError = RxnString();
  final _userRole = RxString('user');
  final _isAuthLoading = false.obs;
  final _sessionUser = Rxn<Map<String, dynamic>>();
  bool _authApiInFlight = false;

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isGoogleSignInLoading => _isGoogleSignInLoading.value;
  bool get isEmailSignInLoading => _isEmailSignInLoading.value;
  bool get isAuthLoading => _isAuthLoading.value;
  String? get lastAuthError => _lastAuthError.value;

  // ─── Role getters ─────────────────────────────────────────────
  String get userRole => _userRole.value;
  bool get isSuperAdmin => _userRole.value == 'superadmin';
  bool get isAdmin => _userRole.value == 'admin' || isSuperAdmin;
  bool get isRegularUser => _userRole.value == 'user';

  /// Backend user payload from the latest login / restored session.
  Map<String, dynamic>? get sessionUser => _sessionUser.value;

  /// Display name from admin login response (`fullName`, `name`, etc.).
  String get displayName =>
      ProfileController.displayNameFromUserMap(sessionUser);

  /// First letter for avatar chips in CMS chrome.
  String get displayInitial {
    final name = displayName;
    if (name.isNotEmpty && name != 'User') {
      return name[0].toUpperCase();
    }
    return isSuperAdmin ? 'S' : 'A';
  }

  String get displayEmail {
    final u = sessionUser;
    if (u == null) return '';
    final email = u['email']?.toString().trim();
    return (email != null && email.isNotEmpty) ? email : '';
  }

  String get displayPhone {
    final u = sessionUser;
    if (u == null) return '';
    for (final key in ['phoneNumber', 'phone', 'mobile']) {
      final value = u[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  /// Hover tooltip for CMS avatar / name (email + phone from login response).
  String get contactHoverText {
    final lines = <String>[];
    if (displayEmail.isNotEmpty) lines.add('Email: $displayEmail');
    if (displayPhone.isNotEmpty) lines.add('Phone: $displayPhone');
    if (lines.isEmpty) return displayName;
    return lines.join('\n');
  }

  void _syncSessionUser() {
    final data = _authSessionService.userData;
    _sessionUser.value =
        data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<void> _clearAuthSession() async {
    await _authSessionService.clear();
    _syncSessionUser();
  }

  /// `false` when the backend login response requires profile completion.
  bool get isProfileRegistrationComplete {
    final v = _authSessionService.userData?['isRegistered'];
    if (v is bool) return v;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    if (v is num) return v != 0;
    return true;
  }

  /// Routes admin → CMS; users with `isRegistered: false` → profile setup; else home.
  void navigateAfterLogin() {
    if (isAdmin) {
      Get.offAllNamed(AppRoutes.cms);
      _startCmsBackgroundMusic();
      _refreshAdminActivityBadge();
      return;
    }
    if (!isProfileRegistrationComplete) {
      Get.offAll(() => const CreateAccountPage(completeProfileOnly: true));
      return;
    }
    Get.offAllNamed(AppRoutes.home);
  }

  /// Current logged-in user's backend MongoDB _id
  String get currentUserId =>
      (_authSessionService.userData?['_id'] as String? ?? '').trim();

  @override
  void onInit() {
    super.onInit();
    // Web skips splash, so restore persisted session/role here as well.
    Future.microtask(loadSavedSession);
    _firebaseService.authStateChanges.listen((state) {
      _isAuthenticated.value = state;
    });
  }

  /// Call this from SplashPage to restore session on app start.
  Future<void> loadSavedSession() async {
    final restored = await _authSessionService.loadPersistedSession();
    if (restored) {
      _isAuthenticated.value = true;
      _userRole.value = _authSessionService.userRole;
      _syncSessionUser();
      // Re-register the device with the backend on a cold start so any
      // tokens that rotated while the app was closed get reconciled.
      await _registerDeviceForPush();
      _refreshProfileControllerAfterAuth();
      // Refresh cart and pooja history for restored session
      unawaited(_refreshCartAfterAuth());
      // Start music if user is regular user
      if (isRegularUser) {
        _startRegularUserBackgroundMusic();
      }
    }
  }

  /// Keeps [ProfileController] in sync after login / cold-start restore so
  /// home greeting and profile UI see the latest `user` map (e.g. `fullName`).
  void _startCmsBackgroundMusic() {
    if (!Get.isRegistered<AppMusicService>()) return;
    final music = Get.find<AppMusicService>();
    Future.microtask(() => unawaited(music.startOnAdminLogin()));
  }

  void _stopCmsBackgroundMusicIfNeeded() {
    if (!Get.isRegistered<AppMusicService>()) return;
    final onCms = AppMusicService.isCmsRoute(Get.currentRoute);
    if (!isAdmin && !onCms) return;
    final music = Get.find<AppMusicService>();
    unawaited(music.stopOnAdminLogout());
  }

  void _refreshAdminActivityBadge() {
    if (!isAdmin || !Get.isRegistered<CmsAdminNotificationsController>()) {
      return;
    }
    unawaited(Get.find<CmsAdminNotificationsController>().refreshUnreadCount());
  }

  void _refreshProfileControllerAfterAuth() {
    try {
      if (!Get.isRegistered<ProfileController>()) return;
      final pc = Get.find<ProfileController>();
      unawaited(() async {
        await pc.loadSessionUser();
        await pc.loadProfile();
      }());
    } catch (_) {}
  }

  void _clearProfileControllerCache() {
    try {
      if (!Get.isRegistered<ProfileController>()) return;
      Get.find<ProfileController>().clearCachedUser();
    } catch (_) {}
  }

  void _clearCartOnLogout() {
    try {
      if (!Get.isRegistered<CartController>()) return;
      final cartController = Get.find<CartController>();
      // Clear cart locally
      cartController.clearLocalCart();
    } catch (_) {}
  }

  Future<void> _refreshCartAfterAuth() async {
    try {
      if (!Get.isRegistered<CartController>()) return;
      final cartController = Get.find<CartController>();
      await cartController.fetchCart();
    } catch (_) {}
  }

  /// Best-effort register the device FCM token with the backend.
  /// Never throws or blocks the calling auth flow — login UX must not
  /// degrade if push registration fails (no Play Services, denied
  /// permission, transient network, etc.).
  Future<void> _registerDeviceForPush() async {
    try {
      if (!Get.isRegistered<FcmBootstrap>()) return;
      // Fire and forget on purpose: callers do not await this.
      unawaited(Get.find<FcmBootstrap>().registerWithBackend());
      _refreshAdminActivityBadge();
    } catch (_) {}
  }

  /// Best-effort unregister BEFORE the session is cleared. Awaited so the
  /// Dio interceptor still attaches a valid bearer to the DELETE.
  Future<void> _unregisterDeviceFromPush() async {
    try {
      if (!Get.isRegistered<FcmBootstrap>()) return;
      await Get.find<FcmBootstrap>().unregisterFromBackend();
    } catch (_) {}
  }

  void _applyRole(Map<String, dynamic> user) {
    // The API may indicate super admin in two ways:
    //   • a dedicated `isSuperAdmin: true` boolean (legacy), or
    //   • `role: "superadmin"` (current /auth/admin-login response).
    final raw = (user['role'] as String? ?? 'user').trim().toLowerCase();
    final isSuperAdmin = user['isSuperAdmin'] == true || raw == 'superadmin';
    print(
      '🔑 RAW ROLE: "${user['role']}" | isSuperAdmin field: ${user['isSuperAdmin']}',
    );
    if (isSuperAdmin) {
      _userRole.value = 'superadmin';
    } else if (raw == 'admin') {
      _userRole.value = 'admin';
    } else {
      _userRole.value = 'user';
    }
    print(
      '🔑 FINAL _userRole: "${_userRole.value}" | isSuperAdmin: $isSuperAdmin',
    );
    _authSessionService.patchRole(_userRole.value);
  }

  void _startRegularUserBackgroundMusic() {
    if (!Get.isRegistered<AppMusicService>()) return;
    final music = Get.find<AppMusicService>();
    Future.microtask(() => unawaited(music.start()));
  }

  void _stopRegularUserBackgroundMusic() {
    if (!Get.isRegistered<AppMusicService>()) return;
    final music = Get.find<AppMusicService>();
    Future.microtask(() => unawaited(music.pause()));
  }

  Future<void> persistLoginResult(AuthLoginResult loginResult) async {
    final user = Map<String, dynamic>.from(loginResult.user);
    user['isRegistered'] = loginResult.isRegistered;
    await _authSessionService.setSession(
      accessToken: loginResult.accessToken,
      refreshToken: loginResult.refreshToken,
      userData: user,
    );
    _syncSessionUser();
    _applyRole(user);
    _isAuthenticated.value = true;
    await _registerDeviceForPush();
    _refreshProfileControllerAfterAuth();
    // Refresh cart and pooja history for new user
    unawaited(_refreshCartAfterAuth());
    // Start music for regular users
    if (isRegularUser) {
      _startRegularUserBackgroundMusic();
    }
  }

  AuthRepository get authRepository => _authRepository;

  Future<void> _markProfileRegisteredInSession() async {
    final current = _authSessionService.userData;
    if (current == null) return;
    final user = Map<String, dynamic>.from(current);
    user['isRegistered'] = true;
    final access = _authSessionService.accessToken;
    final refresh = _authSessionService.refreshToken;
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      return;
    }
    await _authSessionService.setSession(
      accessToken: access,
      refreshToken: refresh,
      userData: user,
    );
    _syncSessionUser();
  }

  // ─── Google Sign-In ──────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    if (_authApiInFlight ||
        _isGoogleSignInLoading.value ||
        _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Login is already in progress. Please wait.';
      return false;
    }
    _authApiInFlight = true;
    _isGoogleSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      await _firebaseService.signInWithGoogle();
      final firebaseIdToken = await _firebaseService.getIdToken(
        forceRefresh: true,
      );
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Firebase ID token is missing after Google sign in.');
      }
      final googleProfile = _firebaseService.getCurrentUserProfileDetails();
      final loginResult = await _authRepository.loginWithFirebaseToken(
        firebaseIdToken,
        userProfile: googleProfile,
      );
      await persistLoginResult(loginResult);
      return true;
    } catch (error) {
      await _clearAuthSession();
      _clearProfileControllerCache();
      await _firebaseService.signOut();
      _isAuthenticated.value = false;
      _lastAuthError.value = _mapGoogleSignInError(error);
      return false;
    } finally {
      _isGoogleSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  // ─── Admin Email / Password Sign-In (web) ───────────────────
  // Signs in to Firebase first (email/password), then exchanges the resulting
  // Firebase ID token at /auth/admin-login. The backend enforces the admin
  // role on that endpoint and rejects regular users.
  Future<bool> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    if (_authApiInFlight ||
        _isGoogleSignInLoading.value ||
        _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Login is already in progress. Please wait.';
      return false;
    }
    _authApiInFlight = true;
    _isEmailSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
        allowGoogleAccountLinking: false,
      );
      final firebaseIdToken = await _firebaseService.getIdToken(
        forceRefresh: true,
      );
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Firebase ID token is missing after admin sign in.');
      }
      final adminProfile = _firebaseService.getCurrentUserProfileDetails();
      final loginResult = await _authRepository.loginAsAdmin(
        firebaseIdToken,
        userProfile: adminProfile,
      );
      // Server flag: explicit gate for the admin panel.
      final canAccessAdminPanel =
          loginResult.user['canLoginAdminPanel'] == true;
      final rawRole = (loginResult.user['role'] as String? ?? '')
          .trim()
          .toLowerCase();
      final hasAdminRole =
          rawRole == 'admin' ||
          rawRole == 'superadmin' ||
          loginResult.user['isSuperAdmin'] == true;
      if (!canAccessAdminPanel || !hasAdminRole) {
        _lastAuthError.value =
            'This account is not authorised to access the admin panel.';
        await _firebaseService.signOut();
        return false;
      }
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _syncSessionUser();
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
      await _registerDeviceForPush();
      _refreshProfileControllerAfterAuth();
      return true;
    } catch (error) {
      await _clearAuthSession();
      _clearProfileControllerCache();
      await _firebaseService.signOut();
      _isAuthenticated.value = false;
      _lastAuthError.value = _mapEmailSignInError(error);
      return false;
    } finally {
      _isEmailSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  // ─── Email / Password Sign-In ────────────────────────────────
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_authApiInFlight ||
        _isGoogleSignInLoading.value ||
        _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Login is already in progress. Please wait.';
      return;
    }
    _authApiInFlight = true;
    _isEmailSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firebaseService.reloadCurrentUser();
      if (!_firebaseService.isEmailVerified) {
        _pendingProfileData = null; // Not a signup, so no profile data pending
        Get.to(() => const EmailVerificationPage());
        return;
      }
      final firebaseIdToken = await _firebaseService.getIdToken(
        forceRefresh: true,
      );
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Firebase ID token is missing after email sign in.');
      }
      final emailProfile = _firebaseService.getCurrentUserProfileDetails();
      final loginResult = await _authRepository.loginWithFirebaseToken(
        firebaseIdToken,
        userProfile: emailProfile,
      );
      await persistLoginResult(loginResult);
      await _markProfileRegisteredInSession();
      navigateAfterLogin();
    } catch (error) {
      await _clearAuthSession();
      _clearProfileControllerCache();
      await _firebaseService.signOut();
      _isAuthenticated.value = false;
      _lastAuthError.value = _mapEmailSignInError(error);
      rethrow;
    } finally {
      _isEmailSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  // ─── Email / Password Sign-Up ────────────────────────────────
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_authApiInFlight ||
        _isGoogleSignInLoading.value ||
        _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Login is already in progress. Please wait.';
      return;
    }
    _authApiInFlight = true;
    _isEmailSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      await _firebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _pendingProfileData = null;
      Get.to(() => const EmailVerificationPage());
    } catch (error) {
      await _clearAuthSession();
      _clearProfileControllerCache();
      await _firebaseService.signOut();
      _isAuthenticated.value = false;
      _lastAuthError.value = _mapEmailSignUpError(error);
      rethrow;
    } finally {
      _isEmailSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  /// Completes registration for users who already signed in (`isRegistered: false`).
  Future<bool> completeRegistration({
    Map<String, dynamic>? profileData,
    bool skipProfile = false,
  }) async {
    if (_authApiInFlight ||
        _isGoogleSignInLoading.value ||
        _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Please wait for the current request to finish.';
      return false;
    }
    _authApiInFlight = true;
    _isEmailSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      if (!skipProfile && profileData != null && profileData.isNotEmpty) {
        await _authRepository.upsertProfile(profileData);
      }
      await _markProfileRegisteredInSession();
      _refreshProfileControllerAfterAuth();
      return true;
    } catch (error) {
      _lastAuthError.value = _mapCreateAccountError(error);
      return false;
    } finally {
      _isEmailSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  Future<void> signUpAndCreateProfile({
    required String email,
    required String password,
    Map<String, dynamic>? profileData,
  }) async {
    if (_authApiInFlight ||
        _isGoogleSignInLoading.value ||
        _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Login is already in progress. Please wait.';
      return;
    }
    _authApiInFlight = true;
    _isEmailSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      await _firebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _pendingProfileData = profileData;
      Get.to(() => const EmailVerificationPage());
    } catch (error) {
      await _clearAuthSession();
      _clearProfileControllerCache();
      await _firebaseService.signOut();
      _isAuthenticated.value = false;
      _lastAuthError.value = _mapCreateAccountError(error);
      rethrow;
    } finally {
      _isEmailSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  /// Called after email is verified to complete signup (including profile data)
  Future<void> completeSignupAfterVerification() async {
    if (_authApiInFlight ||
        _isGoogleSignInLoading.value ||
        _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Please wait for the current request to finish.';
      return;
    }
    _authApiInFlight = true;
    _isEmailSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      final firebaseIdToken = await _firebaseService.getIdToken(
        forceRefresh: true,
      );
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception(
          'Firebase ID token is missing after email verification.',
        );
      }
      final emailProfile = _firebaseService.getCurrentUserProfileDetails();
      final loginResult = await _authRepository.loginWithFirebaseToken(
        firebaseIdToken,
        userProfile: emailProfile,
      );
      await persistLoginResult(loginResult);

      // If we have pending profile data, upsert it now
      if (_pendingProfileData != null && _pendingProfileData!.isNotEmpty) {
        await _authRepository.upsertProfile(_pendingProfileData!);
      }
      await _markProfileRegisteredInSession();
      _refreshProfileControllerAfterAuth();

      // Clear pending data
      _pendingProfileData = null;

      navigateAfterLogin();
    } catch (error) {
      _lastAuthError.value = _mapCreateAccountError(error);
    } finally {
      _isEmailSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  Future<void> signInWithApple() async {
    await _firebaseService.signInWithApple();
    _isAuthenticated.value = true;
    await _registerDeviceForPush();
  }

  Future<void> signOut() async {
    _stopCmsBackgroundMusicIfNeeded();
    _stopRegularUserBackgroundMusic();

    final refreshToken = _authSessionService.refreshToken;
    // Give server-side cleanup a short head start, but never block UX.
    final remoteCleanup = _runBestEffortSignOutCleanup(
      refreshToken: refreshToken,
    );
    await Future.any<void>([
      remoteCleanup,
      Future<void>.delayed(const Duration(milliseconds: 350)),
    ]);

    // ── Local session + Firebase ────────────────────────────────────
    _isAuthenticated.value = false;
    _userRole.value = 'user';
    await _clearAuthSession();
    _clearProfileControllerCache();
    _clearCartOnLogout();

    try {
      await _firebaseService.signOut();
    } catch (_) {}

    // Continue best-effort server cleanup in background if still running.
    unawaited(remoteCleanup);
  }

  Future<void> _runBestEffortSignOutCleanup({String? refreshToken}) async {
    // 1) Unregister FCM while the session still has a valid access token.
    await _unregisterDeviceFromPush();

    // 2) Revoke refresh token on backend while session is intact.
    if (refreshToken == null || refreshToken.isEmpty) return;
    try {
      await _authRepository.logout(refreshToken);
    } catch (e) {
      debugPrint('AuthController.signOut: logout API failed: $e');
    }
  }

  /// Deletes the account on the backend, then clears session and signs out of Firebase.
  Future<bool> deleteAccount({required String comment}) async {
    _isAuthLoading.value = true;
    _lastAuthError.value = null;
    try {
      _stopCmsBackgroundMusicIfNeeded();
      _stopRegularUserBackgroundMusic();

      final normalizedComment = comment.trim();
      if (normalizedComment.isEmpty) {
        _lastAuthError.value = 'Please provide a deletion comment.';
        return false;
      }

      await _unregisterDeviceFromPush();
      await _authRepository.deleteAccount(normalizedComment);

      _isAuthenticated.value = false;
      _userRole.value = 'user';
      await _clearAuthSession();
      _clearProfileControllerCache();

      try {
        await _firebaseService.signOut();
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('AuthController.deleteAccount failed: $e');
      _lastAuthError.value = _mapDeleteAccountError(e);
      return false;
    } finally {
      _isAuthLoading.value = false;
    }
  }

  String _mapDeleteAccountError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Unable to reach the server. Check your connection.';
      }
      final code = error.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'You are not allowed to delete this account. Try signing in again.';
      }
    }
    return 'Could not delete account. Please try again.';
  }

  // ─── Error mappers ────────────────────────────────────────────
  String _mapGoogleSignInError(Object error) {
    final message = error.toString();
    if (message.contains('people.googleapis.com') ||
        message.contains('People API') ||
        message.contains('SERVICE_DISABLED')) {
      return 'Google People API is disabled for this project. '
          'Enable it in Google Cloud Console, wait a few minutes, and try again.';
    }
    if (message.contains('google-sign-in-cancelled')) {
      return 'Google sign in was cancelled.';
    }
    if (message.contains('popup_closed')) {
      return 'Google login popup was closed. Please try again and keep the popup open.';
    }
    if (message.contains('popup_blocked_by_browser') ||
        message.contains('popup_blocked')) {
      return 'Browser blocked the Google login popup. Please allow popups for this site.';
    }
    if (message.contains('ApiException: 10') ||
        message.toUpperCase().contains('DEVELOPER_ERROR')) {
      return 'Google sign in is not configured correctly in Firebase. '
          'Please add Android SHA keys and download a new google-services.json.';
    }
    if (message.contains('network_error')) {
      return 'Network error during Google sign in. Please check your internet.';
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Unable to reach login server. Please check server and network.';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      }
      if (statusCode == 401 || statusCode == 403) {
        return 'Login verification failed by server.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'Server error during login. Please try again.';
      }
      return 'Login API failed. Please try again.';
    }
    return 'Google sign in failed. Please try again.';
  }

  String _mapEmailSignInError(Object error) {
    final raw = error.toString();
    if (raw.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Invalid email or password.';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'google-account-mismatch':
          return 'Please choose the same Google account as the entered email to link providers.';
      }
    }
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Unable to reach login server. Please check server and network.';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      }
      if (statusCode == 401 || statusCode == 403) {
        return 'Login verification failed by server.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'Server error during login. Please try again.';
      }
    }
    return 'Email sign in failed. Please try again.';
  }

  String _mapEmailSignUpError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email/password sign up is disabled in Firebase.';
      }
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Unable to reach login server. Please check server and network.';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) {
        return 'Too many requests. Please wait a moment and try again.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'Server error during signup. Please try again.';
      }
    }
    return 'Email sign up failed. Please try again.';
  }

  String _mapCreateAccountError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Unable to reach server. Check your internet and try again.';
      }
    }
    return _mapEmailSignUpError(error);
  }
}
