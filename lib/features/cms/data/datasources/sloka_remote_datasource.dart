// lib/features/cms/data/datasources/sloka_remote_datasource.dart
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/features/cms/models/sloka_model.dart';

class SlokaRemoteDataSource {
  SlokaRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  static const String _base = '/api/v1/daily-slokas';
  static const String _create = '/api/v1/daily-slokas/create-sloka';

  Map<String, dynamic> _single(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) {
      for (final k in ['sloka', 'shloka', 'dailySloka', 'data']) {
        if (d[k] is Map<String, dynamic>) return d[k] as Map<String, dynamic>;
      }
      return d;
    }
    return body;
  }

  List<dynamic> _list(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is List) return d;
    if (d is Map) {
      for (final k in ['slokas', 'data', 'items']) {
        if (d[k] is List) return d[k] as List;
      }
    }
    for (final k in ['slokas', 'data', 'items']) {
      if (body[k] is List) return body[k] as List;
    }
    return [];
  }

  // ── GET /api/v1/daily-slokas?date=DD-MM-YYYY ─────────────────
  Future<SlokaModel?> getSlokaByDate(String date) async {
    try {
      final res = await _apiClient.dio.get(
        _base,
        queryParameters: {'date': date},
      );
      final body = res.data as Map<String, dynamic>;
      final d = body['data'];
      if (d is List && d.isNotEmpty) {
        return SlokaModel.fromJson(d.first as Map<String, dynamic>);
      }
      if (d is Map<String, dynamic>) {
        return SlokaModel.fromJson(_single(body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── GET /api/v1/daily-slokas ──────────────────────────────────
  Future<List<SlokaModel>> getRecentSlokas() async {
    try {
      final res = await _apiClient.dio.get(_base);
      return _list(
        res.data as Map<String, dynamic>,
      ).map((e) => SlokaModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── POST /api/v1/daily-slokas/create-sloka ───────────────────
  Future<SlokaModel> createOrUpdateSloka(SlokaModel sloka) async {
    final res = await _apiClient.dio.post(
      _create,
      data: sloka.toJson(), // sends { sloka, author, date: DD-MM-YYYY }
    );
    return SlokaModel.fromJson(_single(res.data as Map<String, dynamic>));
  }
}
