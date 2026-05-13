// One row from the admin broadcast history.
//
// Source: GET /api/v1/notifications and the wrapped object returned by
// POST /api/v1/notifications/send.
import 'package:intl/intl.dart';

/// Status of an admin broadcast on the server.
enum NotificationStatus {
  pending,
  scheduled,
  sending,
  sent,
  failed,
  cancelled,
}

NotificationStatus _statusFromString(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'SCHEDULED':
      return NotificationStatus.scheduled;
    case 'SENDING':
      return NotificationStatus.sending;
    case 'SENT':
      return NotificationStatus.sent;
    case 'FAILED':
      return NotificationStatus.failed;
    case 'CANCELLED':
    case 'CANCELED':
      return NotificationStatus.cancelled;
    case 'PENDING':
    default:
      return NotificationStatus.pending;
  }
}

String _statusToWire(NotificationStatus s) {
  switch (s) {
    case NotificationStatus.pending:
      return 'PENDING';
    case NotificationStatus.scheduled:
      return 'SCHEDULED';
    case NotificationStatus.sending:
      return 'SENDING';
    case NotificationStatus.sent:
      return 'SENT';
    case NotificationStatus.failed:
      return 'FAILED';
    case NotificationStatus.cancelled:
      return 'CANCELLED';
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.status,
    required this.successCount,
    required this.failureCount,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.imageUrl,
    this.data,
  });

  final String id;
  final String title;
  final String body;

  /// `ALL | USERS | ADMINS | SUPERADMIN | USER_IDS`.
  final String audience;
  final NotificationStatus status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int successCount;
  final int failureCount;
  final DateTime createdAt;
  final String? imageUrl;
  final Map<String, dynamic>? data;

  String get statusLabel => _statusToWire(status);

  int get totalRecipients => successCount + failureCount;

  String get audienceLabel {
    switch (audience.toUpperCase()) {
      case 'ALL':
        return 'All Users';
      case 'USERS':
        return 'Users';
      case 'ADMINS':
        return 'Admins';
      case 'SUPERADMIN':
        return 'Super Admin';
      case 'USER_IDS':
        return 'Specific Users';
      default:
        return audience;
    }
  }

  /// Pretty timestamp for list rows. Prefers `sentAt`, then `scheduledAt`,
  /// then `createdAt`.
  String get formattedTimestamp {
    final dt = sentAt ?? scheduledAt ?? createdAt;
    return DateFormat('d MMM yyyy, h:mm a').format(dt.toLocal());
  }

  static String _str(dynamic v) => (v ?? '').toString().trim();

  static DateTime? _date(dynamic v) {
    final s = _str(v);
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final audience = _str(json['audience']);
    final data = json['data'];
    return AppNotification(
      id: _str(json['_id'] ?? json['id']),
      title: _str(json['title']),
      body: _str(json['body']),
      audience: audience.isEmpty ? 'ALL' : audience.toUpperCase(),
      status: _statusFromString(_str(json['status'])),
      scheduledAt: _date(json['scheduledAt']),
      sentAt: _date(json['sentAt']),
      successCount: _int(json['successCount']),
      failureCount: _int(json['failureCount']),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      imageUrl: () {
        final s = _str(json['imageUrl']);
        return s.isEmpty ? null : s;
      }(),
      data: data is Map<String, dynamic> ? Map<String, dynamic>.from(data) : null,
    );
  }
}
