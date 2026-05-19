import 'package:satya_devotte_app/features/auth/domain/entities/auth_login_result.dart';

abstract class AuthRepository {
  Future<AuthLoginResult> loginWithFirebaseToken(
    String firebaseIdToken, {
    Map<String, dynamic>? userProfile,
  });

  /// Admin sign-in used by the web login page. Sends the Firebase ID token in
  /// the Authorization header to `/auth/admin-login` and lets the backend
  /// enforce the admin role check.
  Future<AuthLoginResult> loginAsAdmin(
    String firebaseIdToken, {
    Map<String, dynamic>? userProfile,
  });

  Future<void> logout(String refreshToken);

  /// Permanently (soft) deletes the user account on the backend.
  Future<void> deleteAccount(String refreshToken);
}
