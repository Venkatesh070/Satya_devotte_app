// Typed exception for the FCM registry endpoints.
import 'package:dio/dio.dart';

class FcmException implements Exception {
  const FcmException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  factory FcmException.fromDio(DioException e, {String? fallback}) {
    String? backendMsg;
    final res = e.response;
    if (res?.data is Map) {
      final m = res!.data as Map;
      final v = m['message'] ?? m['error'];
      if (v != null && v.toString().trim().isNotEmpty) {
        backendMsg = v.toString().trim();
      }
    }
    return FcmException(
      backendMsg ?? fallback ?? 'Notification registration failed.',
      statusCode: res?.statusCode,
      cause: e,
    );
  }

  @override
  String toString() => 'FcmException($statusCode): $message';
}
