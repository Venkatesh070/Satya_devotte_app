import 'notification_alert_sound_stub.dart'
    if (dart.library.html) 'notification_alert_sound_web.dart' as impl;

/// Plays a short alert when a new admin Activity notification arrives.
Future<void> playAdminNotificationAlert({String? title, String? body}) =>
    impl.playAdminNotificationAlert(title: title, body: body);
