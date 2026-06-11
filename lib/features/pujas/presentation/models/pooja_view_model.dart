import 'dart:convert';

// ════════════════════════════════════════════════════════════════
//  View-model normalising the API payload.
// ════════════════════════════════════════════════════════════════

class PoojaView {
  PoojaView(this._raw);
  final Map<String, dynamic> _raw;

  Map<String, dynamic> get raw => _raw;

  String get id => (_raw['_id'] ?? _raw['id'] ?? '').toString();

  String get title => (_raw['title'] ?? '').toString();
  String get category => (_raw['category'] ?? '').toString();
  String get difficulty => (_raw['difficulty'] ?? '').toString();
  String get duration => (_raw['duration'] ?? '').toString();
  String get description => (_raw['description'] ?? '').toString();
  String get status => (_raw['status'] ?? '').toString();
  String get date => (_raw['date'] ?? '').toString();

  String get deityColor {
    final dDoc = deityDoc;
    if (dDoc != null) {
      return (dDoc['deity_color'] ?? dDoc['color'] ?? '').toString();
    }
    return '';
  }

  Map<String, dynamic>? get deityDoc {
    final d = _raw['deity'];
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return d.map((k, v) => MapEntry(k.toString(), v));
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
      return (d['name'] ?? d['title'] ?? '').toString();
    }
    final raw = (_raw['deity'] ?? '').toString();
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
      primary: (m['primary'] ?? '').toString(),
      repetitions: (m['repetitions'] ?? '').toString(),
      meaning: (m['meaning'] ?? '').toString(),
      additional: (m['additional'] is List)
          ? (m['additional'] as List).map((e) => e.toString()).toList()
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
        title: (m['title'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
        subSteps: (m['subSteps'] is List)
            ? (m['subSteps'] as List).map((e) => e.toString()).toList()
            : const [],
      );
    }).toList();
  }

  List<String> get blessings {
    final raw = _raw['blessings'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> get festivalIds {
    final raw = _raw['festivalIds'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
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
  });
  final int number;
  final String title;
  final String description;
  final List<String> subSteps;
}

class MeaningItem {
  const MeaningItem({required this.title, required this.description});
  final String title;
  final String description;
}
