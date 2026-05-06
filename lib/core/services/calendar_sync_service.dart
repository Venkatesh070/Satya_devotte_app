import 'package:satya_devotte_app/core/services/calendar_sync_service_mobile.dart'
    if (dart.library.html)
    'package:satya_devotte_app/core/services/calendar_sync_service_web.dart'
    as impl;

/// Opens device calendar flow to add an event (user-triggered action only).
///
/// Works with Android/iOS calendar providers through the native calendar UI.
Future<bool> addEventToCalendar({
  required String title,
  String? description,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final safeTitle = title.trim();
  if (safeTitle.isEmpty) {
    throw ArgumentError('Event title cannot be empty.');
  }

  // Prevent invalid ranges like same or earlier end date.
  if (!endDate.isAfter(startDate)) {
    throw ArgumentError('endDate must be after startDate.');
  }

  // Web uses browser calendar URL; Android/iOS uses add_2_calendar.
  return impl.addEventToCalendarImpl(
    title: safeTitle,
    description: description,
    startDate: startDate,
    endDate: endDate,
  );
}
