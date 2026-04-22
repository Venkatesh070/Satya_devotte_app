import 'package:satya_devotte_app/core/services/media_upload_service.dart';
// lib/features/cms/data/datasources/donation_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/features/cms/models/donation_model.dart';

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
  ) async {
    final res = await _apiClient.dio.patch(
      '/api/v1/donations/$id',
      data: FormData.fromMap({'title': title, 'description': description}),
    );
    return DonationModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  // ── DELETE /donations/{id} ────────────────────────────────────
  Future<void> deleteDonation(String id) async {
    await _apiClient.dio.delete('/api/v1/donations/$id');
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
