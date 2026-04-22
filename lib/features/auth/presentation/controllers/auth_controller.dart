import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
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

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isGoogleSignInLoading => _isGoogleSignInLoading.value;
  bool get isEmailSignInLoading => _isEmailSignInLoading.value;
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
    }
  }

  void _applyRole(Map<String, dynamic> user) {
    // The API returns role: "admin" for both admin and superadmin.
    // The real distinction is the separate isSuperAdmin: true boolean field.
    print(
      '🔑 RAW ROLE: "${user['role']}" | isSuperAdmin field: ${user['isSuperAdmin']}',
    );
    final isSuperAdmin = user['isSuperAdmin'] == true;
    if (isSuperAdmin) {
      _userRole.value = 'superadmin';
    } else {
      final raw = (user['role'] as String? ?? 'user').trim().toLowerCase();
      _userRole.value = raw == 'admin' ? 'admin' : 'user';
    }
    print(
      '🔑 FINAL _userRole: "${_userRole.value}" | isSuperAdmin: $isSuperAdmin',
    );
    _authSessionService.patchRole(_userRole.value);
  }

  // ─── Google Sign-In ──────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
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
      final loginResult = await _authRepository.loginWithFirebaseToken(
        firebaseIdToken,
      );
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
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
    }
  }

  // ─── Email / Password Sign-In ────────────────────────────────
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
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
      final loginResult = await _authRepository.loginWithFirebaseToken(
        firebaseIdToken,
      );
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
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
    }
  }

  // ─── Email / Password Sign-Up ────────────────────────────────
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
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
      final loginResult = await _authRepository.loginWithFirebaseToken(
        firebaseIdToken,
      );
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _applyRole(loginResult.user);
      _isAuthenticated.value = true;
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
    }
  }

  Future<void> signInWithApple() async {
    await _firebaseService.signInWithApple();
    _isAuthenticated.value = true;
  }

  Future<void> signOut() async {
    // ── Clear local state FIRST so route guards see unauthenticated immediately ──
    _isAuthenticated.value = false;
    _userRole.value = 'user';

    // ── Clear persisted session ──────────────────────────────────
    final refreshToken = _authSessionService.refreshToken;
    await _authSessionService.clear();

    // ── Firebase sign-out ────────────────────────────────────────
    try {
      await _firebaseService.signOut();
    } catch (_) {}

    // ── Invalidate refresh token on server (best-effort, non-blocking) ──
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _authRepository.logout(refreshToken).catchError((_) {});
    }
  }

  // ─── Error mappers ────────────────────────────────────────────
  String _mapGoogleSignInError(Object error) {
    final message = error.toString();
    if (message.contains('google-sign-in-cancelled')) {
      return 'Google sign in was cancelled.';
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
      if (statusCode != null && statusCode >= 500) {
        return 'Server error during signup. Please try again.';
      }
    }
    return 'Email sign up failed. Please try again.';
  }
}
