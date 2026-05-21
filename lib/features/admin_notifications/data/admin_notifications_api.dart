import 'package:dio/dio.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/admin_notifications_exception.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/models/admin_notification_item.dart';

class AdminNotificationsPage {
  const AdminNotificationsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.unreadCount,
  });

  final List<AdminNotificationItem> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final int? unreadCount;
}

class AdminNotificationsApi {
  AdminNotificationsApi(this._api);
  final ApiClient _api;

  Future<AdminNotificationsPage> list({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    String? type,
  }) async {
    try {
      final res = await _api.dio.get(
        ApiEndpoints.adminNotifications,
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          if (unreadOnly) 'unreadOnly': true,
          if (type != null && type.isNotEmpty) 'type': type,
        },
      );
      return _readList(res.data, requestedPage: page, requestedLimit: limit);
    } on DioException catch (e) {
      throw AdminNotificationsException.fromDio(
        e,
        fallback: 'Failed to load activity.',
      );
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _api.dio.get(ApiEndpoints.adminNotificationsUnreadCount);
      return _readUnreadCount(res.data);
    } on DioException catch (e) {
      throw AdminNotificationsException.fromDio(
        e,
        fallback: 'Failed to load unread count.',
      );
    }
  }

  Future<AdminNotificationItem> getById(String id) async {
    try {
      final res = await _api.dio.get(ApiEndpoints.adminNotification(id));
      return _readOne(res.data);
    } on DioException catch (e) {
      throw AdminNotificationsException.fromDio(
        e,
        fallback: 'Failed to load notification.',
      );
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.dio.post(ApiEndpoints.adminNotificationRead(id));
    } on DioException catch (e) {
      throw AdminNotificationsException.fromDio(
        e,
        fallback: 'Failed to mark notification as read.',
      );
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.dio.post(ApiEndpoints.adminNotificationsReadAll);
    } on DioException catch (e) {
      throw AdminNotificationsException.fromDio(
        e,
        fallback: 'Failed to mark all as read.',
      );
    }
  }

  AdminNotificationItem _readOne(dynamic body) {
    if (body is! Map) {
      throw const AdminNotificationsException('Malformed server response.');
    }
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      final notif = data['notification'];
      if (notif is Map<String, dynamic>) {
        return AdminNotificationItem.fromJson(notif);
      }
      return AdminNotificationItem.fromJson(data);
    }
    return AdminNotificationItem.fromJson(map);
  }

  int _readUnreadCount(dynamic body) {
    if (body is! Map) return 0;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : data is Map
            ? Map<String, dynamic>.from(data)
            : map;

    final candidates = [
      dataMap['unreadCount'],
      dataMap['count'],
      map['unreadCount'],
    ];
    for (final v in candidates) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  AdminNotificationsPage _readList(
    dynamic body, {
    required int requestedPage,
    required int requestedLimit,
  }) {
    if (body is! Map) {
      return AdminNotificationsPage(
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
        : data is Map
            ? Map<String, dynamic>.from(data)
            : const <String, dynamic>{};

    List<dynamic> rawItems;
    if (dataMap['notifications'] is List) {
      rawItems = dataMap['notifications'] as List;
    } else if (dataMap['items'] is List) {
      rawItems = dataMap['items'] as List;
    } else if (data is List) {
      rawItems = data;
    } else {
      rawItems = const [];
    }

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(AdminNotificationItem.fromJson)
        .toList(growable: false);

    final pagination = dataMap['pagination'];
    final paginationMap = pagination is Map<String, dynamic>
        ? pagination
        : pagination is Map
            ? Map<String, dynamic>.from(pagination)
            : const <String, dynamic>{};

    int asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final resolvedPage = asInt(
      paginationMap['page'] ?? dataMap['page'],
      requestedPage,
    );
    final resolvedLimit = asInt(
      paginationMap['limit'] ?? dataMap['limit'],
      requestedLimit,
    );
    final resolvedTotal = asInt(
      paginationMap['total'] ?? dataMap['total'],
      items.length,
    );
    final computed = (resolvedTotal == 0 || resolvedLimit == 0)
        ? 1
        : ((resolvedTotal + resolvedLimit - 1) ~/ resolvedLimit);
    final resolvedTotalPages = asInt(
      paginationMap['totalPages'] ?? dataMap['totalPages'],
      computed,
    );

    int? listUnread;
    final uc = dataMap['unreadCount'];
    if (uc is int) {
      listUnread = uc;
    } else if (uc is num) {
      listUnread = uc.toInt();
    } else if (uc is String) {
      listUnread = int.tryParse(uc);
    }

    return AdminNotificationsPage(
      items: items,
      page: resolvedPage,
      limit: resolvedLimit,
      total: resolvedTotal,
      totalPages: resolvedTotalPages < 1 ? 1 : resolvedTotalPages,
      unreadCount: listUnread,
    );
  }
}
