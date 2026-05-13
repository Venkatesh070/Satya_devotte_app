// Wraps the admin notifications backend (Send / List / Get / Cancel).
import 'package:dio/dio.dart';

import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/notifications/data/models/app_notification.dart';
import 'package:satya_devotte_app/features/notifications/data/models/send_notification_request.dart';
import 'package:satya_devotte_app/features/notifications/data/notifications_exception.dart';

/// Paginated response for the admin notifications list.
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AppNotification> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  /// POST /notifications/send
  Future<AppNotification> sendNotification(
    SendNotificationRequest req,
  ) async {
    _validate(req);
    try {
      final res = await _api.dio.post(
        ApiEndpoints.notificationsSend,
        data: req.toJson(),
      );
      return _readNotification(res.data);
    } on DioException catch (e) {
      throw NotificationsException.fromDio(
        e,
        fallback: 'Failed to send notification.',
      );
    }
  }

  /// GET /notifications?page&limit&status&audience
  Future<NotificationsPage> listNotifications({
    int page = 1,
    int limit = 10,
    String? status,
    String? audience,
  }) async {
    try {
      final res = await _api.dio.get(
        ApiEndpoints.notifications,
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty) 'status': status,
          if (audience != null && audience.isNotEmpty) 'audience': audience,
        },
      );
      return _readList(res.data, requestedPage: page, requestedLimit: limit);
    } on DioException catch (e) {
      throw NotificationsException.fromDio(
        e,
        fallback: 'Failed to load notifications.',
      );
    }
  }

  /// GET /notifications/:id
  Future<AppNotification> getNotification(String id) async {
    try {
      final res = await _api.dio.get(ApiEndpoints.notification(id));
      return _readNotification(res.data);
    } on DioException catch (e) {
      throw NotificationsException.fromDio(
        e,
        fallback: 'Failed to load notification.',
      );
    }
  }

  /// POST /notifications/:id/cancel
  Future<AppNotification> cancelNotification(String id) async {
    try {
      final res = await _api.dio.post(ApiEndpoints.cancelNotification(id));
      return _readNotification(res.data);
    } on DioException catch (e) {
      throw NotificationsException.fromDio(
        e,
        fallback: 'Failed to cancel notification.',
      );
    }
  }

  // ── Internals ───────────────────────────────────────────────────

  void _validate(SendNotificationRequest req) {
    final title = req.title.trim();
    final body = req.body.trim();
    if (title.isEmpty) {
      throw const NotificationsException('Title is required.');
    }
    if (title.length > 120) {
      throw const NotificationsException(
        'Title must be 120 characters or less.',
      );
    }
    if (body.isEmpty) {
      throw const NotificationsException('Message is required.');
    }
    if (body.length > 1000) {
      throw const NotificationsException(
        'Message must be 1000 characters or less.',
      );
    }
    const validAudiences = {
      'ALL',
      'USERS',
      'ADMINS',
      'SUPERADMIN',
      'USER_IDS',
    };
    if (!validAudiences.contains(req.audience.toUpperCase())) {
      throw NotificationsException('Unknown audience: ${req.audience}.');
    }
    if (req.audience.toUpperCase() == 'USER_IDS' && req.userIds.isEmpty) {
      throw const NotificationsException(
        'Select at least one user when targeting specific users.',
      );
    }
    if (req.scheduledAt != null &&
        !req.scheduledAt!.isAfter(DateTime.now())) {
      throw const NotificationsException(
        'Schedule time must be in the future.',
      );
    }
  }

  AppNotification _readNotification(dynamic body) {
    if (body is! Map) {
      throw const NotificationsException('Malformed server response.');
    }
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      final notif = data['notification'];
      if (notif is Map<String, dynamic>) {
        return AppNotification.fromJson(notif);
      }
      return AppNotification.fromJson(data);
    }
    return AppNotification.fromJson(map);
  }

  NotificationsPage _readList(
    dynamic body, {
    required int requestedPage,
    required int requestedLimit,
  }) {
    if (body is! Map) {
      return NotificationsPage(
        items: const [],
        page: requestedPage,
        limit: requestedLimit,
        total: 0,
        totalPages: 1,
      );
    }
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};

    // Items can live under data.items / data.notifications / data / top-level.
    List<dynamic> rawItems;
    if (dataMap['items'] is List) {
      rawItems = dataMap['items'] as List;
    } else if (dataMap['notifications'] is List) {
      rawItems = dataMap['notifications'] as List;
    } else if (data is List) {
      rawItems = data;
    } else if (map['items'] is List) {
      rawItems = map['items'] as List;
    } else {
      rawItems = const [];
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);

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
      paginationMap['page'] ?? dataMap['page'] ?? map['page'],
      requestedPage,
    );
    final resolvedLimit = asInt(
      paginationMap['limit'] ?? dataMap['limit'] ?? map['limit'],
      requestedLimit,
    );
    final resolvedTotal = asInt(
      paginationMap['total'] ??
          paginationMap['totalItems'] ??
          dataMap['total'] ??
          map['total'],
      items.length,
    );
    final computed = (resolvedTotal == 0 || resolvedLimit == 0)
        ? 1
        : ((resolvedTotal + resolvedLimit - 1) ~/ resolvedLimit);
    final resolvedTotalPages = asInt(
      paginationMap['totalPages'] ??
          paginationMap['pages'] ??
          dataMap['totalPages'] ??
          map['totalPages'],
      computed,
    );

    return NotificationsPage(
      items: items,
      page: resolvedPage,
      limit: resolvedLimit,
      total: resolvedTotal,
      totalPages: resolvedTotalPages < 1 ? 1 : resolvedTotalPages,
    );
  }
}
