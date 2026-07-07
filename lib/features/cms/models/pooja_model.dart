import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Encodes/decodes a pooja step stored in [PoojaModel.steps] as JSON, with
/// legacy `title||description` fallback.
class PoojaStepCodec {
  const PoojaStepCodec._();

  static String encode({
    required String title,
    required String description,
    List<String> imageUrls = const [],
  }) {
    final map = <String, dynamic>{'title': title, 'description': description};
    final urls = imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isNotEmpty) map['imageUrls'] = urls;
    return jsonEncode(map);
  }

  static List<String> _urlsFromMap(Map<dynamic, dynamic> map) {
    final raw = map['images'] ?? map['imageUrls'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final single = map['imageUrl']?.toString().trim();
    if (single != null && single.isNotEmpty) return [single];
    return const [];
  }

  static ({String title, String description, List<String> imageUrls}) decode(
    String raw,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (title: '', description: '', imageUrls: const []);
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return (
          title: decoded['title']?.toString().trim() ?? '',
          description: decoded['description']?.toString().trim() ?? '',
          imageUrls: _urlsFromMap(decoded),
        );
      }
    } catch (_) {}
    final parts = trimmed.split('||');
    if (parts.length < 2) {
      return (title: trimmed, description: '', imageUrls: const []);
    }
    return (
      title: parts.first.trim(),
      description: parts.sublist(1).join('||').trim(),
      imageUrls: const [],
    );
  }

  static String encodeFromMap(Map<dynamic, dynamic> map) {
    return encode(
      title: map['title']?.toString().trim() ?? '',
      description: map['description']?.toString().trim() ?? '',
      imageUrls: _urlsFromMap(map),
    );
  }
}

class PoojaModel {
  const PoojaModel({
    required this.id,
    required this.title,
    required this.deities,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.description,
    required this.status,
    this.date,
    this.schedules = const [],
    this.daily = false,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.steps = const [],
    this.requiredItems = const [],
    this.purposeWhy,
    this.purposeBenefits = const [],
    this.deitySummaryAbout,
    this.deitySummaryBlessings = const [],
    this.preparationPersonal = const [],
    this.preparationSpace = const [],
    this.preparationItems = const [],
    this.mantraPrimary,
    this.mantraRepetitions,
    this.mantraAdditional = const [],
    this.mantraMeaning,
    this.spiritualOfferingsMeaning = const [],
    this.spiritualActionsMeaning = const [],
    this.spiritualOtherSymbolism = const [],
    this.guidanceMindset = const [],
    this.guidanceAvoid = const [],
    this.completionClosure = const [],
    this.completionIntegration = const [],
    this.completionBenefits = const [],
    this.blessings = const [],
    this.festivalIds = const [],
    this.rating = 0.0,
    this.poojaDate,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final List<String> deities;
  /// First deity id, or comma-joined ids — for legacy display.
  String get deity => deities.join(', ');
  final String category;
  final String difficulty;
  final String duration;
  final String description;
  final String
  status; // Internal display value: 'Approved' | 'Queued' | 'Pending' | 'Draft' | 'Rejected'
  final String? date;
  final List<Map<String, String>> schedules;
  final bool daily;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> steps;
  final List<String> requiredItems;
  final String? purposeWhy;
  final List<String> purposeBenefits;
  final String? deitySummaryAbout;
  final List<String> deitySummaryBlessings;
  final List<String> preparationPersonal;
  final List<String> preparationSpace;
  final List<String> preparationItems;
  final String? mantraPrimary;
  final String? mantraRepetitions;
  final List<String> mantraAdditional;
  final String? mantraMeaning;
  final List<Map<String, String>> spiritualOfferingsMeaning;
  final List<Map<String, String>> spiritualActionsMeaning;
  final List<Map<String, String>> spiritualOtherSymbolism;
  final List<String> guidanceMindset;
  final List<String> guidanceAvoid;
  final List<String> completionClosure;
  final List<String> completionIntegration;
  final List<String> completionBenefits;
  final List<String> blessings;
  final List<String> festivalIds;
  final double rating;
  final String? poojaDate;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  // ── Try multiple field names ──────────────────────────────────
  static List<String> _extractDeityIds(Map<String, dynamic> json) {
    final raw = json['deity'] ?? json['deities'];
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              return (e['_id'] ?? e['id'] ?? '').toString().trim();
            }
            return e.toString().trim();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is Map) {
      final id = _extractId(raw);
      if (id != null && id.isNotEmpty) return [id];
    }
    final single = _str(json, ['deity', 'deityName', 'deity_name']);
    if (single.isNotEmpty) return [single];
    return const [];
  }

  static String _str(
    Map<String, dynamic> json,
    List<String> keys, [
    String fallback = '',
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
    return fallback;
  }

  static String? _extractId(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) return raw['_id']?.toString() ?? raw['id']?.toString();
    return null;
  }

  static List<String> _listOfStrings(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<Map<String, String>> _keyValueList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) {
          final title = e['title']?.toString().trim() ?? '';
          final descRaw = e['description'];
          String description;
          if (descRaw is List || descRaw is Map) {
            description = jsonEncode(descRaw);
          } else {
            description = descRaw?.toString().trim() ?? '';
          }
          if (title.isEmpty && description.isEmpty) return <String, String>{};
          return {'title': title, 'description': description};
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _normalizeApiTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '00:00';
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
    if (match == null) return trimmed;
    return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!}';
  }

  static List<Map<String, String>> _extractSchedules(Map<String, dynamic> json) {
    final raw = json['schedules'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) {
            final date = _toApiDate(entry['date']?.toString()) ??
                entry['date']?.toString().trim() ??
                '';
            final time = _normalizeApiTime(entry['time']?.toString() ?? '');
            if (date.isEmpty) return <String, String>{};
            return {'date': date, 'time': time};
          })
          .where((entry) => entry.isNotEmpty)
          .toList();
    }

    final legacyDates = json['dates'] ?? json['scheduleDates'];
    if (legacyDates is List) {
      return legacyDates
          .map((item) => _scheduleFromLegacyDateString(item.toString()))
          .whereType<Map<String, String>>()
          .toList();
    }

    final single = json['date'];
    if (single is String && single.trim().isNotEmpty) {
      if (single.contains(',')) {
        return single
            .split(',')
            .map((item) => _scheduleFromLegacyDateString(item))
            .whereType<Map<String, String>>()
            .toList();
      }
      final schedule = _scheduleFromLegacyDateString(single);
      if (schedule != null) return [schedule];
    }
    return const [];
  }

  static Map<String, String>? _scheduleFromLegacyDateString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final withTime = RegExp(
      r'^(\d{1,2})-(\d{1,2})-(\d{4}) (\d{1,2}):(\d{2})$',
    ).firstMatch(trimmed);
    if (withTime != null) {
      final date =
          '${withTime.group(1)!.padLeft(2, '0')}-${withTime.group(2)!.padLeft(2, '0')}-${withTime.group(3)!}';
      final time =
          '${withTime.group(4)!.padLeft(2, '0')}:${withTime.group(5)!}';
      return {'date': date, 'time': time};
    }
    final apiDate = _toApiDate(trimmed);
    if (apiDate == null) return null;
    return {'date': apiDate, 'time': '00:00'};
  }

  static String? _toApiDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final input = raw.trim();
    try {
      final ddMmYyyyHhMm = RegExp(
        r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-[0-9]{4} ([01][0-9]|2[0-3]):[0-5][0-9]$',
      );
      if (ddMmYyyyHhMm.hasMatch(input)) return input;

      final ddMmYyyy = RegExp(r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-[0-9]{4}$');
      if (ddMmYyyy.hasMatch(input)) return input;

      if (RegExp(r'^\d{8}$').hasMatch(input)) {
        final day = input.substring(0, 2);
        final month = input.substring(2, 4);
        final year = input.substring(4, 8);
        return '$day-$month-$year';
      }

      final parsed = DateTime.parse(input);
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      if (parsed.hour != 0 || parsed.minute != 0) {
        final hour = parsed.hour.toString().padLeft(2, '0');
        final minute = parsed.minute.toString().padLeft(2, '0');
        return '$day-$month-$year $hour:$minute';
      }
      return '$day-$month-$year';
    } catch (_) {
      return null;
    }
  }

  // ── Inbound: API value → internal display value ───────────────
  // API sends: APPROVED, REJECTED, PENDING, DRAFT, published, active, etc.
  // We normalise to: 'Approved' | 'Queued' | 'Pending' | 'Draft' | 'Rejected'
  static String _fromApiStatus(String raw) {
    final s = raw.toLowerCase().trim();
    if (s == 'approved' || s == 'published' || s == 'active') return 'Approved';
    if (s == 'queued') return 'Queued';
    if (s == 'pending' || s == 'pending_approval') return 'Pending';
    if (s == 'rejected') return 'Rejected';
    if (s == 'draft') return 'Draft';
    return raw;
  }

  // ── Outbound: internal display value → API uppercase value ────
  // API strictly requires: DRAFT | PENDING | APPROVED | REJECTED
  // We map our display values to the correct API equivalents.
  static String _toApiStatus(String display) {
    switch (display.toLowerCase().trim()) {
      case 'approved':
        return 'APPROVED';
      case 'pending':
        return 'PENDING';
      case 'queued':
        return 'QUEUED';
      case 'draft':
      default:
        return 'DRAFT';
    }
  }

  factory PoojaModel.fromJson(Map<String, dynamic> json) {
    // Special handling for deity field to avoid jsonEncode-ing whole deity object
    String getDeityValue(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) return raw.trim();
      if (raw is List) {
        // If it's a list of deities, take the first one and get its id/name
        if (raw.isEmpty) return '';
        return getDeityValue(raw.first);
      }
      if (raw is Map) {
        // Try to get id first, then name/title if not found
        final id = raw['_id']?.toString().trim() ?? 
                   raw['id']?.toString().trim() ?? 
                   raw['name']?.toString().trim() ?? 
                   raw['title']?.toString().trim();
        return id ?? '';
      }
      return raw.toString().trim();
    }

    // Now get deity value from possible keys
    String deity = '';
    for (final k in ['deity', 'deityName', 'deity_name']) {
      final v = json[k];
      final d = getDeityValue(v);
      if (d.isNotEmpty) {
        deity = d;
        break;
      }
    }

    return PoojaModel(
      id: _str(json, ['_id', 'id']),
      title: _str(json, ['title', 'pooja_name', 'poojaName', 'name']),
      deities: _extractDeityIds(json),
      category: _str(json, ['category']),
      difficulty: _str(json, [
        'difficulty',
        'level',
        'difficultyLevel',
      ], 'Beginner'),
      duration: _str(json, ['duration', 'duration_mins', 'durationMins']),
      description: _str(json, ['description', 'about']),
      status: _fromApiStatus(_str(json, ['status', 'pooja_status'], 'Draft')),
      date: json['date'] as String?,
      schedules: _extractSchedules(json),
      daily: json['daily'] == true,
      imageUrl:
          json['imageUrl'] as String? ??
          json['image'] as String? ??
          (json['media'] is Map
              ? ((json['media']['images'] as List?)?.isNotEmpty == true
                    ? json['media']['images'][0]?.toString()
                    : null)
              : null),
      audioUrl:
          json['audioUrl'] as String? ??
          json['audio'] as String? ??
          (json['media'] is Map
              ? ((json['media']['audio'] as List?)?.isNotEmpty == true
                    ? json['media']['audio'][0]?.toString()
                    : null)
              : null),
      videoUrl:
          json['videoUrl'] as String? ??
          json['video'] as String? ??
          (json['media'] is Map
              ? ((json['media']['videos'] as List?)?.isNotEmpty == true
                    ? json['media']['videos'][0]?.toString()
                    : null)
              : null),
      steps: () {
        final rawSteps = json['steps'] as List?;
        if (rawSteps == null) return <String>[];
        return rawSteps
            .map((e) {
              if (e is Map) {
                final encoded = PoojaStepCodec.encodeFromMap(e);
                if (encoded == '{"title":"","description":""}') return '';
                return encoded;
              }
              return e?.toString().trim() ?? '';
            })
            .where((s) => s.isNotEmpty)
            .toList();
      }(),
      requiredItems:
          (json['requiredItems'] as List?)?.map((e) => e.toString()).toList() ??
          (json['required_items'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          _listOfStrings((json['preparation'] as Map?)?['items']),
      purposeWhy: (json['purpose'] as Map?)?['why']?.toString(),
      purposeBenefits: _listOfStrings((json['purpose'] as Map?)?['benefits']),
      deitySummaryAbout: (json['deitySummary'] as Map?)?['about']?.toString(),
      deitySummaryBlessings: _listOfStrings(
        (json['deitySummary'] as Map?)?['blessings'],
      ),
      preparationPersonal: _listOfStrings(
        (json['preparation'] as Map?)?['personal'],
      ),
      preparationSpace: _listOfStrings((json['preparation'] as Map?)?['space']),
      preparationItems: _listOfStrings((json['preparation'] as Map?)?['items']),
      mantraPrimary: (json['mantra'] as Map?)?['primary']?.toString(),
      mantraRepetitions: (json['mantra'] as Map?)?['repetitions']?.toString(),
      mantraAdditional: _listOfStrings((json['mantra'] as Map?)?['additional']),
      mantraMeaning: (json['mantra'] as Map?)?['meaning']?.toString(),
      spiritualOfferingsMeaning: _keyValueList(
        (json['spiritualMeaning'] as Map?)?['offeringsMeaning'],
      ),
      spiritualActionsMeaning: _keyValueList(
        (json['spiritualMeaning'] as Map?)?['actionsMeaning'],
      ),
      spiritualOtherSymbolism: _keyValueList(
        (json['spiritualMeaning'] as Map?)?['otherSymbolism'],
      ),
      guidanceMindset: _listOfStrings((json['guidance'] as Map?)?['mindset']),
      guidanceAvoid: _listOfStrings((json['guidance'] as Map?)?['avoid']),
      completionClosure: _listOfStrings(
        (json['completion'] as Map?)?['closure'],
      ),
      completionIntegration: _listOfStrings(
        (json['completion'] as Map?)?['integration'],
      ),
      completionBenefits: _listOfStrings(
        (json['completion'] as Map?)?['benefits'],
      ),
      blessings:
          _listOfStrings((json['completion'] as Map?)?['blessings']).isNotEmpty
          ? _listOfStrings((json['completion'] as Map?)?['blessings'])
          : _listOfStrings(json['blessings']),
      festivalIds:
          (json['festivalIds'] as List?)
              ?.map((e) => _extractId(e) ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      poojaDate: _str(json, ['date', 'poojaDate', 'dateKey'], ''),
      createdBy: _extractId(json['createdBy']),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  // ── toJson sends UPPERCASE status values the API accepts ─────
  Map<String, dynamic> toJson() {
    final normalizedSchedules = schedules
        .map((entry) {
          final date = _toApiDate(entry['date']) ?? entry['date']?.trim() ?? '';
          final time = _normalizeApiTime(entry['time'] ?? '');
          if (date.isEmpty) return <String, String>{};
          return {'date': date, 'time': time};
        })
        .where((entry) => entry.isNotEmpty)
        .toList();
    return {
    'title': title,
    'deity': deities,
    'category': category,
    'difficulty': difficulty,
    'duration': duration,
    'description': description,
    'status': _toApiStatus(status), // 'Pending' → 'PENDING', 'Draft' → 'DRAFT'
    'daily': daily,
    'schedules': normalizedSchedules,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (audioUrl != null) 'audioUrl': audioUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    'purpose': {'why': purposeWhy ?? '', 'benefits': purposeBenefits},
    'deitySummary': {
      'about': deitySummaryAbout ?? '',
      'blessings': deitySummaryBlessings,
    },
    'preparation': {
      'personal': preparationPersonal,
      'space': preparationSpace,
      'items': preparationItems.isNotEmpty ? preparationItems : requiredItems,
    },
    'steps': steps.asMap().entries.map((e) {
      final step = PoojaStepCodec.decode(e.value);
      final title = step.title.trim();
      final description = step.description.trim();
      return {
        'stepNumber': e.key + 1,
        'title': title.isEmpty ? 'Step ${e.key + 1}' : title,
        'description': description.isEmpty ? title : description,
        'images': step.imageUrls,
        'subSteps': <String>[],
      };
    }).toList(),
    'mantra': {
      'primary': mantraPrimary ?? '',
      'repetitions': mantraRepetitions ?? '',
      'additional': mantraAdditional,
      'meaning': mantraMeaning ?? '',
    },
    'spiritualMeaning': {
      'offeringsMeaning': spiritualOfferingsMeaning,
      'actionsMeaning': spiritualActionsMeaning,
      'otherSymbolism': spiritualOtherSymbolism,
    },
    'guidance': {'mindset': guidanceMindset, 'avoid': guidanceAvoid},
    'completion': {
      'closure': completionClosure,
      'integration': completionIntegration,
      'benefits': completionBenefits,
      'blessings': blessings,
      'media': {
        'images': imageUrl != null && imageUrl!.trim().isNotEmpty
            ? [imageUrl]
            : [],
        'audio': audioUrl != null && audioUrl!.trim().isNotEmpty
            ? [audioUrl]
            : [],
        'videos': videoUrl != null && videoUrl!.trim().isNotEmpty
            ? [videoUrl]
            : [],
      },
      'festivalIds': festivalIds,
    },
  };
  }

  /// Sentinel: omit `imageUrl` / `audioUrl` / `videoUrl` in [copyWith] to keep previous values.
  /// Pass `null` explicitly to clear (remove media).
  static const Object _keepMediaUrl = Object();

  PoojaModel copyWith({
    String? title,
    List<String>? deities,
    String? category,
    String? difficulty,
    String? duration,
    String? description,
    String? status,
    String? date,
    List<Map<String, String>>? schedules,
    bool? daily,
    Object? imageUrl = _keepMediaUrl,
    Object? audioUrl = _keepMediaUrl,
    Object? videoUrl = _keepMediaUrl,
    List<String>? steps,
    List<String>? requiredItems,
    String? purposeWhy,
    List<String>? purposeBenefits,
    String? deitySummaryAbout,
    List<String>? deitySummaryBlessings,
    List<String>? preparationPersonal,
    List<String>? preparationSpace,
    List<String>? preparationItems,
    String? mantraPrimary,
    String? mantraRepetitions,
    List<String>? mantraAdditional,
    String? mantraMeaning,
    List<Map<String, String>>? spiritualOfferingsMeaning,
    List<Map<String, String>>? spiritualActionsMeaning,
    List<Map<String, String>>? spiritualOtherSymbolism,
    List<String>? guidanceMindset,
    List<String>? guidanceAvoid,
    List<String>? completionClosure,
    List<String>? completionIntegration,
    List<String>? completionBenefits,
    List<String>? blessings,
    List<String>? festivalIds,
    String? poojaDate,
    String? createdBy,
  }) {
    return PoojaModel(
      id: id,
      title: title ?? this.title,
      deities: deities ?? this.deities,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      status: status ?? this.status,
      date: date ?? this.date,
      schedules: schedules ?? this.schedules,
      daily: daily ?? this.daily,
      imageUrl: identical(imageUrl, _keepMediaUrl)
          ? this.imageUrl
          : imageUrl as String?,
      audioUrl: identical(audioUrl, _keepMediaUrl)
          ? this.audioUrl
          : audioUrl as String?,
      videoUrl: identical(videoUrl, _keepMediaUrl)
          ? this.videoUrl
          : videoUrl as String?,
      steps: steps ?? this.steps,
      requiredItems: requiredItems ?? this.requiredItems,
      purposeWhy: purposeWhy ?? this.purposeWhy,
      purposeBenefits: purposeBenefits ?? this.purposeBenefits,
      deitySummaryAbout: deitySummaryAbout ?? this.deitySummaryAbout,
      deitySummaryBlessings:
          deitySummaryBlessings ?? this.deitySummaryBlessings,
      preparationPersonal: preparationPersonal ?? this.preparationPersonal,
      preparationSpace: preparationSpace ?? this.preparationSpace,
      preparationItems: preparationItems ?? this.preparationItems,
      mantraPrimary: mantraPrimary ?? this.mantraPrimary,
      mantraRepetitions: mantraRepetitions ?? this.mantraRepetitions,
      mantraAdditional: mantraAdditional ?? this.mantraAdditional,
      mantraMeaning: mantraMeaning ?? this.mantraMeaning,
      spiritualOfferingsMeaning:
          spiritualOfferingsMeaning ?? this.spiritualOfferingsMeaning,
      spiritualActionsMeaning:
          spiritualActionsMeaning ?? this.spiritualActionsMeaning,
      spiritualOtherSymbolism:
          spiritualOtherSymbolism ?? this.spiritualOtherSymbolism,
      guidanceMindset: guidanceMindset ?? this.guidanceMindset,
      guidanceAvoid: guidanceAvoid ?? this.guidanceAvoid,
      completionClosure: completionClosure ?? this.completionClosure,
      completionIntegration:
          completionIntegration ?? this.completionIntegration,
      completionBenefits: completionBenefits ?? this.completionBenefits,
      blessings: blessings ?? this.blessings,
      festivalIds: festivalIds ?? this.festivalIds,
      rating: rating,
      poojaDate: poojaDate ?? this.poojaDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
