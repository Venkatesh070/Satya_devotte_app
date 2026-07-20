import 'dart:convert';
import 'package:flutter/foundation.dart';

// ════════════════════════════════════════════════════════════════
//  View-model normalising the API payload.
// ════════════════════════════════════════════════════════════════

class PoojaView {
  PoojaView(this._raw, {this.customDate, this.scheduleId});
  final Map<String, dynamic> _raw;
  final String? customDate;
  final String? scheduleId;

  String _extractString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    if (v is List) {
      return v
          .map((e) => _extractString(e))
          .where((s) => s.isNotEmpty)
          .join(', ');
    }
    if (v is Map) {
      // Try to get name or title from map
      final name = v['name'] ?? v['title'] ?? '';
      return _extractString(name);
    }
    return v.toString().trim();
  }

  Map<String, dynamic> get raw => _raw;

  String get id => (_raw['_id'] ?? _raw['id'] ?? '').toString();

  String get title => (_raw['title'] ?? '').toString();
  String get category => (_raw['category'] ?? '').toString();
  String get difficulty => (_raw['difficulty'] ?? '').toString();
  String get duration => (_raw['duration'] ?? '').toString();
  String get description {
    final v = _raw['description'];
    return _extractString(v);
  }

  String get deityDescription {
    final dDoc = deityDoc;
    if (dDoc != null) {
      final v = dDoc['description'];
      return _extractString(v);
    }
    return '';
  }

  String get status => (_raw['status'] ?? '').toString();

  String get date {
    if (customDate != null) return customDate!;
    final cd = _raw['customDate'];
    if (cd != null) return cd.toString();
    final d = _raw['date'] ?? _raw['scheduledDate'] ?? _raw['scheduledAt'];
    if (d != null) return d.toString();
    final schedulesList = _decodeList(_raw['schedules']);
    if (schedulesList.isNotEmpty && schedulesList.first is Map) {
      final s = (schedulesList.first as Map)['date'];
      if (s != null) return s.toString();
    }
    return '';
  }

  List<Map<String, dynamic>> get schedules {
    final list = _decodeList(_raw['schedules']);
    return list.map((e) => _decodeMap(e)).toList();
  }

  bool get daily => _raw['daily'] == true || _raw['isDaily'] == true;

  String get dailyTimeText {
    final list = schedules;
    if (list.isNotEmpty) {
      final time = list.first['time']?.toString() ?? '';
      if (time.isNotEmpty) return 'Daily at $time';
    }
    return 'Daily';
  }

  String? get selectedScheduleId => scheduleId ?? (_raw['scheduleId'] ?? _raw['selectedScheduleId'])?.toString();

  String get deityColor {
    final dDoc = deityDoc;
    if (dDoc != null) {
      return (dDoc['deity_color'] ?? dDoc['color'] ?? '').toString();
    }
    return '';
  }

  Map<String, dynamic>? get deityDoc {
    final d = _raw['deity'];
    debugPrint('[PoojaView] deityDoc: _raw["deity"] type=${d.runtimeType} value=${d.toString().length > 200 ? "${d.toString().substring(0, 200)}..." : d}');
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return d.map((k, v) => MapEntry(k.toString(), v));
    if (d is String && d.trim().isNotEmpty) {
      final decoded = _decodeMap(d);
      debugPrint('[PoojaView] deityDoc: decoded from JSON string -> $decoded');
      if (decoded.isNotEmpty) return decoded;
    }
    // deity field might be an empty list from some API responses
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      if (first is Map) return Map<String, dynamic>.from(first);
      if (first is String && first.trim().isNotEmpty) {
        final decoded = _decodeMap(first);
        if (decoded.isNotEmpty) return decoded;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get deitySections {
    final d = deityDoc;
    if (d == null) return const [];
    final raw = _decodeList(d['sections']);
    return raw.map((e) => _decodeMap(e)).toList();
  }

  List<Map<String, dynamic>> get deityStories {
    final d = deityDoc;
    if (d == null) return const [];
    final raw = _decodeList(d['stories']);
    return raw.map((e) => _decodeMap(e)).toList();
  }

  String get deityName {
    final d = deityDoc;
    if (d != null) {
      final name = (d['name'] ?? d['title'] ?? '').toString();
      debugPrint('[PoojaView] deityName: from deityDoc -> "$name"');
      return name;
    }
    final raw = (_raw['deity'] ?? '').toString();
    debugPrint('[PoojaView] deityName: deityDoc null, raw deity field -> "$raw"');
    if (raw.length == 24 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(raw)) {
      return '';
    }
    return raw;
  }

  String? get heroImage {
    final dDoc = deityDoc;
    if (dDoc != null) {
      final dMedia = _decodeMap(dDoc['media']);
      final dImgs = dMedia['images'];
      if (dImgs is List && dImgs.isNotEmpty) {
        final first = _cleanUrl(dImgs.first.toString());
        if (first.isNotEmpty) return first;
      }
      final dDirect = _cleanUrl(
        (dDoc['imageUrl'] ?? dDoc['image'] ?? '').toString(),
      );
      if (dDirect.isNotEmpty) return dDirect;
    }

    final media = _decodeMap(_raw['media']);
    final imgs = media['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = _cleanUrl(imgs.first.toString());
      if (first.isNotEmpty) return first;
    }

    final direct = _cleanUrl(
      (_raw['imageUrl'] ?? _raw['image'] ?? '').toString(),
    );
    return direct.isEmpty ? null : direct;
  }

  String? get poojaImage {
    // Get the pooja-specific image, NOT the deity's
    final media = _decodeMap(_raw['media']);
    final imgs = media['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = _cleanUrl(imgs.first.toString());
      if (first.isNotEmpty) return first;
    }

    final direct = _cleanUrl(
      (_raw['imageUrl'] ?? _raw['image'] ?? '').toString(),
    );
    if (direct.isNotEmpty) return direct;

    // Fallback to deity image if no pooja image
    final dDoc = deityDoc;
    if (dDoc != null) {
      final dMedia = _decodeMap(dDoc['media']);
      final dImgs = dMedia['images'];
      if (dImgs is List && dImgs.isNotEmpty) {
        final first = _cleanUrl(dImgs.first.toString());
        if (first.isNotEmpty) return first;
      }
      final dDirect = _cleanUrl(
        (dDoc['imageUrl'] ?? dDoc['image'] ?? '').toString(),
      );
      if (dDirect.isNotEmpty) return dDirect;
    }

    return null;
  }

  String? get audioUrl {
    final media = _decodeMap(_raw['media']);
    final list = media['audio'];
    if (list is List && list.isNotEmpty) {
      final first = _cleanUrl(list.first.toString());
      if (first.isNotEmpty) return first;
    }
    final direct = _cleanUrl((_raw['audio'] ?? '').toString());
    return direct.isEmpty ? null : direct;
  }

  List<String> get videoUrls {
    final media = _decodeMap(_raw['media']);
    final list = media['videos'] ?? media['video'];
    if (list is List) {
      return list
          .map((e) => _cleanUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final direct = _cleanUrl((_raw['video'] ?? '').toString());
    return direct.isEmpty ? const [] : [direct];
  }

  Map<String, dynamic> get purpose => _decodeMap(_raw['purpose']);
  Map<String, dynamic> get deitySummary => _decodeMap(_raw['deitySummary']);
  Map<String, dynamic> get preparation => _decodeMap(_raw['preparation']);
  Map<String, dynamic> get mantra => _decodeMap(_raw['mantra']);
  Map<String, dynamic> get spiritualMeaning =>
      _decodeMap(_raw['spiritualMeaning']);
  Map<String, dynamic> get guidance => _decodeMap(_raw['guidance']);
  Map<String, dynamic> get completion => _decodeMap(_raw['completion']);

  MantraView get mantraView {
    final m = mantra;

    return MantraView(
      primary: _extractString(m['primary']),
      repetitions: _extractString(m['repetitions']),
      meaning: _extractString(m['meaning']),
      additional: (m['additional'] is List)
          ? (m['additional'] as List).map((e) => _extractString(e)).toList()
          : const [],
    );
  }

  List<StepView> get steps {
    final raw = _decodeList(_raw['steps']);
    return raw.whereType<Map>().map((m) {
      return StepView(
        number: (m['stepNumber'] is num)
            ? (m['stepNumber'] as num).toInt()
            : int.tryParse(m['stepNumber']?.toString() ?? '') ?? 0,
        title: _extractString(m['title']),
        description: _extractString(m['description']),
        imageUrls: () {
          final urls = <String>[];
          final rawUrls = m['images'] ?? m['imageUrls'];
          if (rawUrls is List) {
            urls.addAll(
              rawUrls
                  .map((e) => _cleanUrl(e.toString()))
                  .where((url) => url.isNotEmpty),
            );
          }
          final single = _cleanUrl((m['imageUrl'] ?? '').toString());
          if (single.isNotEmpty && !urls.contains(single)) {
            urls.add(single);
          }
          return urls;
        }(),
        subSteps: (m['subSteps'] is List)
            ? (m['subSteps'] as List).map((e) => _extractString(e)).toList()
            : const [],
      );
    }).toList();
  }

  List<String> get blessings {
    final raw = _raw['blessings'];
    if (raw is List) return raw.map((e) => _extractString(e)).toList();
    return const [];
  }

  List<String> get festivalIds {
    final raw = _raw['festivalIds'];
    if (raw is List) return raw.map((e) => _extractString(e)).toList();
    return const [];
  }

  static String _cleanUrl(String url) {
    return url.replaceAll('`', '').trim();
  }

  static Map<String, dynamic> _decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  static List<dynamic> _decodeList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return const [];
  }
}

class MantraView {
  const MantraView({
    required this.primary,
    required this.repetitions,
    required this.meaning,
    required this.additional,
  });
  final String primary;
  final String repetitions;
  final String meaning;
  final List<String> additional;
}

class StepView {
  const StepView({
    required this.number,
    required this.title,
    required this.description,
    required this.subSteps,
    this.imageUrls = const [],
  });
  final int number;
  final String title;
  final String description;
  final List<String> subSteps;
  final List<String> imageUrls;
}

class MeaningItem {
  const MeaningItem({required this.title, required this.description});
  final String title;
  final String description;
}
