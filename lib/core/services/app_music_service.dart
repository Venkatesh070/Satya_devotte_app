import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:satya_devotte_app/config/routes/app_routes.dart';

/// Loops [assetPath] across the mobile app and web CMS admin.
class AppMusicService extends GetxService with WidgetsBindingObserver {
  static const String assetPath = 'assets/audios/SatyaAppMusic.mp3';

  final AudioPlayer _player = AudioPlayer();
  bool _prepared = false;
  bool _userPaused = false;
  bool _cmsMusicSuppressed = false;

  final RxBool isPlaying = false.obs;
  final RxBool showFab = false.obs;

  static const Set<String> _fabHiddenRoutes = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.createAccount,
    AppRoutes.poojaKitCart,
    AppRoutes.poojaKitCheckout,
  };

  /// Unnamed `Get.to(() => CreateAccountPage())` routes in GetX.
  static bool _isCreateAccountRoute(String route) =>
      route.contains('CreateAccount');

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
    syncControlsVisibility();
  }

  static bool isCmsRoute(String route) =>
      route == AppRoutes.cms || route.startsWith('${AppRoutes.cms}/');

  /// Updates mobile FAB visibility and web CMS auto-play/stop by route.
  void syncControlsVisibility([String? route]) {
    final current = route ?? Get.currentRoute;
    showFab.value =
        !kIsWeb &&
        !_fabHiddenRoutes.contains(current) &&
        !_isCreateAccountRoute(current) &&
        !isCmsRoute(current);

    if (isCmsRoute(current) && !_cmsMusicSuppressed) {
      unawaited(start());
    } else if (kIsWeb) {
      unawaited(pause());
    }
  }

  /// Call while [CreateAccountPage] is visible (unnamed route).
  void suppressFloatingControl() => showFab.value = false;

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_player.dispose());
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_userPaused) return;
    if (state == AppLifecycleState.resumed) {
      final route = Get.currentRoute;
      if ((!kIsWeb || (isCmsRoute(route) && !_cmsMusicSuppressed))) {
        unawaited(start());
      }
    }
  }

  Future<void> _prepare() async {
    if (_prepared) return;
    await _player.setAsset(assetPath);
    await _player.setLoopMode(LoopMode.one);
    _prepared = true;
  }

  /// Starts or resumes background music (idempotent).
  Future<void> start() async {
    if (_userPaused) return;
    try {
      await _prepare();
      if (!_player.playing) {
        await _player.play();
      }
    } catch (e, st) {
      debugPrint('[AppMusicService] start failed: $e\n$st');
    }
  }

  /// Default play when an admin enters CMS (login or shell mount).
  Future<void> startOnAdminLogin() async {
    _cmsMusicSuppressed = false;
    _userPaused = false;
    await start();
    if (kIsWeb) {
      syncControlsVisibility(AppRoutes.cms);
    }
  }

  /// Stops CMS background music on admin logout (login page must stay silent).
  Future<void> stopOnAdminLogout() async {
    _cmsMusicSuppressed = true;
    _userPaused = false;
    try {
      if (_player.playing) {
        await _player.pause();
      }
    } catch (e, st) {
      debugPrint('[AppMusicService] stopOnAdminLogout failed: $e\n$st');
    }
    if (kIsWeb) {
      syncControlsVisibility(AppRoutes.login);
    }
  }

  Future<void> pause() async {
    if (!_player.playing) return;
    await _player.pause();
  }

  Future<void> toggle() async {
    try {
      await _prepare();
      if (_player.playing) {
        _userPaused = true;
        await _player.pause();
      } else {
        _userPaused = false;
        await _player.play();
      }
    } catch (e, st) {
      debugPrint('[AppMusicService] toggle failed: $e\n$st');
    }
  }
}

