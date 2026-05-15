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
    if (mantra != null) 'mantra': mantra,
    if (affirmation != null) 'affirmation': affirmation,
  };
}

class RitualSection {
  const RitualSection({required this.title, required this.content});

  final String title;
  final String content;

  factory RitualSection.fromJson(Map<String, dynamic> json) {
    // Handle both old flat structure and new nested structure from backend
    final String title = (json['label'] ?? json['title'] ?? '').toString();
    String content = (json['content'] ?? '').toString();

    if (json['contents'] is List && (json['contents'] as List).isNotEmpty) {
      final firstContent = (json['contents'] as List).first;
      if (firstContent is Map) {
        content =
            (firstContent['description'] ?? firstContent['content'] ?? content)
                .toString();
      }
    }

    return RitualSection(title: title, content: content);
  }

  Map<String, dynamic> toJson() => {
    'key': title.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
    'label': title,
    'contents': [
      {'title': title, 'description': content, 'imageUrl': ''},
    ],
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
    this.recommendedDuration,
    this.bestDayTime,
    this.accessType = 'FREE',
    this.price = 0,
    this.currency = 'ZAR',
    this.difficulty = 'BEGINNER',
    this.isFeatured = false,
    this.status = 'DRAFT',
    this.days = const [],
    this.sections = const [],
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
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? createdAt;
  final String? updatedAt;

  factory RitualModel.fromJson(Map<String, dynamic> json) {
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
      recommendedDuration: json['recommendedDuration']?.toString(),
      bestDayTime: json['bestDayTime']?.toString(),
      accessType: (json['accessType'] ?? 'FREE').toString(),
      price: (json['price'] ?? 0) as num,
      currency: (json['currency'] ?? 'ZAR').toString(),
      difficulty: (json['difficulty'] ?? 'BEGINNER').toString(),
      isFeatured: (json['isFeatured'] ?? false) as bool,
      status: (json['status'] ?? 'DRAFT').toString(),
      days: (json['days'] is List)
          ? (json['days'] as List)
                .map((e) => RitualDay.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      sections: (json['sections'] is List)
          ? (json['sections'] as List)
                .map((e) => RitualSection.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      audioUrl: json['audioUrl']?.toString() ?? json['audio']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? json['video']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (slug != null) 'slug': slug,
      if (description != null) 'description': description,
      'deity': deity,
      if (category != null) 'category': category,
      if (purpose != null) 'purpose': purpose,
      if (startingDay != null) 'startingDay': startingDay,
      if (recommendedDuration != null)
        'recommendedDuration': recommendedDuration,
      if (bestDayTime != null) 'bestDayTime': bestDayTime,
      'accessType': accessType,
      'price': price,
      'currency': currency,
      'difficulty': difficulty,
      'isFeatured': isFeatured,
      'status': status,
      'ritualDays': days.length,
      'days': days.map((e) => e.toJson()).toList(),
      'sections': sections.map((e) => e.toJson()).toList(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
