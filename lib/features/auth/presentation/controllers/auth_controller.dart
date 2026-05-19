import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/notifications/fcm_bootstrap.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';
import 'package:satya_devotte_app/features/auth/domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  AuthController(
    this._firebaseService,
    this._authRepository,
    this._authSessionService,
  );

  final FirebaseService _firebaseService;
  final AuthRepository _authRepository;
  final AuthSessionService _authSessionService;

  final _isAuthenticated = false.obs;
  final _isGoogleSignInLoading = false.obs;
  final _isEmailSignInLoading = false.obs;
  final _lastAuthError = RxnString();
  final _userRole = RxString('user');
  final _isAuthLoading = false.obs;
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
      // Re-register the device with the backend on a cold start so any
      // tokens that rotated while the app was closed get reconciled.
      await _registerDeviceForPush();
    }
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

  // ─── Google Sign-In ──────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    if (_authApiInFlight || _isGoogleSignInLoading.value || _isEmailSignInLoading.value) {
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
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
      await _registerDeviceForPush();
      // ── DEBUG: Copy this Bearer token into Swagger Authorize ──
      print('');
      print('╔══════════════════════════════════════════════════════════╗');
      print('║  SWAGGER ACCESS TOKEN — paste into Authorize as Bearer   ║');
      print('╠══════════════════════════════════════════════════════════╣');
      print('  ' + loginResult.accessToken);
      print('╚══════════════════════════════════════════════════════════╝');
      print('');
      return true;
    } catch (error) {
      await _authSessionService.clear();
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
      final canAccessAdminPanel = loginResult.user['canLoginAdminPanel'] == true;
      final rawRole = (loginResult.user['role'] as String? ?? '')
          .trim()
          .toLowerCase();
      final hasAdminRole = rawRole == 'admin' ||
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
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
      await _registerDeviceForPush();
      return true;
    } catch (error) {
      await _authSessionService.clear();
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
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_authApiInFlight || _isGoogleSignInLoading.value || _isEmailSignInLoading.value) {
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
      );
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
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
      await _registerDeviceForPush();
      // ── DEBUG: Copy this Bearer token into Swagger Authorize ──
      print('');
      print('╔══════════════════════════════════════════════════════════╗');
      print('║  SWAGGER ACCESS TOKEN — paste into Authorize as Bearer   ║');
      print('╠══════════════════════════════════════════════════════════╣');
      print('  ' + loginResult.accessToken);
      print('╚══════════════════════════════════════════════════════════╝');
      print('');
      return true;
    } catch (error) {
      await _authSessionService.clear();
      await _firebaseService.signOut();
      _isAuthenticated.value = false;
      _lastAuthError.value = _mapEmailSignInError(error);
      return false;
    } finally {
      _isEmailSignInLoading.value = false;
      _authApiInFlight = false;
    }
  }

  // ─── Email / Password Sign-Up ────────────────────────────────
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_authApiInFlight || _isGoogleSignInLoading.value || _isEmailSignInLoading.value) {
      _lastAuthError.value = 'Login is already in progress. Please wait.';
      return false;
    }
    _authApiInFlight = true;
    _isEmailSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      await _firebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseIdToken = await _firebaseService.getIdToken(
        forceRefresh: true,
      );
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Firebase ID token is missing after email sign up.');
      }
      final emailProfile = _firebaseService.getCurrentUserProfileDetails();
      final loginResult = await _authRepository.loginWithFirebaseToken(
        firebaseIdToken,
        userProfile: emailProfile,
      );
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
      await _registerDeviceForPush();
      // ── DEBUG: Copy this Bearer token into Swagger Authorize ──
      print('');
      print('╔══════════════════════════════════════════════════════════╗');
      print('║  SWAGGER ACCESS TOKEN — paste into Authorize as Bearer   ║');
      print('╠══════════════════════════════════════════════════════════╣');
      print('  ' + loginResult.accessToken);
      print('╚══════════════════════════════════════════════════════════╝');
      print('');
      return true;
    } catch (error) {
      await _authSessionService.clear();
      await _firebaseService.signOut();
      _isAuthenticated.value = false;
      _lastAuthError.value = _mapEmailSignUpError(error);
      return false;
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
    // ── 1. Unregister FCM while the session still has a valid access token ──
    await _unregisterDeviceFromPush();

    final refreshToken = _authSessionService.refreshToken;

    // ── 2. Backend logout while session is intact (Bearer on the request) ──
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _authRepository.logout(refreshToken);
      } catch (e) {
        debugPrint('AuthController.signOut: logout API failed: $e');
      }
    }

    // ── 3. Local session + Firebase ─────────────────────────────────
    _isAuthenticated.value = false;
    _userRole.value = 'user';
    await _authSessionService.clear();

    try {
      await _firebaseService.signOut();
    } catch (_) {}
  }

  /// Deletes the account on the backend, then clears session and signs out of Firebase.
  Future<bool> deleteAccount() async {
    _isAuthLoading.value = true;
    _lastAuthError.value = null;
    try {
      final refreshToken = _authSessionService.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        _lastAuthError.value = 'Session expired. Please sign in again.';
        return false;
      }

      await _unregisterDeviceFromPush();
      await _authRepository.deleteAccount(refreshToken);

      _isAuthenticated.value = false;
      _userRole.value = 'user';
      await _authSessionService.clear();

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
}
