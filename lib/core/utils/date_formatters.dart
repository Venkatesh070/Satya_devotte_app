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
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return null;
    final paddedDay = parsed.day.toString().padLeft(2, '0');
    final shortYear = (parsed.year % 100).toString().padLeft(2, '0');
    return '$paddedDay\n${_months[parsed.month - 1]} $shortYear';
    // return '$paddedDay\n${_months[parsed.month - 1]}';
  }
}
