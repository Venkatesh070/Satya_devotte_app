import 'dart:convert';

class UserCalendarEvent {
  const UserCalendarEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
  });

  final String id;
  final String name;
  final String description;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory UserCalendarEvent.fromJson(Map<String, dynamic> json) {
    return UserCalendarEvent(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  static List<UserCalendarEvent> listFromPrefs(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => UserCalendarEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<UserCalendarEvent> events) {
    return jsonEncode(events.map((e) => e.toJson()).toList());
  }
}
