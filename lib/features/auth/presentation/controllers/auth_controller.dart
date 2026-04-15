import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/services/auth_session_service.dart';
import 'package:satya_devotte_app/core/services/firebase_service.dart';
import 'package:satya_devotte_app/features/auth/domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  AuthController(this._firebaseService, this._authRepository, this._authSessionService);
  final FirebaseService _firebaseService;
  final AuthRepository _authRepository;
  final AuthSessionService _authSessionService;

  final _isAuthenticated = false.obs;
  final _isGoogleSignInLoading = false.obs;
  final _lastAuthError = RxnString();

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isGoogleSignInLoading => _isGoogleSignInLoading.value;
  String? get lastAuthError => _lastAuthError.value;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.authStateChanges.listen((state) {
      _isAuthenticated.value = state;
    });
  }

  Future<bool> signInWithGoogle() async {
    _isGoogleSignInLoading.value = true;
    _lastAuthError.value = null;
    try {
      await _firebaseService.signInWithGoogle();
      final firebaseIdToken =
          await _firebaseService.getIdToken(forceRefresh: true);
      _logTokenInChunks(firebaseIdToken);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Firebase ID token is missing after Google sign in.');
      }
      final loginResult =
          await _authRepository.loginWithFirebaseToken(firebaseIdToken);
      await _authSessionService.setSession(
        accessToken: loginResult.accessToken,
        refreshToken: loginResult.refreshToken,
        userData: loginResult.user,
      );
      _isAuthenticated.value = true;
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

  String _mapGoogleSignInError(Object error) {
    final message = error.toString();

    if (message.contains('google-sign-in-cancelled')) {
      return 'Google sign in was cancelled.';
    }

    // ApiException: 10 / DEVELOPER_ERROR is the most common Firebase OAuth setup issue.
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

  void _logTokenInChunks(String? idToken) {
    if (idToken == null || idToken.isEmpty) {
      print('Final firebase user token to verify: null');
      return;
    }

    const chunkSize = 250;
    final totalParts = (idToken.length / chunkSize).ceil();
    print('Final firebase user token to verify START:$totalParts');
    for (var i = 0; i < totalParts; i++) {
      final start = i * chunkSize;
      final end = ((i + 1) * chunkSize < idToken.length)
          ? (i + 1) * chunkSize
          : idToken.length;
      final part = idToken.substring(start, end);
      print('Final firebase user token to verify PART ${i + 1}/$totalParts:$part');
    }
    // Single-line copy-friendly token.
    print('FINAL_FIREBASE_USER_TOKEN_TO_VERIFY:$idToken');
    print('Final firebase user token to verify END');
  }

  Future<void> signInWithApple() async {
    await _firebaseService.signInWithApple();
    _isAuthenticated.value = true;
  }

  Future<void> signOut() async {
    await _authSessionService.clear();
    await _firebaseService.signOut();
    _isAuthenticated.value = false;
  }
}
