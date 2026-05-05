import 'package:satya_devotte_app/features/auth/domain/entities/auth_login_result.dart';

abstract class AuthRepository {
  Future<AuthLoginResult> loginWithFirebaseToken(
    String firebaseIdToken, {
    Map<String, dynamic>? userProfile,
  });
  Future<void> logout(String refreshToken);
}
