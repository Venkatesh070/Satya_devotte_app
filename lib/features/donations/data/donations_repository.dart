// User-facing donations repository.
//
// Thin wrapper over the existing shared Dio client. All endpoints inherit
// the project-wide auth interceptor (Firebase ID / session token), so
// nothing extra is needed for authorisation here.
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';

import 'donation_exception.dart';
import 'models/donation.dart';
import 'models/donation_contribution.dart';

class DonationsRepository {
  DonationsRepository(this._apiClient);
  final ApiClient _apiClient;

  // ── List approved + visible donations ───────────────────────
  Future<List<Donation>> listDonations({int page = 1, int limit = 20}) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.donations,
        queryParameters: {'page': page, 'limit': limit},
      );
      return _extractList(
        res.data,
      ).map((e) => Donation.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw DonationException.fromDio(e, fallback: 'Failed to load donations.');
    }
  }

  // In-app donation initiate / verify intentionally omitted — voluntary
  // donations complete only on the public website (Guideline 3.2.2(iv)).

  // ── Paginated contribution history ──────────────────────────
  Future<({List<DonationContribution> items, int total, int totalPages})>
  listMyContributions({
    int page = 1,
    int limit = 10,
    String? paymentStatus,
  }) async {
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myContributions,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (paymentStatus != null && paymentStatus.trim().isNotEmpty)
            'paymentStatus': paymentStatus.trim().toUpperCase(),
        },
      );
      final body = res.data;
      final list = _extractList(body).map(_asStringKeyedMap).map((e) {
        return DonationContribution.fromJson(e);
      }).toList();
      final total = _readInt(body, ['total'], fallback: list.length);
      final totalPages = _readInt(
        body,
        ['totalPages', 'pages'],
        fallback: (limit > 0) ? ((total / limit).ceil().clamp(1, 1 << 30)) : 1,
      );
      return (items: list, total: total, totalPages: totalPages);
    } on DioException catch (e) {
      throw DonationException.fromDio(
        e,
        fallback: 'Failed to load your contributions.',
      );
    }
  }

  // ── helpers ─────────────────────────────────────────────────
  static Map<String, dynamic> _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const DonationException('Unexpected contribution payload.');
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return const [];

    // Prefer the current API shape: { data: { items|donations: [...], pagination } }
    final data = body['data'];
    if (data is Map) {
      final items = data['items'] ??
          data['donations'] ??
          data['contributions'] ??
          data['results'];
      if (items is List) return items;
    }
    if (data is List) return data;

    final keys = const [
      'items',
      'contributions',
      'donations',
      'results',
    ];
    for (final k in keys) {
      final v = body[k];
      if (v is List) return v;
    }
    return const [];
  }

  int _readInt(dynamic body, List<String> keys, {required int fallback}) {
    Map? candidate;
    if (body is Map) {
      candidate = body;
      final data = body['data'];
      if (data is Map) {
        final pag = data['pagination'];
        if (pag is Map)
          candidate = pag;
        else
          candidate = data;
      }
    }
    if (candidate == null) return fallback;
    for (final k in keys) {
      final v = candidate[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final p = int.tryParse(v);
        if (p != null) return p;
      }
    }
    return fallback;
  }
}
