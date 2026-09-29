import 'dart:io';

import 'package:flutter/services.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:android_intent_plus/android_intent.dart';

const _calendarChannel = MethodChannel('com.sathya.app/calendar');

Future<bool> addEventToCalendarImpl({
  required String title,
  String? description,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    if (Platform.isIOS) {
      try {
        print('[Dart Calendar] Invoking native channel com.sathya.app/calendar addEvent: $title');
        final res = await _calendarChannel.invokeMethod<bool>('addEvent', {
          'title': title,
          'description': description?.trim() ?? '',
          'location': 'Sathya App',
          'startDate': startDate.millisecondsSinceEpoch,
          'endDate': endDate.millisecondsSinceEpoch,
          'allDay': true,
        });
        print('[Dart Calendar] Native channel returned result: $res');
        return res ?? true;
      } catch (e) {
        print('[Dart Calendar] Native iOS calendar channel ERROR: $e');
        return false;
      }
    }

    // Android / fallback flow: opens native calendar screen where user confirms Save.
    final event = Event(
      title: title,
      description: description?.trim() ?? '',
      location: 'Sathya App',
      startDate: startDate,
      endDate: endDate,
      allDay: true,
    );
    final opened = await Add2Calendar.addEvent2Cal(event);
    if (opened) return true;

    // Fallback for Android devices where add_2_calendar resolveActivity fails.
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
        arguments: <String, dynamic>{
          'title': title,
          'description': description?.trim() ?? '',
          'beginTime': startDate.millisecondsSinceEpoch,
          'endTime': endDate.millisecondsSinceEpoch,
          'allDay': true,
        },
      );
      await intent.launch();
      return true;
    }
    return false;
  } catch (e) {
    print('Calendar error: $e');
    return false;
  }
}
