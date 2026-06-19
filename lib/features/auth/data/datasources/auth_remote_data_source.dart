import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/auth/domain/entities/auth_login_result.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// Invalidates the stored refresh token on the server.
  /// POST `/api/v1/auth/logout` with `{ "refreshToken": "..." }`.
  Future<void> logout(String refreshToken) async {
    await _apiClient.dio.post<dynamic>(
      ApiEndpoints.authLogout,
      data: {'refreshToken': refreshToken},
    );
  }

  /// Soft-deletes the account on the server.
  /// DELETE `/api/v1/auth/account` with body `{ "comment": "..." }`.
  Future<void> deleteAccount(String comment) async {
    await _apiClient.dio.delete<dynamic>(
      ApiEndpoints.authDeleteAccount,
      data: {'comment': comment},
    );
  }

  /// Creates or updates the signed-in user's profile.
  /// POST `/api/v1/auth/profile` as multipart/form-data.
  Future<void> upsertProfile(Map<String, dynamic> profileData) async {
    final formDataMap = <String, dynamic>{};
    profileData.forEach((key, value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        if (key == 'image' || key == 'profileImage' || key == 'imageUrl' || key == 'profileImageUrl') {
          // Send as is (either null or empty string)
          formDataMap[key] = value;
        }
        return;
      }
      if (value is MultipartFile) {
        formDataMap[key] = value;
      } else {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          formDataMap[key] = text;
        }
      }
    });
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.profile,
      data: FormData.fromMap(formDataMap),
    );
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message:
            'Profile upsert API failed with status ${response.statusCode}.',
      );
    }
  }

  /// Partially updates the signed-in user's profile.
  /// PATCH `/api/v1/auth/profile` as multipart/form-data.
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    final formDataMap = <String, dynamic>{};
    profileData.forEach((key, value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        if (key == 'image' || key == 'profileImage' || key == 'imageUrl' || key == 'profileImageUrl') {
          // Send as is (either null or empty string)
          formDataMap[key] = value;
        }
        return;
      }
      if (value is MultipartFile) {
        formDataMap[key] = value;
      } else {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          formDataMap[key] = text;
        }
      }
    });
    final response = await _apiClient.dio.patch<dynamic>(
      ApiEndpoints.profile,
      data: FormData.fromMap(formDataMap),
    );
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message:
            'Profile update API failed with status ${response.statusCode}.',
      );
    }
  }

  /// Deletes the signed-in user's profile picture.
  /// DELETE `/api/v1/auth/profile/image`.
  Future<void> deleteProfilePicture() async {
    final response = await _apiClient.dio.delete<dynamic>(
      ApiEndpoints.profileImage,
    );
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message:
            'Profile picture delete API failed with status ${response.statusCode}.',
      );
    }
  }

  /// Web admin sign-in. POSTs to `/auth/admin-login` with the Firebase ID token
  /// in the Authorization header. The backend verifies the token AND ensures
  /// the user has admin (or superadmin) privileges.
  Future<AuthLoginResult> loginAsAdmin(
    String firebaseIdToken, {
    Map<String, dynamic>? userProfile,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.authAdminLogin,
      data: userProfile == null ? null : <String, dynamic>{'user': userProfile},
      options: Options(headers: {'Authorization': 'Bearer $firebaseIdToken'}),
    );
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Admin login API failed with status ${response.statusCode}.',
      );
    }
    final accessToken = _extractAccessToken(response.data);
    final refreshToken = _extractRefreshToken(response.data);
    final user = _extractUser(response.data);
    if (accessToken == null || accessToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Access token is missing in admin login response.',
      );
    }
    if (user == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'User data is missing in admin login response.',
      );
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Refresh token is missing in admin login response.',
      );
    }
    return AuthLoginResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      isRegistered: _extractIsRegistered(response.data),
    );
  }

  Future<AuthLoginResult> loginWithFirebaseToken(
    String firebaseIdToken, {
    Map<String, dynamic>? userProfile,
  }) async {
    // Explicit log requested for backend auth debugging.
    print('BACKEND_LOGIN_AUTHORIZATION_TOKEN:Bearer $firebaseIdToken');
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.authLogin,
      data: userProfile == null ? null : <String, dynamic>{'user': userProfile},
      options: Options(headers: {'Authorization': 'Bearer $firebaseIdToken'}),
    );
    print('║ Body   : ${response.data}');
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Auth login API failed with status ${response.statusCode}.',
      );
    }

    final accessToken = _extractAccessToken(response.data);
    final refreshToken = _extractRefreshToken(response.data);
    final user = _extractUser(response.data);
    if (accessToken == null || accessToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Access token is missing in auth login response.',
      );
    }
    if (user == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'User data is missing in auth login response.',
      );
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Refresh token is missing in auth login response.',
      );
    }
    return AuthLoginResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      isRegistered: _extractIsRegistered(response.data),
    );
  }

  /// Parses `isRegistered` from the login payload (root, `data`, or nested `user`).
  /// Defaults to `true` when the field is absent (older API responses).
  bool _extractIsRegistered(dynamic data) {
    if (data is! Map<String, dynamic>) return true;

    bool? parseValue(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      if (v is num) return v != 0;
      return null;
    }

    final direct = parseValue(data['isRegistered']);
    if (direct != null) return direct;

    final inner = data['data'];
    if (inner is Map<String, dynamic>) {
      final nested = parseValue(inner['isRegistered']);
      if (nested != null) return nested;
    }

    final user = _extractUser(data);
    if (user != null) {
      final onUser = parseValue(user['isRegistered']);
      if (onUser != null) return onUser;
    }

    return true;
  }

  String? _extractAccessToken(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (data['accessToken'] is String) {
      return data['accessToken'] as String;
    }

    final inner = data['data'];
    if (inner is Map<String, dynamic> && inner['accessToken'] is String) {
      return inner['accessToken'] as String;
    }
    return null;
  }

  String? _extractRefreshToken(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (data['refreshToken'] is String) {
      return data['refreshToken'] as String;
    }

    final inner = data['data'];
    if (inner is Map<String, dynamic> && inner['refreshToken'] is String) {
      return inner['refreshToken'] as String;
    }
    return null;
  }

  Map<String, dynamic>? _extractUser(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (data['user'] is Map<String, dynamic>) {
      return data['user'] as Map<String, dynamic>;
    }

    final inner = data['data'];
    if (inner is Map<String, dynamic> &&
        inner['user'] is Map<String, dynamic>) {
      return inner['user'] as Map<String, dynamic>;
    }

    return null;
  }
}
