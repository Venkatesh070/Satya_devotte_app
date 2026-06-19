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
  Future<AuthLoginResult> loginAsAdmin(
    String firebaseIdToken, {
    Map<String, dynamic>? userProfile,
  }) {
    return _remoteDataSource.loginAsAdmin(
      firebaseIdToken,
      userProfile: userProfile,
    );
  }

  @override
  Future<void> logout(String refreshToken) {
    return _remoteDataSource.logout(refreshToken);
  }

  @override
  Future<void> deleteAccount(String comment, {String? refreshToken}) {
    return _remoteDataSource.deleteAccount(comment);
  }

  @override
  Future<void> upsertProfile(Map<String, dynamic> profileData) {
    return _remoteDataSource.upsertProfile(profileData);
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> profileData) {
    return _remoteDataSource.updateProfile(profileData);
  }
  
  @override
  Future<void> deleteProfilePicture() {
    return _remoteDataSource.deleteProfilePicture();
  }
}
