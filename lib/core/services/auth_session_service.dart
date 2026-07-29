import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionService {
  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _userDataKey = 'auth.userData';

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userData;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userData => _userData;

  // ─── Role helpers ─────────────────────────────────────────────
  String get userRole {
    // API returns role:"admin" + isSuperAdmin:true for super admins.
    // After login _applyRole normalises and patches the stored value to
    // 'superadmin', so on session restore we read the patched value directly.
    final stored = (_userData?['role'] as String? ?? 'user')
        .trim()
        .toLowerCase();
    // Also honour the raw isSuperAdmin boolean if patch hasn't run yet
    if (_userData?['isSuperAdmin'] == true) return 'superadmin';
    if (stored == 'superadmin') return 'superadmin';
    if (stored == 'admin') return 'admin';
    return 'user';
  }

  bool get isSuperAdmin => userRole == 'superadmin';
  bool get isAdmin => userRole == 'admin' || isSuperAdmin;
  bool get isRegularUser => userRole == 'user';

  /// Patches the stored role in memory and SharedPreferences after normalisation.
  void patchRole(String normalisedRole) {
    if (_userData != null) {
      _userData!['role'] = normalisedRole;
      // Persist the patched userData so next loadPersistedSession gets it right
      SharedPreferences.getInstance().then((prefs) {
        try {
          prefs.setString(_userDataKey, jsonEncode(_userData));
        } catch (_) {}
      });
    }
  }

  Future<void> setSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userData = userData;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userDataKey, jsonEncode(userData));
    } catch (_) {
      // Keep in-memory values if SharedPreferences is temporarily unavailable.
    }
  }

  Future<String?> getAccessToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_accessTokenKey);
    } catch (_) {}
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      return _refreshToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _refreshToken = prefs.getString(_refreshTokenKey);
    } catch (_) {}
    return _refreshToken;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_userData != null) {
      return _userData;
    }
    String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_userDataKey);
    } catch (_) {
      return _userData;
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _userData = decoded;
        return _userData;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Load persisted session into memory — call on app start.
  Future<bool> loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);
      final raw = prefs.getString(_userDataKey);
      if (token == null || token.isEmpty || raw == null || raw.isEmpty) {
        return false;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      _accessToken = token;
      _refreshToken = prefs.getString(_refreshTokenKey);
      _userData = decoded;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userData = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
    } catch (_) {}
  }
}
