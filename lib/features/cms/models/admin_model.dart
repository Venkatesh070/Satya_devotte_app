// lib/features/cms/models/admin_model.dart

class AdminModel {
  const AdminModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.profileImage,
    this.createdAt,
    this.isActive = true,
    this.canLoginAdminPanel = true,
  });

  final String id;
  final String email;
  final String name;
  final String role; // 'admin' | 'superadmin' | 'user'
  final String? phone;
  final String? profileImage;
  final String? createdAt;
  final bool isActive;
  /// Whether this admin can sign in to the admin panel. Toggled via
  /// PATCH `/api/v1/superadmin/admins/:id/panel-access`.
  final bool canLoginAdminPanel;

  AdminModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? profileImage,
    String? createdAt,
    bool? isActive,
    bool? canLoginAdminPanel,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      canLoginAdminPanel: canLoginAdminPanel ?? this.canLoginAdminPanel,
    );
  }

  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  // Initials for avatar
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email[0].toUpperCase();
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
          v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return fb;
  }

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: _str(json, ['_id', 'id']),
      email: _str(json, ['email']),
      name: _str(json, ['name', 'displayName', 'fullName']),
      role: _str(json, ['role'], 'user'),
      phone: json['phone'] as String?,
      profileImage:
          json['profileImage'] as String? ?? json['photoURL'] as String?,
      createdAt: json['createdAt'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      canLoginAdminPanel:
          json['canLoginAdminPanel'] as bool? ??
          json['canAccessAdminPanel'] as bool? ??
          json['isAdminPanelEnabled'] as bool? ??
          true,
    );
  }
}
