// Typed exception used across the donations data layer.
//
// Always carries a user-presentable `message`, plus optional `statusCode`
// from the underlying HTTP failure for richer telemetry.
import 'package:dio/dio.dart';

class DonationException implements Exception {
  const DonationException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  factory DonationException.fromDio(DioException e, {String? fallback}) {
    final res = e.response;
    String? backendMsg;
    if (res?.data is Map) {
      final m = res!.data as Map;
      final v = m['message'] ?? m['error'];
      if (v != null && v.toString().trim().isNotEmpty) {
        backendMsg = v.toString().trim();
      }
    }
    final msg = backendMsg ??
        fallback ??
        _friendlyForType(e.type) ??
        'Something went wrong. Please try again.';
    return DonationException(
      msg,
      statusCode: res?.statusCode,
      cause: e,
    );
  }

  static String? _friendlyForType(DioExceptionType t) {
    switch (t) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Network is slow. Please check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return null;
    }
  }

  @override
  String toString() => 'DonationException($statusCode): $message';
}
