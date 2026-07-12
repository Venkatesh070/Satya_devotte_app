import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:satya_devotte_app/core/notifications/admin_notification_router.dart';
import 'package:satya_devotte_app/core/notifications/push_router.dart';
import 'package:satya_devotte_app/core/services/notification_platform.dart';

/// Temp file shared between background handler and main isolate.
/// `dart:io` works in any isolate — no platform channels needed.
const String _pendingNotificationFile = 'satya_pending.json';
const int _maxPendingNotifications = 50;

/// Top-level FCM background isolate handler.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')`
/// so the engine can locate it when the app is fully terminated. Persists
/// notification data to a temp file so the main isolate can show it later
/// (platform channels are unavailable when the app is fully killed).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final data = message.data;
    final displayTitle = data['title'] ?? message.notification?.title ?? 'Satya';
    final displayBody = data['body'] ?? message.notification?.body ?? '';
    if (displayBody.isEmpty && displayTitle.isEmpty) return;

    final file = File('${Directory.systemTemp.path}/$_pendingNotificationFile');
    final pending = <Map<String, String>>[];
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> existing = jsonDecode(content);
          for (final item in existing) {
            if (item is Map) {
              pending.add(item.map((k, v) => MapEntry(k.toString(), v.toString())));
            }
          }
        }
      } catch (_) {}
    }
    if (pending.length >= _maxPendingNotifications) {
      pending.removeAt(0);
    }
    pending.add(data.map((k, v) => MapEntry(k.toString(), v.toString())));
    await file.writeAsString(jsonEncode(pending));
  } catch (e) {
    print('[fcm bg] error: $e');
  }
}

/// All notification plumbing — local notifications, FCM foreground
/// display, tap routing, and scheduled ritual reminders.
class NotificationService with WidgetsBindingObserver {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _processingPending = false;

  // ── Channels ────────────────────────────────────────────────────
  /// MUST match the server payload:
  /// `android.notification.channelId = "satya_default"`. Mismatched id
  /// = silent drop on Android 8+.
  static const String pushChannelId = 'satya_default';
  static const String pushChannelName = 'Satya notifications';
  static const String pushChannelDescription = 'General app notifications';

  /// Local-only channels used for scheduled ritual reminders (existing
  /// behavior, preserved).
  static const String scheduledChannelId = 'scheduled_channel_v2';
  static const String highImportanceChannelId = 'high_importance_channel_v2';

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await _initializeWebFcm();
        return;
      }

      // 1. Timezones must be ready before any zoned schedule call.
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      if (kDebugMode) debugPrint('Timezone initialized to: $timeZoneName');

      // 2. Register the background isolate handler BEFORE anything that
      // could deliver a message.
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 3. Init the local notifications plugin (used for foreground
      // display + tap payloads).
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      // 4. Create the three Android channels we use. The plan-mandated
      // `satya_default` channel is the one server-sent broadcasts target.
      if (notificationPlatformIsAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        const pushChannel = AndroidNotificationChannel(
          pushChannelId,
          pushChannelName,
          description: pushChannelDescription,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        const scheduledChannel = AndroidNotificationChannel(
          scheduledChannelId,
          'Ritual Reminders',
          description: 'Notifications for upcoming rituals and festivals',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        const highImportanceChannel = AndroidNotificationChannel(
          highImportanceChannelId,
          'General Notifications',
          description: 'Important updates and messages',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );

        await androidPlugin?.createNotificationChannel(pushChannel);
        await androidPlugin?.createNotificationChannel(scheduledChannel);
        await androidPlugin?.createNotificationChannel(highImportanceChannel);

        // Android 13+ runtime permission. No-op on older versions.
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();
      }

      // 5. iOS / macOS notification permission.
      if (notificationPlatformIsIOS || notificationPlatformIsMacOS) {
        await _fcm.requestPermission(alert: true, badge: true, sound: true);
        // Make sure foreground pushes don't sneak past us silently on
        // iOS — disable native presentation since we render ourselves.
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
        // FCM getToken() needs the APNs token first on iOS.
        await _waitForApnsToken();
      }

      // 6. Observe app lifecycle so we drain pending notifications when
      // the user returns to the app (messages that arrived in background).
      WidgetsBinding.instance.addObserver(this);

      // 7. Drain any notifications the background handler persisted while
      // the app was killed (platform channels unavailable in that isolate).
      await processPendingNotifications();

      // 7. FCM listeners — foreground display, background tap, cold-start.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      if (kDebugMode) {
        final token = await _fcm.getToken();
        if (token != null && token.length >= 12) {
          debugPrint('[fcm] device token: ${token.substring(0, 12)}…');
        } else if (notificationPlatformIsIOS || notificationPlatformIsMacOS) {
          debugPrint(
            '[fcm] device token not ready yet (APNs may still be registering)',
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _initializeWebFcm() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    if (kDebugMode) {
      debugPrint(
        '[fcm] web listeners attached (service worker: firebase-messaging-sw.js)',
      );
    }
  }

  /// Call once after Firebase + GetX bindings are ready. Handles the
  /// "user tapped a tray notification while the app was terminated"
  /// case — `getInitialMessage()` returns the `RemoteMessage` that
  /// caused the launch.
  Future<void> handleColdStart() async {
    try {
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        if (kDebugMode) {
          debugPrint(
            '[fcm cold] id=${initial.messageId} type=${initial.data['type']}',
          );
        }
        PushRouter.navigateFromData(_dataAsMap(initial.data));
      }
      // Also show any pending notifications saved by background handler.
      await processPendingNotifications();
    } catch (e) {
      if (kDebugMode) debugPrint('[fcm cold] error: $e');
    }
  }

  /// Reads and displays notifications saved by the background handler.
  /// Called from [initialize] and [handleColdStart] — the main isolate
  /// has working platform channels so [FlutterLocalNotificationsPlugin]
  /// can show them.
  Future<void> processPendingNotifications() async {
    if (_processingPending) return;
    _processingPending = true;
    try {
      final file = File('${Directory.systemTemp.path}/$_pendingNotificationFile');
      if (!await file.exists()) return;
      final content = await file.readAsString();
      if (content.isEmpty) return;
      await file.delete();

      final List<dynamic> items = jsonDecode(content);
      for (final item in items) {
        if (item is! Map) continue;
        final data = item.map((k, v) => MapEntry(k.toString(), v.toString()));
        final title = data['title'] ?? 'Satya';
        final body = data['body'] ?? '';
        if (title == 'Satya' && body.isEmpty) continue;
        await _localNotifications.show(
          data.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              pushChannelId,
              pushChannelName,
              channelDescription: pushChannelDescription,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              styleInformation: BigTextStyleInformation(body),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(data),
        );
      }
    } catch (e) {
      print('[notification] process pending error: $e');
    } finally {
      _processingPending = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      processPendingNotifications();
    }
  }

  // ── FCM message handlers ───────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = _dataAsMap(message.data);
    if (AdminNotificationRouter.tryHandleData(
      data,
      fromTap: false,
      message: message,
    )) {
      // Web: sound + inbox refresh in [AdminNotificationRouter]; no extra tray here.
      if (kIsWeb) return;
      // Mobile admin: still show a heads-up below.
    }

    final notification = message.notification;
    final displayTitle = notification?.title ?? data['title'] ?? 'Satya';
    final displayBody = notification?.body ?? data['body'] ?? '';
    if (displayBody.isEmpty && displayTitle.isEmpty) return;

    if (kDebugMode) {
      debugPrint(
        '[fcm fg] type=${message.data['type']} title=$displayTitle',
      );
    }
    final payload = jsonEncode(_dataAsMap(message.data));
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        pushChannelId,
        pushChannelName,
        channelDescription: pushChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(displayBody),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _localNotifications.show(
      message.hashCode,
      displayTitle,
      displayBody,
      details,
      payload: payload,
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[fcm tap-bg] type=${message.data['type']}');
    }
    PushRouter.navigateFromData(_dataAsMap(message.data));
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final data = decoded.map((k, v) => MapEntry(k.toString(), v));
        if (AdminNotificationRouter.tryHandleData(data, fromTap: true)) {
          return;
        }
        PushRouter.navigateFromData(data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[fcm tap-fg] payload decode failed: $e');
    }
  }

  /// FCM data values are always strings on the wire, but the plugin
  /// hands us a `Map<String, dynamic>`. Normalise to a plain map we can
  /// JSON-encode without surprises.
  Map<String, dynamic> _dataAsMap(Map<String, dynamic> data) {
    return data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  /// iOS/macOS: FCM cannot produce a device token until APNs registration
  /// completes (often a few seconds after [requestPermission]).
  Future<void> _waitForApnsToken() async {
    if (!notificationPlatformIsIOS && !notificationPlatformIsMacOS) return;
    for (var i = 0; i < 20; i++) {
      final token = await _fcm.getAPNSToken();
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[fcm] APNs token ready (${token.substring(0, 10)}…)');
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (kDebugMode) {
      debugPrint('[fcm] APNs token not available yet — push may register later');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Existing ritual-reminder API (preserved)
  // ════════════════════════════════════════════════════════════════

  Future<void> subscribeToEventNotification(
    String eventId,
    String title,
    String type,
    DateTime eventDate,
  ) async {
    try {
      final cleanTopic = eventId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');

      await _fcm.subscribeToTopic(cleanTopic);

      final now = DateTime.now();
      DateTime scheduledDateTime = eventDate.subtract(
        const Duration(minutes: 1),
      );
      // DEBUG/TEST: If event is today, always trigger in 10 seconds for
      // verification.
      if (scheduledDateTime.isBefore(now.add(const Duration(seconds: 30)))) {
        scheduledDateTime = now.add(const Duration(seconds: 10));
      }

      await _scheduleLocalNotification(
        id: eventId.hashCode,
        title: 'Reminder: $title',
        body: 'Your scheduled $type is about to start.',
        scheduledDate: scheduledDateTime,
      );

      await _firestore.collection('ritual_reminders').doc(eventId).set({
        'eventId': eventId,
        'title': title,
        'type': type,
        'eventDate': eventDate.toIso8601String(),
        'topicName': cleanTopic,
        'scheduledTime': Timestamp.fromDate(scheduledDateTime),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar(
        'Reminder Set',
        'We will notify you at '
            '${scheduledDateTime.hour}:'
            '${scheduledDateTime.minute.toString().padLeft(2, '0')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Color(0xFFFCF7EF),
      );

      if (kDebugMode) {
        debugPrint('Notifications: Scheduled for $scheduledDateTime');
      }
    } catch (e) {
      debugPrint('Error subscribing to event notification: $e');
      rethrow;
    }
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // Android 12+ blocks exact alarms unless the user grants
      // SCHEDULE_EXACT_ALARM in system settings.  Use inexact so the
      // notification still fires in all cases (may be delayed a few
      // minutes during Doze).
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            scheduledChannelId,
            'Ritual Reminders',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (kDebugMode) {
        debugPrint('Local Notification scheduled for: $scheduledDate');
      }
    } catch (e) {
      debugPrint('Error scheduling local notification: $e');
    }
  }

  Future<void> unsubscribeFromEventNotification(String eventId) async {
    try {
      final cleanTopic = eventId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
      await _fcm.unsubscribeFromTopic(cleanTopic);
      await _localNotifications.cancel(eventId.hashCode);

      Get.snackbar(
        'Reminder Cancelled',
        'Notification has been removed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error unsubscribing: $e');
    }
  }
}
