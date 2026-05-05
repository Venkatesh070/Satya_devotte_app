import 'package:satya_devotte_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:satya_devotte_app/features/auth/domain/entities/auth_login_result.dart';
import 'package:satya_devotte_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthLoginResult> loginWithFirebaseToken(
    String firebaseIdToken, {
    Map<String, dynamic>? userProfile,
  }) {
    return _remoteDataSource.loginWithFirebaseToken(
      firebaseIdToken,
      userProfile: userProfile,
    );
  }

  @override
  Future<void> logout(String refreshToken) {
    return _remoteDataSource.logout(refreshToken);
  }
}
