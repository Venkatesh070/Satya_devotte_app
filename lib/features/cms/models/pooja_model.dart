class PoojaModel {
  const PoojaModel({
    required this.id,
    required this.title,
    required this.deity,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.description,
    required this.status,
    this.date,
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
  final String deity;
  final String category;
  final String difficulty;
  final String duration;
  final String description;
  final String
  status; // Internal display value: 'Approved' | 'Queued' | 'Pending' | 'Draft' | 'Rejected'
  final String? date;
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
  static String _str(
    Map<String, dynamic> json,
    List<String> keys, [
    String fallback = '',
  ]) {
    for (final k in keys) {
      final v = json[k];
      if (v != null && v.toString().trim().isNotEmpty)
        return v.toString().trim();
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
          final description = e['description']?.toString().trim() ?? '';
          if (title.isEmpty && description.isEmpty) return <String, String>{};
          return {'title': title, 'description': description};
        })
        .where((e) => e.isNotEmpty)
        .toList();
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
    return PoojaModel(
      id: _str(json, ['_id', 'id']),
      title: _str(json, ['title', 'pooja_name', 'poojaName', 'name']),
      deity: _str(json, ['deity', 'deityName', 'deity_name']),
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
      steps:
          (json['steps'] as List?)
              ?.map((e) {
                if (e is Map) {
                  return e['title']?.toString().trim() ??
                      e['description']?.toString().trim() ??
                      '';
                }
                return e?.toString().trim() ?? '';
              })
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
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
  Map<String, dynamic> toJson() => {
    'title': title,
    'deity': deity,
    'category': category,
    'difficulty': difficulty,
    'duration': duration,
    'description': description,
    'status': _toApiStatus(status), // 'Pending' → 'PENDING', 'Draft' → 'DRAFT'
    if (date != null) 'date': date,
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
      final raw = e.value.trim();
      final parts = raw.split('||');
      final title = parts.first.trim();
      final description = parts.length > 1
          ? parts.sublist(1).join('||').trim()
          : title;
      return {
        'stepNumber': e.key + 1,
        'title': title,
        'description': description,
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
    },
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
    if (poojaDate != null && poojaDate!.trim().isNotEmpty) 'date': poojaDate,
  };

  PoojaModel copyWith({
    String? title,
    String? deity,
    String? category,
    String? difficulty,
    String? duration,
    String? description,
    String? status,
    String? date,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
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
      deity: deity ?? this.deity,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      status: status ?? this.status,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
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
