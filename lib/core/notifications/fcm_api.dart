// Thin wrapper around the backend's FCM token registry.
//
// All three endpoints inherit the shared `AuthTokenInterceptor`, so the
// Firebase / session bearer is attached automatically. No additional
// header plumbing lives here.
import 'package:dio/dio.dart';

import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';

import 'fcm_exception.dart';

class FcmApi {
  FcmApi(this._apiClient);
  final ApiClient _apiClient;

  /// POST /api/v1/fcm/register — idempotent; backend `$addToSet`s the
  /// token into the user's `fcmTokens` array.
  Future<void> registerToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    if (token.trim().length < 20) {
      throw const FcmException('FCM token looks invalid (too short).');
    }
    try {
      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.fcmRegister,
        data: <String, dynamic>{
          'token': token,
          'platform': platform,
          if (deviceId != null && deviceId.trim().isNotEmpty)
            'deviceId': deviceId.trim(),
        },
      );
    } on DioException catch (e) {
      throw FcmException.fromDio(
        e,
        fallback: 'Could not register this device for notifications.',
      );
    }
  }

  /// DELETE /api/v1/fcm/unregister — best-effort cleanup on logout /
  /// token rotation.
  Future<void> unregisterToken(String token) async {
    if (token.trim().isEmpty) return;
    try {
      await _apiClient.dio.delete<dynamic>(
        ApiEndpoints.fcmUnregister,
        data: <String, dynamic>{'token': token},
      );
    } on DioException catch (e) {
      throw FcmException.fromDio(
        e,
        fallback: 'Could not unregister this device.',
      );
    }
  }

  /// GET /api/v1/fcm/me — returns `{ count: N }` for sanity checks.
  Future<int> registeredCount() async {
    try {
      final res = await _apiClient.dio.get<dynamic>(ApiEndpoints.fcmMe);
      final body = res.data;
      if (body is! Map) return 0;
      final data = body['data'] is Map ? body['data'] as Map : body;
      final raw = data['count'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    } on DioException catch (e) {
      throw FcmException.fromDio(
        e,
        fallback: 'Could not fetch registered token count.',
      );
    }
  }
}
