// lib/features/cms/models/festival_model.dart

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
    this.locationCity = '',
    this.locationState = '',
    this.locationCountry = 'India',
    this.notifyUsers = false,
    this.notificationDaysBefore = 0,
    this.rituals,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String date; // ISO string from API e.g. "2026-10-26T00:00:00.000Z"
  final String status; // Pending | Approved | Rejected
  final String? endDate;
  final String category; // MAJOR | MINOR | FASTING | ECLIPSE
  final bool isGlobal;
  final String locationCity;
  final String locationState;
  final String locationCountry;
  final bool notifyUsers;
  final int notificationDaysBefore;
  final String? rituals; // optional — null means not set
  final String? imageUrl;
  final String? createdAt;

  // ── Display location as "City, State" ────────────────────────
  String get locationDisplay {
    final parts = [
      locationCity,
      locationState,
      locationCountry,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  // ── Status normalisation ──────────────────────────────────────
  static String _normaliseStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      default:
        return raw;
    }
  }

  // ── Safe string extractor ─────────────────────────────────────
  static String _str(
    Map<String, dynamic> json,
    List<String> keys, [
    String fb = '',
  ]) {
    for (final k in keys) {
      final v = json[k];
      // skip arrays/maps — only want scalar strings
      if (v != null &&
          v is! List &&
          v is! Map &&
          v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return fb;
  }

  // ── Parse location object from API ───────────────────────────
  // API returns: { "country": "India", "state": "Telangana", "city": "Hyderabad" }
  static Map<String, String> _parseLocation(dynamic raw) {
    if (raw is Map) {
      return {
        'city': raw['city']?.toString() ?? '',
        'state': raw['state']?.toString() ?? '',
        'country': raw['country']?.toString() ?? 'India',
      };
    }
    return {'city': '', 'state': '', 'country': 'India'};
  }

  // Parse rituals — API returns [] or ['id1','id2'] or a string
  static String? _parseRituals(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      if (raw.isEmpty) return null;
      return raw.map((e) => e.toString()).join(', ');
    }
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    final loc = _parseLocation(json['location']);

    return FestivalModel(
      id: _str(json, ['_id', 'id']),
      title: _str(json, ['title', 'name']),
      description: _str(json, ['description']),
      // API returns ISO date string — displayDay/Month handle both ISO + DD-MM-YYYY
      date: _str(json, ['date', 'startDate']),
      endDate: json['endDate'] as String?,
      category: _str(json, ['category'], 'MAJOR'),
      isGlobal: json['isGlobal'] as bool? ?? false,
      locationCity: loc['city']!,
      locationState: loc['state']!,
      locationCountry: loc['country']!,
      notifyUsers: json['notifyUsers'] as bool? ?? false,
      notificationDaysBefore:
          (json['notificationDaysBefore'] as num?)?.toInt() ?? 0,
      // rituals comes back as [] (array) — join to string or keep null
      rituals: _parseRituals(json['rituals']),
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String?,
      status: _normaliseStatus(_str(json, ['status'], 'Pending')),
      createdAt: json['createdAt'] as String?,
    );
  }

  // ── Display helpers — handles ISO and DD-MM-YYYY formats ──────
  DateTime? get _parsedDate {
    try {
      return DateTime.parse(date);
    } catch (_) {}
    try {
      // DD-MM-YYYY fallback
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
    String? imageUrl,
    String? status,
  }) => FestivalModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    date: date ?? this.date,
    endDate: endDate ?? this.endDate,
    category: category ?? this.category,
    isGlobal: isGlobal ?? this.isGlobal,
    locationCity: locationCity ?? this.locationCity,
    locationState: locationState ?? this.locationState,
    locationCountry: locationCountry ?? this.locationCountry,
    notifyUsers: notifyUsers ?? this.notifyUsers,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
    rituals: rituals ?? this.rituals,
    imageUrl: imageUrl ?? this.imageUrl,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}
