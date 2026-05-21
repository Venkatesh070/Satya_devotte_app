import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';

/// Auth-scoped favourite deities (Swagger: Auth → favorite-deities).
class FavoriteDeitiesRemoteDataSource {
  FavoriteDeitiesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// GET `/api/v1/auth/favorite-deities` — returns full deity documents.
  Future<List<Map<String, dynamic>>> fetchFavoriteDeities() async {
    final response = await _apiClient.dio.get<dynamic>(
      ApiEndpoints.favoriteDeities,
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'GET favorite deities failed (${response.statusCode}).',
      );
    }
    return _extractDeityList(response.data);
  }

  /// POST `/api/v1/auth/favorite-deities/{deityId}` — idempotent add.
  Future<void> addFavorite(String deityId) async {
    final id = deityId.trim();
    if (id.isEmpty) {
      throw ArgumentError('deityId must not be empty');
    }
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.favoriteDeity(id),
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Add favorite failed (${response.statusCode}).',
      );
    }
  }

  /// DELETE `/api/v1/auth/favorite-deities/{deityId}` — remove favourite.
  Future<void> removeFavorite(String deityId) async {
    final id = deityId.trim();
    if (id.isEmpty) {
      throw ArgumentError('deityId must not be empty');
    }
    final response = await _apiClient.dio.delete<dynamic>(
      ApiEndpoints.favoriteDeity(id),
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Remove favorite failed (${response.statusCode}).',
      );
    }
  }

  List<Map<String, dynamic>> _extractDeityList(dynamic payload) {
    dynamic data = payload;
    if (payload is Map) {
      final root = Map<String, dynamic>.from(payload);
      data =
          root['data'] ??
          root['deities'] ??
          root['results'] ??
          root['items'] ??
          root['favorites'];
      if (data is Map) {
        data = data['deities'] ?? data['items'] ?? data['docs'] ?? data;
      }
    }
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
}
