import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionService {
  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _userDataKey = 'auth.userData';
  static const _lastActivityKey = 'auth.lastActivity';
  static const int maxInactivityDays = 7;

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userData;
  int? _lastActivityTimestamp;
  bool _wasSessionExpiredOnLaunch = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userData => _userData;
  bool get wasSessionExpiredOnLaunch => _wasSessionExpiredOnLaunch;

  // ─── Role helpers ─────────────────────────────────────────────
  String get userRole {
    final stored = (_userData?['role'] as String? ?? 'user')
        .trim()
        .toLowerCase();
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
      SharedPreferences.getInstance().then((prefs) {
        try {
          prefs.setString(_userDataKey, jsonEncode(_userData));
        } catch (_) {}
      });
    }
  }

  /// Extracts the expiration DateTime (`exp` claim) from a JWT token string.
  DateTime? getJwtExpiration(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic> && data['exp'] is num) {
        final expSeconds = (data['exp'] as num).toInt();
        return DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
      }
    } catch (_) {}
    return null;
  }

  /// Updates the last active timestamp when user performs API interactions.
  void touchActivity() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastActivityTimestamp = now;
    SharedPreferences.getInstance().then((prefs) {
      try {
        prefs.setInt(_lastActivityKey, now);
      } catch (_) {}
    });
  }

  Future<void> setSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userData = userData;
    _wasSessionExpiredOnLaunch = false;
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastActivityTimestamp = now;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userDataKey, jsonEncode(userData));
      await prefs.setInt(_lastActivityKey, now);
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
    _wasSessionExpiredOnLaunch = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);
      final raw = prefs.getString(_userDataKey);
      if (token == null || token.isEmpty || raw == null || raw.isEmpty) {
        return false;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;

      final now = DateTime.now();

      // 1. Check exact JWT expiration date (exp claim) if available
      final jwtExpiry = getJwtExpiration(token);
      if (jwtExpiry != null && now.isAfter(jwtExpiry)) {
        _wasSessionExpiredOnLaunch = true;
        await clear();
        return false;
      }

      // 2. Check 7-day inactivity threshold
      final lastActivity = prefs.getInt(_lastActivityKey);
      if (lastActivity != null) {
        final lastTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
        if (lastTime.isAfter(now)) {
          // System clock was set backward after testing: reset last activity to current time
          await prefs.setInt(_lastActivityKey, now.millisecondsSinceEpoch);
        } else {
          final differenceDays = now.difference(lastTime).inDays;
          if (differenceDays >= maxInactivityDays) {
            _wasSessionExpiredOnLaunch = true;
            await clear();
            return false;
          }
        }
      } else {
        // Legacy session without saved lastActivity timestamp: set current timestamp
        await prefs.setInt(_lastActivityKey, now.millisecondsSinceEpoch);
      }

      _accessToken = token;
      _refreshToken = prefs.getString(_refreshTokenKey);
      _userData = decoded;
      _lastActivityTimestamp = lastActivity ?? now.millisecondsSinceEpoch;
      return true;
    } catch (_) {
      return false;
    }
  }

  int? get lastActivityTimestamp => _lastActivityTimestamp;

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userData = null;
    _lastActivityTimestamp = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_lastActivityKey);
    } catch (_) {}
  }
}
