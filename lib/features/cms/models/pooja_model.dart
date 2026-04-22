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
  final String
  status; // Internal display value: 'Approved' | 'Pending' | 'Draft' | 'Rejected'
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> steps;
  final List<String> requiredItems;
  final double rating;
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

  // ── Inbound: API value → internal display value ───────────────
  // API sends: APPROVED, REJECTED, PENDING, DRAFT, published, active, etc.
  // We normalise to: 'Approved' | 'Pending' | 'Draft' | 'Rejected'
  static String _fromApiStatus(String raw) {
    final s = raw.toLowerCase().trim();
    if (s == 'approved' || s == 'published' || s == 'active') return 'Approved';
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

  // ── toJson sends UPPERCASE status values the API accepts ─────
  Map<String, dynamic> toJson() => {
    'title': title,
    'deity': deity,
    'category': category,
    'difficulty': difficulty,
    'duration': duration,
    'description': description,
    'status': _toApiStatus(status), // 'Pending' → 'PENDING', 'Draft' → 'DRAFT'
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
