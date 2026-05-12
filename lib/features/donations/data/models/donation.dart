// User-facing donation campaign model (approved + visible).
//
// Decoupled from `lib/features/cms/models/donation_model.dart` because the
// CMS model carries admin-only fields (review status, createdBy, …) that
// users never see. Keep this lean.
class Donation {
  const Donation({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;

  static String _str(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && v is! List && v is! Map) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
        id: _str(json, ['_id', 'id']),
        title: _str(json, ['title', 'name']),
        description: _str(json, ['description']),
        imageUrl: () {
          final v =
              _str(json, ['image', 'imageUrl', 'cover', 'coverImage']);
          return v.isEmpty ? null : v;
        }(),
      );
}
