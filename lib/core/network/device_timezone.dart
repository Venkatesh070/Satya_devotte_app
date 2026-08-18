import 'package:flutter_timezone/flutter_timezone.dart';

const String kDefaultAppTimeZone = 'Africa/Johannesburg';

/// Device IANA timezone for API headers (`X-Timezone`).
/// Abbreviations like `SAST` are not valid IANA ids.
Future<String> deviceIanaTimeZone() async {
  try {
    final raw = (await FlutterTimezone.getLocalTimezone()).trim();
    if (raw.isEmpty) return kDefaultAppTimeZone;
    if (raw.contains('/') || raw.toUpperCase() == 'UTC' || raw.toUpperCase() == 'GMT') {
      return raw;
    }
    return _aliasToIana(raw) ?? kDefaultAppTimeZone;
  } catch (_) {
    return kDefaultAppTimeZone;
  }
}

String? _aliasToIana(String raw) {
  switch (raw.toUpperCase()) {
    case 'SAST':
    case 'CAT':
    case 'GMT+2':
    case 'GMT+02':
    case 'GMT+02:00':
      return 'Africa/Johannesburg';
    case 'IST':
    case 'GMT+5:30':
    case 'GMT+05:30':
      return 'Asia/Kolkata';
    default:
      return null;
  }
}
