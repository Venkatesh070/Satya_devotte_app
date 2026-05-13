// Bridges the device FCM token to the backend registry.
//
// Lifecycle:
//   • `registerWithBackend()` — call from each successful auth path
//     (Google / Email / Email-SignUp / Admin login + restored session).
//     Resolves the device token, requests notification permission on iOS,
//     posts to `/fcm/register`, and subscribes to `onTokenRefresh` so any
//     future rotation is silently re-registered (backend is idempotent).
//   • `unregisterFromBackend()` — call from logout BEFORE the session is
//     cleared (the auth interceptor needs the bearer to be valid). The
//     last-known token is preferred; we fall back to `getToken()` so that
//     even a restored session can be cleaned up correctly.
//
// Flutter web: FCM web push requires VAPID + a service worker the project
// does not yet ship, so we no-op rather than fail noisily. Mobile flows
// are unaffected.
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show Random;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fcm_api.dart';
import 'fcm_exception.dart';

class FcmBootstrap {
  FcmBootstrap(this._api);
  final FcmApi _api;

  String? _lastRegisteredToken;
  StreamSubscription<String>? _refreshSub;
  bool _registering = false;

  /// Returns the most recent token we successfully registered with the
  /// backend during this app session (or `null` if none).
  String? get lastRegisteredToken => _lastRegisteredToken;

  /// Idempotent — calling this twice in a row from concurrent login
  /// callbacks is safe; the second call short-circuits.
  Future<void> registerWithBackend() async {
    if (kIsWeb) {
      debugPrint('[FCM] register skipped on web (VAPID not configured).');
      return;
    }
    if (_registering) return;
    _registering = true;
    try {
      // iOS / macOS: explicit permission gate before `getToken()`.
      if (Platform.isIOS || Platform.isMacOS) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('[FCM] permission denied — skipping register.');
          return;
        }
      }
      // On Android, the system notification permission is handled inside
      // `NotificationService.initialize()` at startup. We just need the
      // token here.
      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (token == null || token.length < 20) {
        debugPrint('[FCM] getToken() returned no token; skipping register.');
        return;
      }
      final platform = _platformLabel();
      final deviceId = await _deviceId();
      try {
        await _api.registerToken(
          token: token,
          platform: platform,
          deviceId: deviceId,
        );
        _lastRegisteredToken = token;
        debugPrint('[FCM] registered token (${token.substring(0, 12)}…).');
      } on FcmException catch (e) {
        debugPrint('[FCM] register failed: $e');
      }
      // Make sure token rotations land on the server too.
      await _refreshSub?.cancel();
      _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
          if (newToken.length < 20) return;
          try {
            await _api.registerToken(
              token: newToken,
              platform: platform,
              deviceId: deviceId,
            );
            _lastRegisteredToken = newToken;
            debugPrint('[FCM] refreshed token re-registered.');
          } on FcmException catch (e) {
            debugPrint('[FCM] refresh register failed: $e');
          }
        },
        onError: (e) => debugPrint('[FCM] onTokenRefresh error: $e'),
      );
    } catch (e) {
      // Never block sign-in on FCM failures.
      debugPrint('[FCM] register unexpected error: $e');
    } finally {
      _registering = false;
    }
  }

  /// Should be invoked **before** the auth session is cleared so the Dio
  /// interceptor can still attach a valid bearer to the DELETE.
  Future<void> unregisterFromBackend() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (kIsWeb) {
      _lastRegisteredToken = null;
      return;
    }
    try {
      var token = _lastRegisteredToken;
      // Fall back to the live device token (e.g. when the session was
      // restored at app launch and we never re-registered this run).
      token ??= await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (token == null || token.isEmpty) return;
      try {
        await _api.unregisterToken(token);
        debugPrint('[FCM] unregistered token (${token.substring(0, 12)}…).');
      } on FcmException catch (e) {
        debugPrint('[FCM] unregister failed: $e');
      }
      try {
        await FirebaseMessaging.instance.deleteToken();
        debugPrint('[FCM] deleteToken() completed.');
      } catch (e) {
        debugPrint('[FCM] deleteToken failed: $e');
      }
    } catch (e) {
      debugPrint('[FCM] unregister unexpected error: $e');
    } finally {
      _lastRegisteredToken = null;
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    // Backend only knows the three values above — coerce desktop/test
    // builds to a sane default so the request still validates.
    return 'android';
  }

  /// Stable per-install identifier persisted in SharedPreferences. Used
  /// purely as a hint for the backend (the plan flags it as optional).
  Future<String> _deviceId() async {
    const key = 'fcm.deviceId';
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(key);
      if (id == null || id.isEmpty) {
        id =
            '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
            '${Random.secure().nextInt(1 << 31).toRadixString(36)}';
        await prefs.setString(key, id);
      }
      return id;
    } catch (_) {
      return '';
    }
  }
}
