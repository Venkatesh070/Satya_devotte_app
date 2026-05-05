import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Define channels as constants to ensure consistency
  static const String scheduledChannelId = 'scheduled_channel_v2';
  static const String highImportanceChannelId = 'high_importance_channel_v2';

  Future<void> initialize() async {
    try {
      // 1. Initialize Timezone FIRST (critical for scheduling)
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone initialized to: $timeZoneName');

      // 2. Initialize Local Notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Local notification clicked: ${details.payload}');
        },
      );

      // 3. Create Notification Channels explicitly for Android
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        // Channel for scheduled reminders
        const AndroidNotificationChannel scheduledChannel =
            AndroidNotificationChannel(
              scheduledChannelId,
              'Ritual Reminders',
              description: 'Notifications for upcoming rituals and festivals',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
              showBadge: true,
            );

        // Channel for immediate/FCM messages
        const AndroidNotificationChannel highImportanceChannel =
            AndroidNotificationChannel(
              highImportanceChannelId,
              'General Notifications',
              description: 'Important updates and messages',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            );

        await androidPlugin?.createNotificationChannel(scheduledChannel);
        await androidPlugin?.createNotificationChannel(highImportanceChannel);

        // Request permissions (Android 13+ only, Android 11 returns true automatically)
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();
      }

      // 4. Get FCM Token
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received');
        _showLocalNotification(message);
      });

      // 6. Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 7. Startup Test: Show an immediate notification to verify setup
      await _showImmediateTestNotification();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _showImmediateTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          highImportanceChannelId,
          'System Test',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      999,
      'System Ready',
      'Notification system is active and ready.',
      details,
    );
    debugPrint('Startup test notification triggered');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          highImportanceChannelId,
          'General Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  Future<void> subscribeToEventNotification(
    String eventId,
    String title,
    String type,
    DateTime eventDate,
  ) async {
    try {
      final cleanTopic = eventId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');

      // 1. Subscribe to FCM Topic
      await _fcm.subscribeToTopic(cleanTopic);

      // 2. Schedule Local Notification
      final now = DateTime.now();

      // Calculate 1 min before
      DateTime scheduledDateTime = eventDate.subtract(
        const Duration(minutes: 1),
      );

      // DEBUG/TEST: If event is today, always trigger in 10 seconds for verification
      if (scheduledDateTime.isBefore(now.add(const Duration(seconds: 30)))) {
        scheduledDateTime = now.add(const Duration(seconds: 10));
      }

      await _scheduleLocalNotification(
        id: eventId.hashCode,
        title: 'Reminder: $title',
        body: 'Your scheduled $type is about to start.',
        scheduledDate: scheduledDateTime,
      );

      // 3. Backup to Firestore
      await _firestore.collection('ritual_reminders').doc(eventId).set({
        'eventId': eventId,
        'title': title,
        'type': type,
        'eventDate': eventDate.toIso8601String(),
        'topicName': cleanTopic,
        'scheduledTime': Timestamp.fromDate(scheduledDateTime),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Show a snackbar so the user knows the button click worked
      Get.snackbar(
        'Reminder Set',
        'We will notify you at ${scheduledDateTime.hour}:${scheduledDateTime.minute.toString().padLeft(2, '0')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

      debugPrint('Notifications: Scheduled for $scheduledDateTime');
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
            fullScreenIntent: true, // Helps visibility on some devices
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
        'Local Notification successfully scheduled for: $scheduledDate',
      );
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
