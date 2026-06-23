// lib/features/cms/data/datasources/admin_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/models/admin_model.dart';
import 'package:satya_devotte_app/features/cms/models/invite_admin_result.dart';

class AdminRemoteDataSource {
  AdminRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  List<dynamic> _list(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return [];
    final map = Map<String, dynamic>.from(body);
    final d = map['data'];
    if (d is List) return d;
    if (d is Map) {
      for (final k in ['users', 'admins', 'data', 'items', 'results']) {
        if (d[k] is List) return d[k] as List;
      }
    }
    for (final k in ['users', 'admins', 'data', 'items', 'results']) {
      if (map[k] is List) return map[k] as List;
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

  // ── GET /superadmin/admins — paginated admin users (super admin) ───
  Future<({List<AdminModel> items, int page, int limit, int total, int totalPages})>
  getAdminUsersPage({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final q = search?.trim();
    if (q != null && q.isNotEmpty) {
      query['search'] = q;
    }

    try {
      final res = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.superadminAdmins,
        queryParameters: query,
      );
      final body = res.data;
      if (body == null) {
        return (
          items: const <AdminModel>[],
          page: page,
          limit: limit,
          total: 0,
          totalPages: 1,
        );
      }
      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ?? 'Could not load admins.',
        );
      }
      return _parsePaginatedAdmins(
        body,
        page: page,
        limit: limit,
      );
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }

  // ── GET /superadmin/admins — all admin users (legacy helper) ───
  Future<List<AdminModel>> getAdminUsers() async {
    final result = await getAdminUsersPage(page: 1, limit: 100);
    return result.items;
  }

  ({List<AdminModel> items, int page, int limit, int total, int totalPages})
  _parsePaginatedAdmins(
    Map<String, dynamic> body, {
    required int page,
    required int limit,
  }) {
    final items = _parseAdminList(_list(body));

    final data = body['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final pagination = dataMap['pagination'];
    final paginationMap = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};

    final resolvedPage = _asInt(
      paginationMap['page'] ?? dataMap['page'] ?? body['page'],
      page,
    );
    final resolvedLimit = _asInt(
      paginationMap['limit'] ?? dataMap['limit'] ?? body['limit'],
      limit,
    );
    final resolvedTotal = _asInt(
      paginationMap['total'] ?? dataMap['total'] ?? body['total'],
      items.length,
    );
    final fallbackPages = resolvedLimit <= 0
        ? 1
        : ((resolvedTotal + resolvedLimit - 1) ~/ resolvedLimit).clamp(1, 999999);
    final resolvedTotalPages = _asInt(
      paginationMap['totalPages'] ?? dataMap['totalPages'] ?? body['totalPages'],
      fallbackPages,
    );

    return (
      items: items,
      page: resolvedPage,
      limit: resolvedLimit,
      total: resolvedTotal,
      totalPages: resolvedTotalPages < 1 ? 1 : resolvedTotalPages,
    );
  }

  List<AdminModel> _parseAdminList(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((e) => AdminModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ── GET /admin/regular-users — all users with role=user ───────
  Future<List<AdminModel>> getRegularUsers() async {
    final res = await _apiClient.dio.get('/api/v1/admin/regular-users');
    return _list(
      res.data as Map<String, dynamic>,
    ).map((e) => AdminModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /admin/regular-users?page=&limit= — paginated users list.
  Future<({List<AdminModel> items, int page, int limit, int total, int totalPages})>
  getRegularUsersPage({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/v1/admin/regular-users',
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = res.data;
    if (body == null) {
      return (
        items: const <AdminModel>[],
        page: page,
        limit: limit,
        total: 0,
        totalPages: 1,
      );
    }
    final items = _list(body)
        .whereType<Map>()
        .map((e) => AdminModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final data = body['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final pagination = dataMap['pagination'];
    final paginationMap = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};

    final resolvedPage = _asInt(
      paginationMap['page'] ?? dataMap['page'] ?? body['page'],
      page,
    );
    final resolvedLimit = _asInt(
      paginationMap['limit'] ?? dataMap['limit'] ?? body['limit'],
      limit,
    );
    final resolvedTotal = _asInt(
      paginationMap['total'] ?? dataMap['total'] ?? body['total'],
      items.length,
    );
    final fallbackPages = resolvedLimit <= 0
        ? 1
        : ((resolvedTotal + resolvedLimit - 1) ~/ resolvedLimit).clamp(1, 999999);
    final resolvedTotalPages = _asInt(
      paginationMap['totalPages'] ?? dataMap['totalPages'] ?? body['totalPages'],
      fallbackPages,
    );

    return (
      items: items,
      page: resolvedPage,
      limit: resolvedLimit,
      total: resolvedTotal,
      totalPages: resolvedTotalPages < 1 ? 1 : resolvedTotalPages,
    );
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

  // ── DELETE /superadmin/admins/:id — remove admin user ────────
  Future<void> removeAdmin(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('Cannot remove admin: id is missing.');
    }
    try {
      await _apiClient.dio.delete<void>(ApiEndpoints.superadminAdmin(id));
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
  }

  /// POST `/api/v1/superadmin/admins/:id/password-reset-link` — generate a
  /// password reset link for an existing admin.
  Future<String> resendPasswordResetLink(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('Cannot generate reset link: admin id is missing.');
    }
    final path = ApiEndpoints.superadminAdminPasswordResetLink(id);
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(path);
      final body = res.data;
      if (body == null) {
        throw Exception('Empty response from server.');
      }
      if (body['success'] == false) {
        throw Exception(
          body['message']?.toString() ??
              'Could not generate password reset link.',
        );
      }
      final data = body['data'];
      String? link;
      if (data is Map) {
        link = data['passwordResetLink']?.toString();
      }
      link ??= body['passwordResetLink']?.toString();
      if (link == null || link.trim().isEmpty) {
        throw Exception('No password reset link was returned.');
      }
      return link.trim();
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      rethrow;
    }
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
