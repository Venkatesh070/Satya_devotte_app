// lib/features/cms/models/ritual_model.dart

class RitualDayStep {
  const RitualDayStep({
    required this.stepNumber,
    required this.title,
    this.description = '',
    this.images = const [],
    this.subSteps = const [],
  });

  final int stepNumber;
  final String title;
  final String description;
  final List<String> images;
  final List<String> subSteps;

  factory RitualDayStep.fromJson(Map<String, dynamic> json) {
    final stepNumber = RitualDay._parseStepNumber(json);
    return RitualDayStep(
      stepNumber: stepNumber,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      images: RitualDay._parseImages(json),
      subSteps: RitualDay._parseSubSteps(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'title': title,
    'description': description,
    if (images.isNotEmpty) 'images': images,
    if (subSteps.isNotEmpty) 'subSteps': subSteps,
  };

  RitualDayStep copyWith({
    int? stepNumber,
    String? title,
    String? description,
    List<String>? images,
    List<String>? subSteps,
  }) {
    return RitualDayStep(
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      subSteps: subSteps ?? this.subSteps,
    );
  }
}

class RitualDay {
  const RitualDay({
    required this.stepNumber,
    required this.title,
    this.description = '',
    this.images = const [],
    this.subSteps = const [],
    this.requiredItems = const [],
    this.satyaBlessings = '',
    this.steps = const [],
  });

  /// Matches ritual day schema: stepNumber, title, description, images,
  /// requiredItems, satyaBlessings, and nested steps.
  final int stepNumber;
  final String title;
  final String description;
  final List<String> images;
  final List<String> subSteps;
  final List<String> requiredItems;
  final String satyaBlessings;
  final List<RitualDayStep> steps;

  int get dayNumber => stepNumber;

  factory RitualDay.fromJson(Map<String, dynamic> json) {
    final stepNumber = _parseStepNumber(json);
    final parsedSubSteps = _parseSubSteps(json);
    final requiredItems = _parseStringList(json['requiredItems']);
    final stepsRaw = json['steps'];
    List<RitualDayStep> steps = stepsRaw is List
        ? stepsRaw
              .whereType<Map>()
              .map((e) => RitualDayStep.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <RitualDayStep>[];

    if (steps.isEmpty && parsedSubSteps.isNotEmpty) {
      steps = parsedSubSteps
          .asMap()
          .entries
          .map(
            (e) => RitualDayStep(
              stepNumber: e.key + 1,
              title: 'Step ${e.key + 1}',
              description: e.value,
            ),
          )
          .toList();
    }

    return RitualDay(
      stepNumber: stepNumber,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      images: _parseImages(json),
      subSteps: steps.isNotEmpty ? const [] : parsedSubSteps,
      requiredItems: requiredItems,
      satyaBlessings: (json['satyaBlessings'] ?? '').toString(),
      steps: steps,
    );
  }

  static List<String> _parseImages(Map<String, dynamic> json) {
    final fromList = _parseStringList(json['images']);
    if (fromList.isNotEmpty) return fromList;

    final fromUrls = _parseStringList(json['imageUrls']);
    if (fromUrls.isNotEmpty) return fromUrls;

    final single = json['imageUrl'] ?? json['image'];
    if (single != null) {
      final cleaned = _cleanImageUrl(single.toString());
      if (cleaned.isNotEmpty) return [cleaned];
    }
    return const [];
  }

  static String _cleanImageUrl(String url) {
    return url.replaceAll('`', '').trim();
  }

  static int _parseStepNumber(Map<String, dynamic> json) {
    final raw = json['stepNumber'] ?? json['dayNumber'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => _cleanImageUrl(e.toString()))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _parseSubSteps(Map<String, dynamic> json) {
    final fromSubSteps = _parseStringList(json['subSteps']);
    if (fromSubSteps.isNotEmpty) return fromSubSteps;

    final fromActivities = _parseStringList(json['activities']);
    if (fromActivities.isNotEmpty) return fromActivities;

    final legacy = <String>[];
    final mantra = (json['mantra'] ?? json['chant'])?.toString().trim() ?? '';
    final affirmation =
        (json['affirmation'] ?? json['offering'])?.toString().trim() ?? '';
    if (mantra.isNotEmpty) legacy.add(mantra);
    if (affirmation.isNotEmpty) legacy.add(affirmation);
    return legacy;
  }

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'title': title,
    'description': description,
    'satyaBlessings': satyaBlessings,
    if (images.isNotEmpty) 'images': images,
    if (subSteps.isNotEmpty) 'subSteps': subSteps,
    if (requiredItems.isNotEmpty) 'requiredItems': requiredItems,
    if (steps.isNotEmpty) 'steps': steps.map((e) => e.toJson()).toList(),
  };

  RitualDay copyWith({
    int? stepNumber,
    String? title,
    String? description,
    List<String>? images,
    List<String>? subSteps,
    List<String>? requiredItems,
    String? satyaBlessings,
    List<RitualDayStep>? steps,
  }) {
    return RitualDay(
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      subSteps: subSteps ?? this.subSteps,
      requiredItems: requiredItems ?? this.requiredItems,
      satyaBlessings: satyaBlessings ?? this.satyaBlessings,
      steps: steps ?? this.steps,
    );
  }
}

class RitualSection {
  const RitualSection({
    required this.key,
    required this.label,
    this.description = '',
  });

  final String key;
  final String label;
  final String description;

  /// Back-compat for legacy flat section shape.
  String get title => label;

  String get content => description;

  factory RitualSection.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] ?? json['title'] ?? '').toString();
    var key = (json['key'] ?? '').toString();
    if (key.isEmpty && label.isNotEmpty) {
      key = _slugifyKey(label);
    }

    var description =
        (json['description'] ?? json['content'] ?? '').toString();

    // Migrate legacy nested contents[] into a single description.
    if (description.trim().isEmpty && json['contents'] is List) {
      final parts = <String>[];
      for (final item in json['contents'] as List) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final itemTitle = (map['title'] ?? '').toString().trim();
        final desc =
            (map['description'] ?? map['content'] ?? '').toString().trim();
        if (itemTitle.isNotEmpty && desc.isNotEmpty) {
          parts.add('$itemTitle\n$desc');
        } else if (itemTitle.isNotEmpty) {
          parts.add(itemTitle);
        } else if (desc.isNotEmpty) {
          parts.add(desc);
        }
      }
      description = parts.join('\n\n');
    }

    return RitualSection(key: key, label: label, description: description);
  }

  Map<String, dynamic> toJson() => {
    'key': key.isNotEmpty ? key : _slugifyKey(label),
    'label': label,
    'description': description,
  };

  RitualSection copyWith({
    String? key,
    String? label,
    String? description,
  }) {
    return RitualSection(
      key: key ?? this.key,
      label: label ?? this.label,
      description: description ?? this.description,
    );
  }

  static String _slugifyKey(String label) {
    return label
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class RitualMedia {
  const RitualMedia({
    this.images = const [],
    this.audio = const [],
    this.videos = const [],
  });

  final List<String> images;
  final List<String> audio;
  final List<String> videos;

  factory RitualMedia.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RitualMedia();
    List<String> strings(dynamic v) {
      if (v is! List) {
        final single = RitualModel._cleanMediaUrl(v);
        return single == null ? <String>[] : [single];
      }
      return v
          .map(RitualModel._cleanMediaUrl)
          .whereType<String>()
          .toList();
    }

    return RitualMedia(
      images: strings(json['images']),
      audio: strings(json['audio']),
      videos: strings(json['videos']),
    );
  }

  Map<String, dynamic> toJson() => {
    'images': images,
    'audio': audio,
    'videos': videos,
  };
}

class RitualModel {
  const RitualModel({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    required this.deities,
    this.festivalIds = const [],
    this.category,
    this.purpose,
    this.startingDay,
    this.ritualDay,
    this.recommendedDuration,
    this.bestDayTime,
    this.accessType = 'FREE',
    this.price = 0,
    this.currency = 'ZAR',
    this.difficulty = 'BEGINNER',
    this.isFeatured = false,
    this.status = 'PENDING',
    this.days = const [],
    this.sections = const [],
    this.media = const RitualMedia(),
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? slug;
  final String? description;
  final List<String> deities;
  String get deity => deities.join(', ');
  final List<String> festivalIds;
  final String? category;
  final String? purpose;
  final String? startingDay;
  final String? ritualDay;
  final String? recommendedDuration;
  final String? bestDayTime;
  final String accessType;
  final num price;
  final String currency;
  final String difficulty;
  final bool isFeatured;
  final String status;
  final List<RitualDay> days;
  final List<RitualSection> sections;
  final RitualMedia media;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? createdAt;
  final String? updatedAt;

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
      final id = (raw['_id'] ?? raw['id'] ?? '').toString().trim();
      if (id.isNotEmpty) return [id];
    }
    final single = (json['deity'] ?? '').toString().trim();
    if (single.isNotEmpty) return [single];
    return const [];
  }

  static String? _extractId(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }
    if (raw is Map) {
      final id = (raw['_id'] ?? raw['id'] ?? '').toString().trim();
      return id.isEmpty ? null : id;
    }
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _extractFestivalIds(Map<String, dynamic> json) {
    final raw = json['festivalIds'];
    if (raw is! List) return const [];
    return raw
        .map(_extractId)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _parseDocumentId(Map<String, dynamic> json) {
    final raw = json['_id'] ?? json['id'];
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is Map) {
      final oid = raw[r'$oid'] ?? raw['oid'];
      if (oid is String) return oid.trim();
    }
    final text = raw.toString().trim();
    if (text.startsWith('ObjectId(') && text.endsWith(')')) {
      return text.substring(9, text.length - 1).trim();
    }
    return text;
  }

  static num _parseNum(dynamic raw) {
    if (raw is num) return raw;
    if (raw == null) return 0;
    return num.tryParse(raw.toString().trim()) ?? 0;
  }

  static String? _cleanMediaUrl(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      for (final item in raw) {
        final cleaned = _cleanMediaUrl(item);
        if (cleaned != null) return cleaned;
      }
      return null;
    }
    if (raw is Map) {
      return _cleanMediaUrl(
        raw['url'] ?? raw['imageUrl'] ?? raw['src'] ?? raw['path'],
      );
    }
    final text = raw.toString().replaceAll('`', '').trim();
    if (text.isEmpty || text == 'null' || text == 'undefined') return null;
    return text;
  }

  static List<String> _cleanMediaUrlList(dynamic raw) {
    if (raw is! List) {
      final single = _cleanMediaUrl(raw);
      return single == null ? const [] : [single];
    }
    final out = <String>[];
    for (final item in raw) {
      final cleaned = _cleanMediaUrl(item);
      if (cleaned != null && !out.contains(cleaned)) out.add(cleaned);
    }
    return out;
  }

  factory RitualModel.fromJson(Map<String, dynamic> json) {
    if (json['ritual'] is Map) {
      return RitualModel.fromJson(
        Map<String, dynamic>.from(json['ritual'] as Map),
      );
    }
    if (json['data'] is Map) {
      final data = Map<String, dynamic>.from(json['data'] as Map);
      if (data['ritual'] is Map) {
        return RitualModel.fromJson(
          Map<String, dynamic>.from(data['ritual'] as Map),
        );
      }
      if (data['title'] != null || data['_id'] != null || data['id'] != null) {
        return RitualModel.fromJson(data);
      }
    }

    final daysList = (json['days'] is List)
        ? (json['days'] as List)
              .map((e) => RitualDay.fromJson(e as Map<String, dynamic>))
              .toList()
        : <RitualDay>[];

    final ritualDayRaw = json['ritualDay'] ?? json['ritualDays'];
    String? ritualDay;
    if (ritualDayRaw != null) {
      final text = ritualDayRaw.toString().trim();
      if (text.isNotEmpty) ritualDay = text;
    }

    RitualMedia media = const RitualMedia();
    final topImages = _cleanMediaUrlList(json['images']);
    final topAudio = _cleanMediaUrlList(json['audio']);
    final topVideos = _cleanMediaUrlList(json['videos']);

    if (json['media'] is Map) {
      media = RitualMedia.fromJson(
        Map<String, dynamic>.from(json['media'] as Map),
      );
    }
    if (media.images.isEmpty && topImages.isNotEmpty) {
      media = RitualMedia(
        images: topImages,
        audio: media.audio.isNotEmpty ? media.audio : topAudio,
        videos: media.videos.isNotEmpty ? media.videos : topVideos,
      );
    } else if (media.images.isEmpty &&
        media.audio.isEmpty &&
        media.videos.isEmpty &&
        json['media'] is! Map) {
      media = RitualMedia(
        images: topImages,
        audio: topAudio,
        videos: topVideos,
      );
    }

    final coverUrl =
        _cleanMediaUrl(json['imageUrl']) ??
        _cleanMediaUrl(json['image']) ??
        (media.images.isNotEmpty ? media.images.first : null);

    return RitualModel(
      id: _parseDocumentId(json),
      title: (json['title'] ?? '').toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      deities: _extractDeityIds(json),
      festivalIds: _extractFestivalIds(json),
      category: json['category']?.toString(),
      purpose: json['purpose']?.toString(),
      startingDay: json['startingDay']?.toString(),
      ritualDay: ritualDay,
      recommendedDuration: json['recommendedDuration']?.toString(),
      bestDayTime: json['bestDayTime']?.toString(),
      accessType: (json['accessType'] ?? 'FREE').toString(),
      price: _parseNum(json['price']),
      currency: (json['currency'] ?? 'ZAR').toString(),
      difficulty: (json['difficulty'] ?? 'BEGINNER').toString(),
      isFeatured: json['isFeatured'] == true,
      status: (json['status'] ?? 'PENDING').toString(),
      days: daysList,
      sections: (json['sections'] is List)
          ? (json['sections'] as List)
                .map((e) => RitualSection.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      media: media,
      imageUrl: coverUrl,
      audioUrl:
          _cleanMediaUrl(json['audioUrl']) ??
          (media.audio.isNotEmpty ? media.audio.first : null),
      videoUrl:
          _cleanMediaUrl(json['videoUrl']) ??
          (media.videos.isNotEmpty ? media.videos.first : null),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  bool get isMultiDayRitual {
    final label = (ritualDay ?? '').trim().toLowerCase();
    if (label.contains('multiple')) return true;
    if (label.contains('1 day')) return false;
    return days.length > 1;
  }

  RitualDay? dayByNumber(int dayNumber) {
    for (final day in days) {
      if (day.stepNumber == dayNumber) return day;
    }
    if (dayNumber >= 1 && dayNumber <= days.length) {
      return days[dayNumber - 1];
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final cover = _cleanMediaUrl(imageUrl) ??
        (media.images.isNotEmpty ? _cleanMediaUrl(media.images.first) : null);
    final images = <String>[
      if (cover != null) cover,
      ...media.images
          .map(_cleanMediaUrl)
          .whereType<String>()
          .where((url) => url != cover),
    ];
    final audio = <String>[
      if (_cleanMediaUrl(audioUrl) != null) _cleanMediaUrl(audioUrl)!,
      ...media.audio
          .map(_cleanMediaUrl)
          .whereType<String>()
          .where((url) => url != audioUrl),
    ];
    final videos = <String>[
      if (_cleanMediaUrl(videoUrl) != null) _cleanMediaUrl(videoUrl)!,
      ...media.videos
          .map(_cleanMediaUrl)
          .whereType<String>()
          .where((url) => url != videoUrl),
    ];

    return {
      'title': title,
      if (slug != null && slug!.isNotEmpty) 'slug': slug,
      if (description != null) 'description': description,
      'deity': deities,
      'festivalIds': festivalIds,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (purpose != null && purpose!.isNotEmpty) 'purpose': purpose,
      if (startingDay != null && startingDay!.isNotEmpty)
        'startingDay': startingDay,
      if (ritualDay != null && ritualDay!.isNotEmpty) 'ritualDay': ritualDay,
      if (bestDayTime != null && bestDayTime!.isNotEmpty)
        'bestDayTime': bestDayTime,
      'accessType': accessType,
      'price': price,
      'currency': currency,
      'difficulty': difficulty,
      'isFeatured': isFeatured,
      'status': status,
      'days': days.map((e) => e.toJson()).toList(),
      'sections': sections.map((e) => e.toJson()).toList(),
      'images': images,
      'audio': audio,
      'videos': videos,
      'media': {
        'images': images,
        'audio': audio,
        'videos': videos,
      },
      if (cover != null) 'imageUrl': cover,
      if (cover != null) 'image': cover,
      if (audio.isNotEmpty) 'audioUrl': audio.first,
      if (videos.isNotEmpty) 'videoUrl': videos.first,
    };
  }

  RitualModel copyWith({
    String? title,
    String? slug,
    String? description,
    List<String>? deities,
    List<String>? festivalIds,
    String? category,
    String? purpose,
    String? startingDay,
    String? ritualDay,
    String? recommendedDuration,
    String? bestDayTime,
    String? accessType,
    num? price,
    String? currency,
    String? difficulty,
    bool? isFeatured,
    String? status,
    List<RitualDay>? days,
    List<RitualSection>? sections,
    RitualMedia? media,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
  }) {
    return RitualModel(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      deities: deities ?? this.deities,
      festivalIds: festivalIds ?? this.festivalIds,
      category: category ?? this.category,
      purpose: purpose ?? this.purpose,
      startingDay: startingDay ?? this.startingDay,
      ritualDay: ritualDay ?? this.ritualDay,
      recommendedDuration: recommendedDuration ?? this.recommendedDuration,
      bestDayTime: bestDayTime ?? this.bestDayTime,
      accessType: accessType ?? this.accessType,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      difficulty: difficulty ?? this.difficulty,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
      days: days ?? this.days,
      sections: sections ?? this.sections,
      media: media ?? this.media,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
