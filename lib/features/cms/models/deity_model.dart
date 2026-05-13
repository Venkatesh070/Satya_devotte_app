class DeityModel {
  const DeityModel({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.status,
    this.imageUrl,
    this.audioUrls = const [],
    this.videoUrls = const [],
    this.alternateNames = const [],
    this.roles = const [],
    this.lineageParents = const [],
    this.lineageConsort = '',
    this.lineageChildren = const [],
    this.lineageVehicle = '',
    this.lineageAbode = '',
    this.appearance = const [],
    this.spiritualSignificance = const [],
    this.connectingHowToPray = '',
    this.connectingWhatPleases = const [],
    this.connectingDispleases = const [],
    this.connectingIdealTime = '',
    this.chantingMantra = '',
    this.chantingRepetitions = '',
    this.chantingBenefits = const [],
    this.chantingPreferredDays = const [],
    this.chantingAssociatedColors = const [],
    this.homePlacement = '',
    this.homeOfferings = const [],
    this.homeDo = const [],
    this.homeDont = const [],
    this.devotionalSignOfConnection = '',
    this.devotionalNotes = '',
    this.stories = const [],
    this.rituals = const [],
    this.ritualTitles = const {},
    this.lineageForms = const [],
    this.structure = const [],
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final String status;
  final String? imageUrl;
  final List<String> audioUrls;
  final List<String> videoUrls;
  final List<String> alternateNames;
  final List<String> roles;
  final List<String> lineageParents;
  final String lineageConsort;
  final List<String> lineageChildren;
  final String lineageVehicle;
  final String lineageAbode;
  final List<Map<String, String>> appearance;
  final List<Map<String, String>> spiritualSignificance;
  final String connectingHowToPray;
  final List<String> connectingWhatPleases;
  final List<String> connectingDispleases;
  final String connectingIdealTime;
  final String chantingMantra;
  final String chantingRepetitions;
  final List<String> chantingBenefits;
  final List<String> chantingPreferredDays;
  final List<String> chantingAssociatedColors;
  final String homePlacement;
  final List<String> homeOfferings;
  final List<String> homeDo;
  final List<String> homeDont;
  final String devotionalSignOfConnection;
  final String devotionalNotes;
  final List<Map<String, String>> stories;
  final List<String> rituals;
  /// Optional `id -> display title` map captured when the API returns
  /// populated ritual objects (e.g. `{_id, title, name}`). Used by the CMS
  /// edit form to render names instead of raw IDs while the pooja list loads.
  final Map<String, String> ritualTitles;
  final List<Map<String, String>> lineageForms;
  final List<Map<String, String>> structure;

  factory DeityModel.fromJson(Map<String, dynamic> json) {
    return DeityModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['deityName'] ?? json['title'] ?? '')
          .toString(),
      title: (json['title'] ?? json['subtitle'] ?? '').toString(),
      description: (json['description'] ?? json['about'] ?? '').toString(),
      status: _prettyStatus((json['status'] ?? 'Pending').toString()),
      imageUrl:
          json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          ((json['media'] is Map &&
                  (json['media']['images'] as List?)?.isNotEmpty == true)
              ? json['media']['images'][0]?.toString()
              : null),
      audioUrls: _listOfStrings((json['media'] as Map?)?['audio']),
      videoUrls: _listOfStrings((json['media'] as Map?)?['videos']),
      alternateNames: _listOfStrings(json['alternate_names']),
      roles: _listOfStrings(json['roles']),
      lineageParents: _listOfStrings((json['lineage'] as Map?)?['parents']),
      lineageConsort: ((json['lineage'] as Map?)?['consort'] ?? '').toString(),
      lineageChildren: _listOfStrings((json['lineage'] as Map?)?['children']),
      lineageVehicle: ((json['lineage'] as Map?)?['vehicle'] ?? '').toString(),
      lineageAbode: ((json['lineage'] as Map?)?['abode'] ?? '').toString(),
      appearance: _listOfKeyValue(json['appearance']),
      spiritualSignificance: _listOfKeyValue(json['spiritual_significance']),
      connectingHowToPray: ((json['connecting'] as Map?)?['how_to_pray'] ?? '')
          .toString(),
      connectingWhatPleases: _listOfStrings(
        (json['connecting'] as Map?)?['what_pleases'],
      ),
      connectingDispleases: _listOfStrings(
        (json['connecting'] as Map?)?['displeases'] ??
            (json['connecting'] as Map?)?['what_displeases'],
      ),
      connectingIdealTime: _stringFromAny(
        (json['connecting'] as Map?)?['ideal_time'],
      ),
      chantingMantra: ((json['chanting'] as Map?)?['mantra'] ?? '').toString(),
      chantingRepetitions:
          ((json['chanting'] as Map?)?['repetitions'] ?? '').toString(),
      chantingBenefits: _listOfStrings((json['chanting'] as Map?)?['benefits']),
      chantingPreferredDays: _listOfStrings(
        (json['chanting'] as Map?)?['preferred_days'],
      ),
      chantingAssociatedColors: _listOfStrings(
        (json['chanting'] as Map?)?['associated_colors'],
      ),
      homePlacement: ((json['home_practice'] as Map?)?['placement'] ?? '')
          .toString(),
      homeOfferings: _listOfStrings((json['home_practice'] as Map?)?['offerings']),
      homeDo: _listOfStrings(
        ((json['home_practice'] as Map?)?['do_and_dont'] as Map?)?['do'],
      ),
      homeDont: _listOfStrings(
        ((json['home_practice'] as Map?)?['do_and_dont'] as Map?)?['dont'],
      ),
      devotionalSignOfConnection:
          ((json['devotional_experience'] as Map?)?['sign_of_connection'] ?? '')
              .toString(),
      devotionalNotes: ((json['devotional_experience'] as Map?)?['notes'] ?? '')
          .toString(),
      stories: _listOfKeyValue(json['stories']),
      // Backend key was renamed `rituals` → `pujas`; accept both so older
      // payloads still parse during the transition.
      rituals: _listOfIds(json['pujas'] ),
      ritualTitles: _idToTitleMap(json['pujas']),
      lineageForms: _listOfKeyValue(
        (json['lineage'] as Map?)?['forms'] ?? json['lineage_forms'],
      ),
      structure: _listOfKeyValue(
        json['structure'] ??
            json['divine_structure'] ??
            json['divineStructure'] ??
            (json['lineage'] as Map?)?['structure'],
      ),
    );
  }

  static String _stringFromAny(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    return raw.toString();
  }

  static List<String> _listOfStrings(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Like [_listOfStrings] but for ID-bearing fields. The API may return either
  /// raw IDs (`["67..."]`) or populated objects (`[{_id: "67...", title: ...}]`).
  /// In either case we keep only the ID so UI lookups (e.g. ritual title)
  /// can resolve a human-readable label.
  static List<String> _listOfIds(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e == null) return '';
          if (e is String) return e.trim();
          if (e is Map) {
            final v = e['_id'] ?? e['id'];
            return v?.toString().trim() ?? '';
          }
          return e.toString().trim();
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Captures `id -> title` pairs when the API returns populated objects so
  /// the UI can display human-readable names without an extra lookup.
  static Map<String, String> _idToTitleMap(dynamic raw) {
    if (raw is! List) return const {};
    final out = <String, String>{};
    for (final e in raw) {
      if (e is! Map) continue;
      final id = (e['_id'] ?? e['id'])?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final title =
          (e['title'] ?? e['name'] ?? e['poojaName'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      out[id] = title;
    }
    return out;
  }

  static List<Map<String, String>> _listOfKeyValue(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) {
          final title = e['title']?.toString().trim() ?? '';
          final description = e['description']?.toString().trim() ?? '';
          if (title.isEmpty && description.isEmpty) return <String, String>{};
          return {'title': title, 'description': description};
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _prettyStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'approved') return 'Approved';
    if (s == 'published') return 'Published';
    if (s == 'pending') return 'Pending';
    if (s == 'queued') return 'Queued';
    if (s == 'draft') return 'Draft';
    if (s == 'rejected') return 'Rejected';
    return raw.isEmpty ? 'Pending' : raw;
  }
}
