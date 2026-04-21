// lib/features/cms/data/datasources/admin_remote_datasource.dart
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';

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

  // ── POST /admin/create-admin — promote user to admin ──────────
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
}
