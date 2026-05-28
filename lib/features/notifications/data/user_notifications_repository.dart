import 'package:dio/dio.dart';

import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/notifications/data/notifications_exception.dart';

class UserNotificationItem {
  const UserNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.data,
    this.type,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>? data;
  final String? type;

  String? get orderId {
    final direct = _clean((data?['orderId'] ?? data?['order_id']));
    if (direct != null) return direct;
    return null;
  }

  String? get orderStatus {
    final status = _clean(
      data?['orderStatus'] ?? data?['order_status'] ?? data?['status'],
    );
    return status?.toUpperCase();
  }

  String? get notificationType {
    final raw = _clean(type ?? data?['type']);
    return raw?.toUpperCase();
  }

  bool get isDeliveredOrderNotification {
    final kind = notificationType;
    if (kind == 'ORDER_DELIVERED') return true;
    final status = orderStatus;
    if (status == null) return false;
    return status == 'DELIVERED' || status == 'FULFILLED';
  }

  bool get isOrderTypeNotification {
    final kind = notificationType;
    if (kind == null) return false;
    return kind.startsWith('ORDER_');
  }

  static String? _clean(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory UserNotificationItem.fromJson(Map<String, dynamic> json) {
    final createdRaw = (json['createdAt'] ?? json['created_at'] ?? '').toString();
    final createdAt = DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now();
    return UserNotificationItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: createdAt,
      read: json['read'] == true,
      type: _clean(json['type']),
      data: () {
        final raw = json['data'];
        if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
        if (raw is Map) {
          return raw.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
        return null;
      }(),
    );
  }
}

class UserNotificationsPage {
  const UserNotificationsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.unreadCount,
  });

  final List<UserNotificationItem> items;
  final int page;
  final int limit;
  final int totalPages;
  final int? unreadCount;
}

class UserNotificationsRepository {
  UserNotificationsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<UserNotificationsPage> list({
    required int page,
    required int limit,
  }) async {
    try {
      final res = await _apiClient.dio.get(
        ApiEndpoints.userNotifications,
        queryParameters: <String, dynamic>{'page': page, 'limit': limit},
      );
      return _parseList(res.data, page: page, limit: limit);
    } on DioException catch (e) {
      throw NotificationsException.fromDio(
        e,
        fallback: 'Failed to load notifications.',
      );
    }
  }

  UserNotificationsPage _parseList(
    dynamic body, {
    required int page,
    required int limit,
  }) {
    if (body is! Map) {
      return UserNotificationsPage(
        items: const [],
        page: page,
        limit: limit,
        totalPages: 1,
        unreadCount: 0,
      );
    }
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};

    final rawItems = dataMap['items'] is List
        ? dataMap['items'] as List
        : dataMap['notifications'] is List
        ? dataMap['notifications'] as List
        : data is List
        ? data
        : const [];

    final items = rawItems
        .whereType<Map>()
        .map((e) => UserNotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final pagination = dataMap['pagination'];
    final paginationMap = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};

    int asInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final resolvedPage = asInt(
      paginationMap['page'] ?? dataMap['page'] ?? map['page'],
      page,
    );
    final resolvedLimit = asInt(
      paginationMap['limit'] ?? dataMap['limit'] ?? map['limit'],
      limit,
    );
    final totalPages = asInt(
      paginationMap['totalPages'] ?? dataMap['totalPages'] ?? map['totalPages'],
      1,
    );
    final unreadCount = asInt(
      dataMap['unreadCount'] ?? map['unreadCount'],
      -1,
    );

    return UserNotificationsPage(
      items: items,
      page: resolvedPage,
      limit: resolvedLimit,
      totalPages: totalPages < 1 ? 1 : totalPages,
      unreadCount: unreadCount < 0 ? null : unreadCount,
    );
  }
}
