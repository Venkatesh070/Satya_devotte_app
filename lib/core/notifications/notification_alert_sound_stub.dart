import 'package:flutter/services.dart';

/// Short alert on mobile / desktop native builds.
Future<void> playAdminNotificationAlert({String? title, String? body}) async {
  try {
    await SystemSound.play(SystemSoundType.alert);
  } catch (_) {}
}
