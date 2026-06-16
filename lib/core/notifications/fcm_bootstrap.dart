// Bridges the device FCM token to the backend registry.
//
// Web: requires `FIREBASE_VAPID_KEY` + `web/firebase-messaging-sw.js`.
import 'dart:async';
import 'dart:math' show Random;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:satya_devotte_app/config/env/app_env.dart';
import 'package:satya_devotte_app/core/services/notification_platform.dart'
    as np;

import 'fcm_api.dart';
import 'fcm_exception.dart';

class FcmBootstrap {
  FcmBootstrap(this._api);
  final FcmApi _api;

  String? _lastRegisteredToken;
  StreamSubscription<String>? _refreshSub;
  bool _registering = false;

  String? get lastRegisteredToken => _lastRegisteredToken;

  Future<void> registerWithBackend() async {
    if (_registering) return;
    _registering = true;
    try {
      if (kIsWeb) {
        await _registerWeb();
      } else {
        await _registerMobile();
      }
    } catch (e) {
      debugPrint('[FCM] register unexpected error: $e');
    } finally {
      _registering = false;
    }
  }

  Future<void> _registerWeb() async {
    final vapidKey = AppEnv.firebaseVapidKey.trim();
    if (vapidKey.isEmpty) {
      debugPrint(
        '[FCM] web register skipped — set FIREBASE_VAPID_KEY '
        '(Firebase Console → Cloud Messaging → Web Push certificates).',
      );
      return;
    }
    if (!AppEnv.hasPlausibleFirebaseVapidKey) {
      debugPrint(
        '[FCM] FIREBASE_VAPID_KEY looks invalid (expected ~88-char public key '
        'from Firebase “Key pair”, not a short fragment). '
        'Current length: ${vapidKey.length}.',
      );
      return;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] web notification permission denied.');
      return;
    }

    final token = await FirebaseMessaging.instance
        .getToken(vapidKey: vapidKey)
        .timeout(const Duration(seconds: 15), onTimeout: () => null);
    if (token == null || token.length < 20) {
      debugPrint('[FCM] web getToken() returned no token.');
      return;
    }

    final deviceId = await _deviceId(webPrefix: true);
    try {
      await _api.registerToken(
        token: token,
        platform: 'web',
        deviceId: deviceId,
      );
      _lastRegisteredToken = token;
      debugPrint('[FCM] web token registered (${token.substring(0, 12)}…).');
    } on FcmException catch (e) {
      debugPrint('[FCM] web register failed: $e');
      return;
    }

    await _refreshSub?.cancel();
    _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) async {
      if (newToken.length < 20) return;
      try {
        await _api.registerToken(
          token: newToken,
          platform: 'web',
          deviceId: deviceId,
        );
        _lastRegisteredToken = newToken;
        debugPrint('[FCM] web token refresh re-registered.');
      } on FcmException catch (e) {
        debugPrint('[FCM] web refresh register failed: $e');
      }
    }, onError: (e) => debugPrint('[FCM] onTokenRefresh error: $e'));
  }

  Future<void> _registerMobile() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    if (np.notificationPlatformIsIOS || np.notificationPlatformIsMacOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] iOS permission status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] permission denied — skipping register.');
        return;
      }
      // iOS can return null FCM token until APNs token is available.
      final apnsToken = await _waitForApnsToken();
      if (apnsToken == null) {
        debugPrint('[FCM] APNs token unavailable — skipping register for now.');
        return;
      }
    }

    final token = await FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    if (token == null || token.length < 20) {
      debugPrint('[FCM] getToken() returned no token; skipping register.');
      return;
    }
    debugPrint('[FCM] getToken() success (${token.substring(0, 12)}…).');

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
      try {
        final count = await _api.registeredCount();
        debugPrint('[FCM] backend token count: $count');
      } catch (e) {
        debugPrint('[FCM] count check failed: $e');
      }
    } on FcmException catch (e) {
      debugPrint('[FCM] register failed: $e');
    }

    await _refreshSub?.cancel();
    _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) async {
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
    }, onError: (e) => debugPrint('[FCM] onTokenRefresh error: $e'));
  }

  Future<String?> _waitForApnsToken() async {
    if (!np.notificationPlatformIsIOS && !np.notificationPlatformIsMacOS) {
      return null;
    }
    for (var i = 0; i < 20; i++) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[FCM] APNs token ready (${token.substring(0, 10)}…).');
        return token;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  Future<void> unregisterFromBackend() async {
    await _refreshSub?.cancel();
    _refreshSub = null;

    try {
      var token = _lastRegisteredToken;
      token ??= await _resolveTokenForUnregister();
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

  Future<String?> _resolveTokenForUnregister() async {
    if (kIsWeb) {
      final vapidKey = AppEnv.firebaseVapidKey.trim();
      if (vapidKey.isEmpty) return null;
      return FirebaseMessaging.instance
          .getToken(vapidKey: vapidKey)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    }
    return FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    if (np.notificationPlatformIsAndroid) return 'android';
    if (np.notificationPlatformIsIOS) return 'ios';
    return 'android';
  }

  Future<String> _deviceId({bool webPrefix = false}) async {
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
      return webPrefix ? 'web-$id' : id;
    } catch (_) {
      return webPrefix ? 'web-unknown' : '';
    }
  }
}
