// lib/features/cms/data/datasources/admin_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';
import 'package:satya_devotte_app/features/cms/models/invite_admin_result.dart';

class AdminRemoteDataSource {
  AdminRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  List<dynamic> _list(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is List) return d;
    if (d is Map) {
      for (final k in ['users', 'admins', 'data', 'items', 'results']) {
        if (d[k] is List) return d[k] as List;
      }
    }
    for (final k in ['users', 'admins', 'data', 'items', 'results']) {
      if (body[k] is List) return body[k] as List;
    }
    return [];
  }

  Map<String, dynamic> _single(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is Map<String, dynamic>) {
      for (final k in ['user', 'admin', 'data']) {
        if (d[k] is Map<String, dynamic>) return d[k] as Map<String, dynamic>;
      }
      return d;
    }
    return body;
  }

  // ── GET /admin/users — all admin users ────────────────────────
  Future<List<AdminModel>> getAdminUsers() async {
    final res = await _apiClient.dio.get('/api/v1/admin/users');
    return _list(
      res.data as Map<String, dynamic>,
    ).map((e) => AdminModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /admin/regular-users — all users with role=user ───────
  Future<List<AdminModel>> getRegularUsers() async {
    final res = await _apiClient.dio.get('/api/v1/admin/regular-users');
    return _list(
      res.data as Map<String, dynamic>,
    ).map((e) => AdminModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /superadmin/admins — invite a new admin (Super Admin only).
  Future<InviteAdminResult> inviteAdmin({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': email.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.superadminCreateAdmin,
        data: payload,
      );
      final body = res.data;
      if (body == null) {
        throw Exception('Empty response from server.');
      }
      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Could not create admin invite.',
        );
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response data.');
      }
      final link = data['passwordResetLink']?.toString();
      final delivered = data['emailDelivered'] == true;
      return InviteAdminResult(
        emailDelivered: delivered,
        passwordResetLink:
            (link != null && link.isNotEmpty) ? link : null,
      );
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }

  // ── POST /admin/create-admin — promote user to admin (legacy) ─
  // body: { email: 'user@example.com' }  OR  { userId: 'xxx' }
  Future<AdminModel> createAdmin(String emailOrId) async {
    // Try email first; if it looks like a MongoDB ID, use userId
    final isId = emailOrId.length == 24 && !emailOrId.contains('@');
    final body = isId ? {'userId': emailOrId} : {'email': emailOrId};

    final res = await _apiClient.dio.post(
      '/api/v1/admin/create-admin',
      data: body,
    );
    return AdminModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  // ── PATCH /admin/remove-admin/{id} — demote admin to user ─────
  Future<AdminModel> removeAdmin(String id) async {
    final res = await _apiClient.dio.patch('/api/v1/admin/remove-admin/$id');
    return AdminModel.fromJson(_single(res.data as Map<String, dynamic>));
  }

  /// PATCH `/api/v1/superadmin/admins/:id/panel-access` — toggle whether the
  /// admin can sign in to the admin panel. Returns the updated admin.
  Future<AdminModel> setPanelAccess({
    required String id,
    required bool canLoginAdminPanel,
  }) async {
    if (id.trim().isEmpty) {
      // Without this guard, an empty id would produce
      // `/api/v1/superadmin/admins//panel-access` which the backend
      // matches with no route and returns `Route not found`.
      throw Exception('Cannot update panel access: admin id is missing.');
    }
    final path = ApiEndpoints.superadminAdminPanelAccess(id);
    try {
      // Temporary diagnostic so the exact PATCH URL + body show up in the
      // console. Remove once the endpoint is confirmed wired up.
      // ignore: avoid_print
      print(
        'setPanelAccess → PATCH $path  body={canLoginAdminPanel: $canLoginAdminPanel}',
      );
      final res = await _apiClient.dio.patch<Map<String, dynamic>>(
        path,
        data: {'canLoginAdminPanel': canLoginAdminPanel},
      );
      final body = res.data;
      if (body == null) {
        throw Exception('Empty response from server.');
      }
      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ?? 'Could not update panel access.',
        );
      }
      return AdminModel.fromJson(_single(body));
    } on DioException catch (e) {
      // ignore: avoid_print
      print(
        'setPanelAccess ✗ ${e.response?.statusCode} ${e.requestOptions.uri} → ${e.response?.data}',
      );
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }
}
