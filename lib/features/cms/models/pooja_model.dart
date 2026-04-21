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
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.steps = const [],
    this.requiredItems = const [],
    this.rating = 0.0,
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
  final String status;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> steps;
  final List<String> requiredItems;
  final double rating;
  final String? createdAt;
  final String? updatedAt;

  // ── Try multiple field names — handles API field name variations ──
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

  // ── Normalise status to match our filter values ───────────────
  static String _status(String raw) {
    final s = raw.toLowerCase();
    if (s == 'published' || s == 'active') return 'Published';
    if (s == 'pending' || s == 'pending_approval') return 'Pending';
    if (s == 'draft') return 'Draft';
    return raw; // keep original if unknown
  }

  factory PoojaModel.fromJson(Map<String, dynamic> json) {
    return PoojaModel(
      id: _str(json, ['_id', 'id']),
      // API may send: title | pooja_name | poojaName | name
      title: _str(json, ['title', 'pooja_name', 'poojaName', 'name']),
      // API may send: deity | deityName | deity_name
      deity: _str(json, ['deity', 'deityName', 'deity_name']),
      category: _str(json, ['category']),
      // API may send: difficulty | level | difficultyLevel
      difficulty: _str(json, [
        'difficulty',
        'level',
        'difficultyLevel',
      ], 'Beginner'),
      // API may send: duration | duration_mins | durationMins
      duration: _str(json, ['duration', 'duration_mins', 'durationMins']),
      description: _str(json, ['description', 'about']),
      // Normalise: active → Published, pending_approval → Pending
      status: _status(_str(json, ['status', 'pooja_status'], 'Draft')),
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      audioUrl: json['audioUrl'] as String? ?? json['audio'] as String?,
      videoUrl: json['videoUrl'] as String? ?? json['video'] as String?,
      steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
      requiredItems:
          (json['requiredItems'] as List?)?.map((e) => e.toString()).toList() ??
          (json['required_items'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'deity': deity,
    'category': category,
    'difficulty': difficulty,
    'duration': duration,
    'description': description,
    'status': status,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (audioUrl != null) 'audioUrl': audioUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    'steps': steps,
    'requiredItems': requiredItems,
  };

  PoojaModel copyWith({
    String? title,
    String? deity,
    String? category,
    String? difficulty,
    String? duration,
    String? description,
    String? status,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
    List<String>? steps,
    List<String>? requiredItems,
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
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      steps: steps ?? this.steps,
      requiredItems: requiredItems ?? this.requiredItems,
      rating: rating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
