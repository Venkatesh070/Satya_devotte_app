// Body shape for POST /api/v1/notifications/send.
//
// Serialization rules (mirroring the backend contract):
//   • drop `userIds` if empty,
//   • drop `scheduledAt` if null,
//   • coerce every value in `data` to `String` (FCM data-payload rule).
class SendNotificationRequest {
  const SendNotificationRequest({
    required this.title,
    required this.body,
    this.audience = 'ALL',
    this.userIds = const <String>[],
    this.data,
    this.imageUrl,
    this.scheduledAt,
  });

  final String title;
  final String body;

  /// `ALL | USERS | ADMINS | SUPERADMIN | USER_IDS`.
  final String audience;
  final List<String> userIds;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final DateTime? scheduledAt;

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{
      'title': title.trim(),
      'body': body.trim(),
      'audience': audience,
    };
    if (userIds.isNotEmpty) out['userIds'] = userIds;
    if (data != null && data!.isNotEmpty) {
      out['data'] = data!.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      out['imageUrl'] = imageUrl!.trim();
    }
    if (scheduledAt != null) {
      out['scheduledAt'] = scheduledAt!.toUtc().toIso8601String();
    }
    return out;
  }
}
