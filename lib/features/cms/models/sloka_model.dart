// lib/features/cms/models/sloka_model.dart

class SlokaModel {
  const SlokaModel({
    required this.id,
    required this.sloka,
    required this.date, // DD-MM-YYYY (API format)
    required this.author,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sloka; // the sloka text
  final String date; // DD-MM-YYYY
  final String author;
  final String? createdAt;
  final String? updatedAt;

  // ── Parse DD-MM-YYYY for display ─────────────────────────────
  DateTime? get _parsed {
    try {
      final p = date.split('-');
      if (p.length == 3) {
        // Could be DD-MM-YYYY or YYYY-MM-DD
        if (p[0].length == 4) {
          return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  String get displayDate {
    final d = _parsed;
    if (d == null) return date;
    const months = [
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  bool get isToday {
    final d = _parsed;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static String _str(
    Map<String, dynamic> json,
    List<String> keys, [
    String fb = '',
  ]) {
    for (final k in keys) {
      final v = json[k];
      if (v != null &&
          v is! List &&
          v is! Map &&
          v.toString().trim().isNotEmpty)
        return v.toString().trim();
    }
    return fb;
  }

  factory SlokaModel.fromJson(Map<String, dynamic> json) {
    return SlokaModel(
      id: _str(json, ['_id', 'id']),
      sloka: _str(json, ['sloka', 'text', 'content']),
      date: _str(json, ['date']),
      author: _str(json, ['author']),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  // Format DateTime → DD-MM-YYYY (what API expects)
  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';

  Map<String, dynamic> toJson() => {
    'sloka': sloka,
    'author': author,
    'date': date, // DD-MM-YYYY
  };
}
