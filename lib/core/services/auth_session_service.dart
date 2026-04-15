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
    } catch (_) {
      // Return current in-memory value when storage channel fails.
    }
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      return _refreshToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _refreshToken = prefs.getString(_refreshTokenKey);
    } catch (_) {
      // Return current in-memory value when storage channel fails.
    }
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
      // Return current in-memory value when storage channel fails.
      return _userData;
    }
    if (raw == null || raw.isEmpty) {
      return null;
    }
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

  @Deprecated('Use setSession to store all auth values together.')
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } catch (_) {}
  }

  @Deprecated('Use setSession to store all auth values together.')
  Future<void> setUser(Map<String, dynamic> user) async {
    _userData = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(user));
    } catch (_) {}
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
