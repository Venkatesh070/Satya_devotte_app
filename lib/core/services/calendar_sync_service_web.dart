import 'dart:html' as html;

String _toGoogleCalendarDate(DateTime dateTime) {
  final utc = dateTime.toUtc();
  final y = utc.year.toString().padLeft(4, '0');
  final m = utc.month.toString().padLeft(2, '0');
  final d = utc.day.toString().padLeft(2, '0');
  final hh = utc.hour.toString().padLeft(2, '0');
  final mm = utc.minute.toString().padLeft(2, '0');
  final ss = utc.second.toString().padLeft(2, '0');
  return '$y$m${d}T$hh$mm${ss}Z';
}

Future<bool> addEventToCalendarImpl({
  required String title,
  String? description,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final uri = Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': title,
    'details': (description ?? '').trim(),
    'location': 'Sathya App',
    'dates':
        '${_toGoogleCalendarDate(startDate)}/${_toGoogleCalendarDate(endDate)}',
  });

  html.window.open(uri.toString(), '_blank');
  return true;
}
