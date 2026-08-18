class DateFormatters {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String? formatFestivalDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;

    DateTime? parsed = DateTime.tryParse(rawDate);
    final isIsoInstant = rawDate.contains('T') || rawDate.endsWith('Z');
    if (parsed != null && isIsoInstant) {
      parsed = parsed.toUtc();
    }

    // Try DD-MM-YYYY if ISO fails
    if (parsed == null) {
      try {
        final parts = rawDate.split('-');
        if (parts.length == 3 && parts[0].length <= 2) {
          parsed = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }

    if (parsed == null) return null;
    return '${parsed.day}${_ordinalSuffix(parsed.day)}\n${_months[parsed.month - 1]}';
  }

  static String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
