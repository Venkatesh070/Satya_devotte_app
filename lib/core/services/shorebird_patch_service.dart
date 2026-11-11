import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:satya_devotte_app/shared/widgets/shorebird_patch_dialog.dart';

/// Downloads Shorebird patches with a branded UI, then asks the user to close
/// and reopen so the patch can load.
///
/// Uses only [shorebird_code_push] (Dart/FFI into the Shorebird engine already
/// in store builds) so this can ship as a Shorebird patch.
class ShorebirdPatchService {
  ShorebirdPatchService._();

  /// Temporary: force-show the Shorebird patch UI so you can review design.
  /// Keep `false` for production / Shorebird patches.
  static const bool previewUi = false;

  static const _prefsRestartedPatchKey = 'shorebird_last_restarted_patch';

  static final ShorebirdUpdater _updater = ShorebirdUpdater();
  static bool _inFlight = false;
  static bool _dialogOpen = false;
  static bool _awaitingUserRestart = false;
  static Timer? _autoCloseTimer;
  static final ValueNotifier<ShorebirdPatchDialogPhase> _phase =
      ValueNotifier(ShorebirdPatchDialogPhase.downloading);

  /// Checks for a patch, shows download UI, then ready + auto-close on iOS.
  static Future<void> checkDownloadAndRestartIfNeeded({
    bool force = false,
  }) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;

    // Same production UI path — preview only skips the real Shorebird engine.
    if (previewUi) {
      await showPreviewUi();
      return;
    }

    if (_inFlight) return;
    if (_awaitingUserRestart && _dialogOpen) return;
    if (!_updater.isAvailable) {
      debugPrint('[ShorebirdPatch] Updater unavailable in this build');
      return;
    }

    _inFlight = true;
    try {
      var status = await _updater.checkForUpdate();
      debugPrint('[ShorebirdPatch] status=$status');

      if (status == UpdateStatus.outdated) {
        _showDownloadingDialog();
        try {
          await _updater.update();
          status = UpdateStatus.restartRequired;
        } on UpdateException catch (e) {
          debugPrint('[ShorebirdPatch] update failed: $e');
          _dismissDialog();
          return;
        }
      }

      if (status != UpdateStatus.restartRequired) {
        _dismissDialog();
        return;
      }

      final current = (await _updater.readCurrentPatch())?.number ?? 0;
      final next = (await _updater.readNextPatch())?.number ?? 0;
      if (next == 0 || next == current) {
        _dismissDialog();
        _awaitingUserRestart = false;
        return;
      }

      _awaitingUserRestart = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefsRestartedPatchKey, next);
      } catch (_) {}
      await _showReadyDialogAndAutoClose();
    } catch (e, st) {
      debugPrint('[ShorebirdPatch] check failed: $e\n$st');
      _dismissDialog();
      _awaitingUserRestart = false;
    } finally {
      _inFlight = false;
    }
  }

  /// Same UI as a real patch: downloading → ready (dismissible) → auto-close.
  static Future<void> showPreviewUi() async {
    if (_dialogOpen || _inFlight) return;
    _inFlight = true;
    try {
      debugPrint('[ShorebirdPatch] Preview UI (production copy)');
      _showDownloadingDialog();
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!_dialogOpen) return;
      _awaitingUserRestart = true;
      await _showReadyDialogAndAutoClose();
    } finally {
      _inFlight = false;
    }
  }

  static Future<void> _closeAppToApply() async {
    _autoCloseTimer?.cancel();
    try {
      // Soft exit first (Android-friendly).
      await SystemNavigator.pop();
    } catch (e) {
      debugPrint('[ShorebirdPatch] SystemNavigator.pop failed: $e');
    }
    // iOS often ignores SystemNavigator.pop(); force-terminate so the next
    // cold start can load the downloaded Shorebird patch.
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      exit(0);
    } catch (e) {
      debugPrint('[ShorebirdPatch] exit(0) failed: $e');
    }
  }

  static void _showDownloadingDialog() {
    _autoCloseTimer?.cancel();
    _phase.value = ShorebirdPatchDialogPhase.downloading;

    if (_dialogOpen) return;

    _dialogOpen = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: ValueListenableBuilder<ShorebirdPatchDialogPhase>(
          valueListenable: _phase,
          builder: (context, currentPhase, _) {
            return ShorebirdPatchDialog(
              phase: currentPhase,
              onCloseAndApply: _closeAppToApply,
              onDismiss: currentPhase == ShorebirdPatchDialogPhase.ready
                  ? _dismissDialog
                  : null,
            );
          },
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      useSafeArea: true,
    ).whenComplete(() {
      _dialogOpen = false;
      _awaitingUserRestart = false;
      _autoCloseTimer?.cancel();
    });
  }

  /// After install: ready UI is dismissible, then auto-closes the app on iOS.
  static Future<void> _showReadyDialogAndAutoClose() async {
    _phase.value = ShorebirdPatchDialogPhase.ready;

    // Rebuild as a dismissible dialog so iOS users can tap outside / X / back.
    if (_dialogOpen || (Get.isDialogOpen ?? false)) {
      Get.back();
      _dialogOpen = false;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    _dialogOpen = true;
    unawaited(
      Get.dialog(
        PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              _autoCloseTimer?.cancel();
              _awaitingUserRestart = false;
            }
          },
          child: ShorebirdPatchDialog(
            phase: ShorebirdPatchDialogPhase.ready,
            onCloseAndApply: _closeAppToApply,
            onDismiss: _dismissDialog,
          ),
        ),
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        useSafeArea: true,
      ).whenComplete(() {
        _dialogOpen = false;
        _awaitingUserRestart = false;
        _autoCloseTimer?.cancel();
      }),
    );

    // Brief moment to read the ready state, then auto-close the app.
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(milliseconds: 1600), () {
      if (_dialogOpen) {
        unawaited(_closeAppToApply());
      }
    });
  }

  static void _dismissDialog() {
    _autoCloseTimer?.cancel();
    _awaitingUserRestart = false;
    if (_dialogOpen || (Get.isDialogOpen ?? false)) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      _dialogOpen = false;
    }
  }
}
