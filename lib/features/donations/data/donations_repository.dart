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
import 'models/donation_init_data.dart';
import 'models/verify_result.dart';

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

  // ── Initiate Paystack payment for a single donation ─────────
  Future<DonationInitData> initiateDonation({
    String? donationId,
    required num amount,
    String currency = 'ZAR',
    String? note,
    String? callbackUrl,
  }) async {
    if (amount < 10) {
      throw const DonationException('Minimum donation amount is ₹ 10.');
    }
    if (note != null && note.length > 280) {
      throw const DonationException('Note must be 280 characters or fewer.');
    }
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'currency': currency,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (callbackUrl != null && callbackUrl.trim().isNotEmpty)
          'callbackUrl': callbackUrl.trim(),
      };
      final url = donationId != null && donationId.trim().isNotEmpty
          ? ApiEndpoints.donate(donationId)
          : ApiEndpoints.generalDonate;

      final res = await _apiClient.dio.post<dynamic>(url, data: body);
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const DonationException('Unexpected response from server.');
      }
      return DonationInitData.fromJson(data);
    } on DioException catch (e) {
      throw DonationException.fromDio(
        e,
        fallback: 'Could not start the donation.',
      );
    }
  }

  // ── Verify a Paystack reference (idempotent) ────────────────
  Future<VerifyResult> verifyPayment(String reference) async {
    if (reference.trim().isEmpty) {
      throw const DonationException('Missing payment reference.');
    }
    try {
      final res = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.verifyPayment(reference),
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw const DonationException('Unexpected response from server.');
      }
      return VerifyResult.fromJson(data, fallbackReference: reference);
    } on DioException catch (e) {
      throw DonationException.fromDio(
        e,
        fallback: 'Could not verify the payment.',
      );
    }
  }

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
      final list = _extractList(body)
          .map((e) => DonationContribution.fromJson(e as Map<String, dynamic>))
          .toList();
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
  List<dynamic> _extractList(dynamic body) {
    if (body is! Map) return const [];
    final keys = const [
      'donations',
      'contributions',
      'items',
      'results',
      'data',
    ];
    for (final k in keys) {
      final v = body[k];
      if (v is List) return v;
    }
    final data = body['data'];
    if (data is List) return data;
    if (data is Map) {
      for (final k in keys) {
        final v = data[k];
        if (v is List) return v;
      }
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
