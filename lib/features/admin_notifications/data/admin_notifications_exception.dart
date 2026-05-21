import 'package:dio/dio.dart';

class AdminNotificationsException implements Exception {
  const AdminNotificationsException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  factory AdminNotificationsException.fromDio(
    DioException e, {
    String? fallback,
  }) {
    String? backendMsg;
    final res = e.response;
    if (res?.data is Map) {
      final m = res!.data as Map;
      final v = m['message'] ?? m['error'];
      if (v != null && v.toString().trim().isNotEmpty) {
        backendMsg = v.toString().trim();
      }
    }
    return AdminNotificationsException(
      backendMsg ?? fallback ?? 'Failed to load notifications.',
      statusCode: res?.statusCode,
      cause: e,
    );
  }

  @override
  String toString() => 'AdminNotificationsException($statusCode): $message';
}
