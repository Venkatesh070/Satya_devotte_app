import 'package:satya_devotte_app/features/admin_notifications/data/admin_notifications_api.dart';
import 'package:satya_devotte_app/features/admin_notifications/data/models/admin_notification_item.dart';

class AdminNotificationsRepository {
  AdminNotificationsRepository(this._api);
  final AdminNotificationsApi _api;

  Future<AdminNotificationsPage> list({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    String? type,
  }) =>
      _api.list(
        page: page,
        limit: limit,
        unreadOnly: unreadOnly,
        type: type,
      );

  Future<int> unreadCount() => _api.unreadCount();

  Future<AdminNotificationItem> getById(String id) => _api.getById(id);

  Future<void> markRead(String id) => _api.markRead(id);

  Future<void> markAllRead() => _api.markAllRead();
}
