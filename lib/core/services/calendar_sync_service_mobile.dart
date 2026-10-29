import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:satya_devotte_app/core/services/calendar_add_outcome.dart';

const _calendarChannel = MethodChannel('com.sathya.app/calendar');

/// Opens the system calendar editor and returns [CalendarAddOutcome.saved]
/// only when the native layer confirms the user saved the event.
Future<CalendarAddOutcome> addEventToCalendarImpl({
  required String title,
  String? description,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return CalendarAddOutcome.failed;
  }

  // Android verifies save by reading CalendarContract after the editor closes.
  if (Platform.isAndroid) {
    final granted = await _ensureAndroidCalendarPermission();
    if (!granted) return CalendarAddOutcome.failed;
  }

  try {
    final res = await _calendarChannel.invokeMethod<bool>('addEvent', {
      'title': title,
      'description': description?.trim() ?? '',
      'location': 'Sathya App',
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'allDay': true,
    });
    if (res == true) return CalendarAddOutcome.saved;
    if (res == false) return CalendarAddOutcome.cancelled;
    return CalendarAddOutcome.failed;
  } catch (e) {
    // ignore: avoid_print
    print('[Dart Calendar] Native calendar channel ERROR: $e');
    return CalendarAddOutcome.failed;
  }
}

Future<bool> _ensureAndroidCalendarPermission() async {
  // Full access is required so we can verify the event was actually written
  // after the system calendar editor closes (RESULT_OK is unreliable).
  var status = await Permission.calendarFullAccess.status;
  if (status.isGranted) return true;
  status = await Permission.calendarFullAccess.request();
  return status.isGranted;
}
