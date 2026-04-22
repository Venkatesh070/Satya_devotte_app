// lib/features/cms/models/donation_model.dart

class DonationModel {
  const DonationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.imageUrl,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String status; // Pending | Approved | Rejected
  final String? imageUrl;
  final String? createdBy; // MongoDB _id of creator
  final String? createdAt;
  final String? updatedAt;

  static String _normalizeStatus(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  static String _str(
    Map<String, dynamic> json,
    List<String> keys, [
    String fb = '',
  ]) {
    for (final k in keys) {
      final v = json[k];
      if (v != null &&
          v is! List &&
          v is! Map &&
          v.toString().trim().isNotEmpty)
        return v.toString().trim();
    }
    return fb;
  }

  static String? _extractId(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) return raw['_id']?.toString() ?? raw['id']?.toString();
    return null;
  }

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: _str(json, ['_id', 'id']),
      title: _str(json, ['title', 'name']),
      description: _str(json, ['description']),
      status: _normalizeStatus(json['status'] as String?),
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String?,
      createdBy: _extractId(json['createdBy']),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  DonationModel copyWith({
    String? title,
    String? description,
    String? status,
    String? imageUrl,
  }) => DonationModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    imageUrl: imageUrl ?? this.imageUrl,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
