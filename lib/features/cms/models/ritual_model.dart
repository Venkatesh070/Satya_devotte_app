// lib/features/cms/models/ritual_model.dart

class RitualDay {
  const RitualDay({
    required this.dayNumber,
    required this.title,
    required this.activities,
    this.mantra,
    this.affirmation,
  });

  final int dayNumber;
  final String title;
  final List<String> activities;
  final String? mantra;
  final String? affirmation;

  factory RitualDay.fromJson(Map<String, dynamic> json) {
    return RitualDay(
      dayNumber: (json['dayNumber'] ?? 0) as int,
      title: (json['title'] ?? '').toString(),
      activities:
          (json['activities'] as List?)?.map((e) => e.toString()).toList() ??
          (json['instructions'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      mantra: (json['mantra'] ?? json['chant'])?.toString(),
      affirmation: (json['affirmation'] ?? json['offering'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dayNumber': dayNumber,
    'title': title,
    'activities': activities,
    if (mantra != null && mantra!.isNotEmpty) 'mantra': mantra,
    if (affirmation != null && affirmation!.isNotEmpty) 'affirmation': affirmation,
  };

  RitualDay copyWith({
    int? dayNumber,
    String? title,
    List<String>? activities,
    String? mantra,
    String? affirmation,
  }) {
    return RitualDay(
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      activities: activities ?? this.activities,
      mantra: mantra ?? this.mantra,
      affirmation: affirmation ?? this.affirmation,
    );
  }
}

class RitualSectionContent {
  const RitualSectionContent({
    this.title = '',
    this.description = '',
    this.imageUrl = '',
  });

  final String title;
  final String description;
  final String imageUrl;

  factory RitualSectionContent.fromJson(Map<String, dynamic> json) {
    return RitualSectionContent(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? json['content'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
  };

  RitualSectionContent copyWith({
    String? title,
    String? description,
    String? imageUrl,
  }) {
    return RitualSectionContent(
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class RitualSection {
  const RitualSection({
    required this.key,
    required this.label,
    this.contents = const [],
  });

  final String key;
  final String label;
  final List<RitualSectionContent> contents;

  /// Back-compat for legacy flat section shape.
  String get title => label;

  String get content =>
      contents.isNotEmpty ? contents.first.description : '';

  factory RitualSection.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] ?? json['title'] ?? '').toString();
    var key = (json['key'] ?? '').toString();
    if (key.isEmpty && label.isNotEmpty) {
      key = _slugifyKey(label);
    }

    final contents = <RitualSectionContent>[];
    if (json['contents'] is List) {
      for (final item in json['contents'] as List) {
        if (item is Map) {
          contents.add(
            RitualSectionContent.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    if (contents.isEmpty) {
      final legacy = (json['content'] ?? json['description'] ?? '').toString();
      if (legacy.isNotEmpty || label.isNotEmpty) {
        contents.add(
          RitualSectionContent(title: label, description: legacy),
        );
      }
    }
    if (contents.isEmpty) {
      contents.add(const RitualSectionContent());
    }

    return RitualSection(key: key, label: label, contents: contents);
  }

  Map<String, dynamic> toJson() => {
    'key': key.isNotEmpty ? key : _slugifyKey(label),
    'label': label,
    'contents': contents.map((e) => e.toJson()).toList(),
  };

  RitualSection copyWith({
    String? key,
    String? label,
    List<RitualSectionContent>? contents,
  }) {
    return RitualSection(
      key: key ?? this.key,
      label: label ?? this.label,
      contents: contents ?? this.contents,
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
      if (v is! List) return [];
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
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
    required this.deity,
    this.category,
    this.purpose,
    this.startingDay,
    this.ritualDays,
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
  final String deity;
  final String? category;
  final String? purpose;
  final String? startingDay;
  final int? ritualDays;
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

  factory RitualModel.fromJson(Map<String, dynamic> json) {
    final daysList = (json['days'] is List)
        ? (json['days'] as List)
              .map((e) => RitualDay.fromJson(e as Map<String, dynamic>))
              .toList()
        : <RitualDay>[];

    final parsedRitualDays = json['ritualDays'];
    int? ritualDays;
    if (parsedRitualDays is int) {
      ritualDays = parsedRitualDays;
    } else if (parsedRitualDays != null) {
      ritualDays = int.tryParse(parsedRitualDays.toString());
    }
    ritualDays ??= daysList.isNotEmpty ? daysList.length : null;

    RitualMedia media = const RitualMedia();
    if (json['media'] is Map) {
      media = RitualMedia.fromJson(
        Map<String, dynamic>.from(json['media'] as Map),
      );
    }

    return RitualModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      deity:
          (json['deity'] is Map
                  ? (json['deity']['_id'] ?? json['deity']['id'] ?? '')
                  : (json['deity'] ?? ''))
              .toString(),
      category: json['category']?.toString(),
      purpose: json['purpose']?.toString(),
      startingDay: json['startingDay']?.toString(),
      ritualDays: ritualDays,
      recommendedDuration: json['recommendedDuration']?.toString(),
      bestDayTime: json['bestDayTime']?.toString(),
      accessType: (json['accessType'] ?? 'FREE').toString(),
      price: (json['price'] ?? 0) as num,
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
      imageUrl:
          json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          (media.images.isNotEmpty ? media.images.first : null),
      audioUrl:
          json['audioUrl']?.toString() ??
          json['audio']?.toString() ??
          (media.audio.isNotEmpty ? media.audio.first : null),
      videoUrl:
          json['videoUrl']?.toString() ??
          json['video']?.toString() ??
          (media.videos.isNotEmpty ? media.videos.first : null),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final dayCount = ritualDays ?? days.length;
    return {
      'title': title,
      if (slug != null && slug!.isNotEmpty) 'slug': slug,
      if (description != null) 'description': description,
      'deity': deity,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (purpose != null && purpose!.isNotEmpty) 'purpose': purpose,
      if (startingDay != null && startingDay!.isNotEmpty)
        'startingDay': startingDay,
      if (dayCount > 0) 'ritualDays': dayCount,
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
      'media': media.toJson(),
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (audioUrl != null && audioUrl!.isNotEmpty) 'audioUrl': audioUrl,
      if (videoUrl != null && videoUrl!.isNotEmpty) 'videoUrl': videoUrl,
    };
  }

  RitualModel copyWith({
    String? title,
    String? slug,
    String? description,
    String? deity,
    String? category,
    String? purpose,
    String? startingDay,
    int? ritualDays,
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
      deity: deity ?? this.deity,
      category: category ?? this.category,
      purpose: purpose ?? this.purpose,
      startingDay: startingDay ?? this.startingDay,
      ritualDays: ritualDays ?? this.ritualDays,
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
