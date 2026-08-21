// lib/features/cms/models/festival_model.dart
import 'dart:convert';

class FestivalModel {
  const FestivalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    this.endDate,
    this.category = 'MAJOR',
    this.isGlobal = false,
    this.location = '',
    this.locationCity = '',
    this.locationState = '',
    this.locationCountry = '',
    this.notifyUsers = false,
    this.notificationDaysBefore = 0,
    this.rituals,
    this.ritualIds = const [],
    this.ritualTitles = const {},
    this.imageUrl,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String date;
  final String status; // Pending | Approved | Rejected
  final String? endDate;
  final String category; // MAJOR | MINOR | FASTING | ECLIPSE
  final bool isGlobal;
  final String location; // display string built from {city, state, country}
  final String locationCity;
  final String locationState;
  final String locationCountry;
  final bool notifyUsers;
  final int notificationDaysBefore;

  /// Display string of associated puja titles (comma-separated). Prefer
  /// [ritualDisplayNames] / [ritualIds] for structured access.
  final String? rituals;

  /// Associated puja ObjectIds.
  final List<String> ritualIds;

  /// Optional `id -> title` when the API returns populated ritual objects.
  final Map<String, String> ritualTitles;

  final String? imageUrl;
  final String? createdBy;
  final String? createdAt;

  String get locationDisplay {
    final parts = [
      locationCity,
      locationState,
      locationCountry,
    ].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : location;
  }

  /// Human-readable associated puja names for list/chips.
  String get ritualDisplayNames {
    if (ritualIds.isEmpty) {
      return (rituals ?? '').trim();
    }
    return ritualIds
        .map((id) {
          final title = ritualTitles[id];
          if (title != null && title.trim().isNotEmpty) return title.trim();
          return id;
        })
        .join(', ');
  }

  static String _normaliseStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'QUEUED':
        return 'Queued';
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      default:
        return raw;
    }
  }

  // API returns location as {city, state, country} object
  static Map<String, String> _parseLocation(dynamic raw) {
    if (raw == null) return {'city': '', 'state': '', 'country': ''};
    if (raw is Map) {
      return {
        'city': raw['city']?.toString() ?? '',
        'state': raw['state']?.toString() ?? '',
        'country': raw['country']?.toString() ?? '',
      };
    }
    // plain string fallback
    return {'city': raw.toString(), 'state': '', 'country': ''};
  }

  static List<String> _listOfRitualIds(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      final s = raw.toString().trim();
      if (s.isEmpty) return const [];
      return s
          .split(RegExp(r'[,\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return raw
        .map((e) {
          if (e == null) return '';
          if (e is String) return e.trim();
          if (e is Map) {
            return (e['_id'] ?? e['id'])?.toString().trim() ?? '';
          }
          return e.toString().trim();
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Map<String, String> _idToTitleMap(dynamic raw) {
    if (raw is! List) return const {};
    final out = <String, String>{};
    for (final e in raw) {
      if (e is! Map) continue;
      final id = (e['_id'] ?? e['id'])?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final title = (e['title'] ?? e['name'] ?? e['poojaName'] ?? '')
          .toString()
          .trim();
      if (title.isEmpty) continue;
      out[id] = title;
    }
    return out;
  }

  static String? _displayRituals(
    List<String> ids,
    Map<String, String> titles,
  ) {
    if (ids.isEmpty) return null;
    final names = ids
        .map((id) {
          final title = titles[id];
          if (title != null && title.isNotEmpty) return title;
          return id;
        })
        .toList();
    return names.join(', ');
  }

  static String _str(
    Map<String, dynamic> json,
    List<String> keys, [
    String fb = '',
  ]) {
    for (final k in keys) {
      final v = json[k];
      if (v != null) {
        String str;
        if (v is List || v is Map) {
          str = jsonEncode(v);
        } else {
          str = v.toString().trim();
        }
        if (str.isNotEmpty) return str;
      }
    }
    return fb;
  }

  static String? _extractId(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) return raw['_id']?.toString() ?? raw['id']?.toString();
    return null;
  }

  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    final rawAssociatePujas = json['associate_pujas'] ?? json['rituals'];
    final ritualIds = _listOfRitualIds(rawAssociatePujas);
    final ritualTitles = _idToTitleMap(rawAssociatePujas);
    return FestivalModel(
      id: _str(json, ['_id', 'id']),
      title: _str(json, ['title', 'name']),
      description: _str(json, ['description']),
      date: _str(json, ['date', 'startDate']),
      endDate: json['endDate'] as String?,
      category: _str(json, ['category'], 'MAJOR'),
      isGlobal: json['isGlobal'] as bool? ?? false,
      location: '', // computed from city/state/country
      locationCity: _parseLocation(json['location'])['city']!,
      locationState: _parseLocation(json['location'])['state']!,
      locationCountry: _parseLocation(json['location'])['country']!,
      notifyUsers: json['notifyUsers'] as bool? ?? false,
      notificationDaysBefore:
          (json['notificationDaysBefore'] as num?)?.toInt() ?? 0,
      ritualIds: ritualIds,
      ritualTitles: ritualTitles,
      rituals: _displayRituals(ritualIds, ritualTitles),
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String?,
      createdBy: _extractId(json['createdBy']),
      status: _normaliseStatus(_str(json, ['status'], 'Pending')),
      createdAt: json['createdAt'] as String?,
    );
  }

  DateTime? get _parsedDate {
    try {
      return DateTime.parse(date);
    } catch (_) {}
    try {
      final p = date.split('-');
      if (p.length == 3 && p[0].length == 2) {
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
    } catch (_) {}
    return null;
  }

  String get displayDay => _parsedDate?.day.toString().padLeft(2, '0') ?? '--';
  String get displayMonth {
    const m = [
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
    final d = _parsedDate;
    return d != null ? m[d.month - 1] : '';
  }

  int get monthNumber => _parsedDate?.month ?? DateTime.now().month;

  FestivalModel copyWith({
    String? title,
    String? description,
    String? date,
    String? endDate,
    String? category,
    bool? isGlobal,
    String? locationCity,
    String? locationState,
    String? locationCountry,
    bool? notifyUsers,
    int? notificationDaysBefore,
    String? rituals,
    List<String>? ritualIds,
    Map<String, String>? ritualTitles,
    String? imageUrl,
    String? status,
    String? createdBy,
  }) => FestivalModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    date: date ?? this.date,
    endDate: endDate ?? this.endDate,
    category: category ?? this.category,
    isGlobal: isGlobal ?? this.isGlobal,
    location: this.location,
    locationCity: locationCity ?? this.locationCity,
    locationState: locationState ?? this.locationState,
    locationCountry: locationCountry ?? this.locationCountry,
    notifyUsers: notifyUsers ?? this.notifyUsers,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
    rituals: rituals ?? this.rituals,
    ritualIds: ritualIds ?? this.ritualIds,
    ritualTitles: ritualTitles ?? this.ritualTitles,
    imageUrl: imageUrl ?? this.imageUrl,
    status: status ?? this.status,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt,
  );
}
