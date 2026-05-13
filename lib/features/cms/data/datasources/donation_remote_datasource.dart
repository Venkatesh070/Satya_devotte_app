import 'package:satya_devotte_app/core/services/media_upload_service.dart';
// lib/features/cms/data/datasources/donation_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/donation_model.dart';
import 'package:satya_devotte_app/features/donations/data/models/donation_contribution.dart';

/// Paginated bundle returned by [DonationRemoteDataSource.getAllContributions].
class AdminContributionsPage {
  const AdminContributionsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<DonationContribution> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

class DonationRemoteDataSource {
  DonationRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  List<dynamic> _list(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is List) return d;
    if (d is Map<String, dynamic>) {
      for (final k in ['donations', 'data', 'items', 'results']) {
        final v = d[k];
        if (v is List) return v;
      }
    }
    for (final k in ['donations', 'data', 'items', 'results']) {
      final v = body[k];
      if (v is List) return v;
    }
    return [];
  }

  Map<String, dynamic> _single(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) {
      for (final k in ['donation', 'data']) {
        if (d[k] is Map<String, dynamic>) return d[k] as Map<String, dynamic>;
      }
      return d;
    }
    return body;
  }

  // ── GET /donations/my — admin's own ──────────────────────────
  Future<List<DonationModel>> getMyDonations() async {
    final res = await _apiClient.dio.get('/api/v1/donations/my');
    return _list(
      res.data as Map<String, dynamic>,
    ).map((e) => DonationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /donations/all — superadmin ──────────────────────────
  Future<List<DonationModel>> getAllDonations() async {
    final res = await _apiClient.dio.get('/api/v1/donations/all');
    return _list(
      res.data as Map<String, dynamic>,
    ).map((e) => DonationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── POST /donations/create-donation — multipart/form-data ────
  // Fields: title* (string), description (string), image* ($binary)
  Future<DonationModel> createDonation({
    required String title,
    String description = '',
    PickedFile? image, // picked file sent directly as multipart
  }) async {
    final fields = <String, dynamic>{
      'title': title,
      'description': description,
    };
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    final res = await _apiClient.dio.post(
      '/api/v1/donations/create-donation',
      data: FormData.fromMap(fields),
    );
    return DonationModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  // ── PATCH /donations/{id} — update ───────────────────────────
  Future<DonationModel> updateDonation(
    String id,
    String title,
    String description,
    {PickedFile? image}
  ) async {
    final fields = <String, dynamic>{'title': title, 'description': description};
    if (image != null) {
      fields['image'] = MultipartFile.fromBytes(
        image.bytes,
        filename: image.filename,
      );
    }
    final res = await _apiClient.dio.patch(
      '/api/v1/donations/$id',
      data: FormData.fromMap(fields),
    );
    return DonationModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  // ── DELETE /donations/{id} ────────────────────────────────────
  Future<void> deleteDonation(String id) async {
    await _apiClient.dio.delete('/api/v1/donations/$id');
  }

  // ── GET /donations/contributions/all — superadmin ────────────
  // Paginated list of every contribution across the platform.
  //   • [page]          1-based page number
  //   • [limit]         items per page
  //   • [paymentStatus] optional filter (PAID | PENDING | FAILED)
  Future<AdminContributionsPage> getAllContributions({
    int page = 1,
    int limit = 20,
    String? paymentStatus,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (paymentStatus != null && paymentStatus.isNotEmpty)
        'paymentStatus': paymentStatus,
    };
    final res = await _apiClient.dio.get(
      ApiEndpoints.allContributions,
      queryParameters: query,
    );
    final body = (res.data is Map<String, dynamic>)
        ? res.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final data = body['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};

    // Items may live under .data.items / .data / a top-level list.
    List<dynamic> rawItems;
    if (dataMap['items'] is List) {
      rawItems = dataMap['items'] as List;
    } else if (data is List) {
      rawItems = data;
    } else {
      rawItems = _list(body);
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(DonationContribution.fromJson)
        .toList(growable: false);

    // Pagination block can live under:
    //   • data.pagination.{page,limit,total,totalPages}   ← current server
    //   • data.{page,limit,total,totalPages}              ← legacy shape
    //   • body.{page,limit,total,totalPages}              ← legacy shape
    final pagination = dataMap['pagination'];
    final paginationMap = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};

    int asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final resolvedPage = asInt(
      paginationMap['page'] ??
          dataMap['page'] ??
          body['page'] ??
          body['currentPage'],
      page,
    );
    final resolvedLimit = asInt(
      paginationMap['limit'] ??
          dataMap['limit'] ??
          body['limit'] ??
          body['perPage'],
      limit,
    );
    final resolvedTotal = asInt(
      paginationMap['total'] ??
          paginationMap['totalItems'] ??
          dataMap['total'] ??
          dataMap['totalItems'] ??
          body['total'] ??
          body['totalItems'],
      items.length,
    );
    final computedPages = (resolvedTotal == 0 || resolvedLimit == 0)
        ? 1
        : ((resolvedTotal + resolvedLimit - 1) ~/ resolvedLimit);
    final resolvedTotalPages = asInt(
      paginationMap['totalPages'] ??
          paginationMap['pages'] ??
          dataMap['totalPages'] ??
          body['totalPages'] ??
          body['pages'],
      computedPages,
    );

    return AdminContributionsPage(
      items: items,
      page: resolvedPage,
      limit: resolvedLimit,
      total: resolvedTotal,
      totalPages: resolvedTotalPages < 1 ? 1 : resolvedTotalPages,
    );
  }

  // ── PUT /donations/review/{id} — superadmin ───────────────────
  Future<DonationModel> reviewDonation(
    String id,
    String status, {
    String? reason,
  }) async {
    final res = await _apiClient.dio.put(
      '/api/v1/donations/review/$id',
      data: {
        'status': status, // APPROVED | REJECTED
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return DonationModel.fromJson(_single(res.data as Map<String, dynamic>));
  }
}
