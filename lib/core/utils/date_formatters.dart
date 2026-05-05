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
    final paddedDay = parsed.day.toString().padLeft(2, '0');
    final shortYear = (parsed.year % 100).toString().padLeft(2, '0');
    return '$paddedDay\n${_months[parsed.month - 1]} $shortYear';
  }
}
