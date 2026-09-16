import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

class ScreenProtectionService extends GetxService {
  bool _isProtected = false;
  DateTime? _lastWarningTime;

  bool get isProtected => _isProtected;

  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      // Hardware-level prevent screenshots on Android (FLAG_SECURE) and iOS
      await ScreenProtector.preventScreenshotOn();

      // Protect recent apps preview (multitasking switcher)
      await ScreenProtector.protectDataLeakageWithColor(
        const Color(0xFF1E0B00),
      );

      // Listen for screenshot attempts (on iOS where system events fire)
      ScreenProtector.addListener(
        () {
          _showScreenshotWarning(
            title: 'Screenshots Restricted',
            message:
                'Screenshots are disabled to protect devotional content and privacy.',
          );
        },
        (isCaptured) {
          if (isCaptured) {
            _showScreenshotWarning(
              title: 'Screen Recording Restricted',
              message: 'Screen recording is disabled while using this app.',
            );
          }
        },
      );

      _isProtected = true;
      debugPrint('[ScreenProtectionService] Screenshot protection enabled.');
    } catch (e) {
      debugPrint('[ScreenProtectionService] Failed to enable protection: $e');
    }
  }

  void _showScreenshotWarning({
    required String title,
    required String message,
  }) {
    final now = DateTime.now();
    // Debounce alerts within 2 seconds
    if (_lastWarningTime != null &&
        now.difference(_lastWarningTime!).inMilliseconds < 2000) {
      return;
    }
    _lastWarningTime = now;

    if (Get.context == null) return;

    Get.snackbar(
      title,
      message,
      titleText: Text(
        title,
        style: AppTypography.lora(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFD180),
        ),
      ),
      messageText: Text(
        message,
        style: AppTypography.inter(
          fontSize: 13,
          color: const Color(0xFFFCF7EF),
        ),
      ),
      icon: const Icon(
        Icons.shield_outlined,
        color: Color(0xFFFFD180),
        size: 24,
      ),
      backgroundColor: const Color(0xFF2A1102).withValues(alpha: 0.95),
      colorText: const Color(0xFFFCF7EF),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      borderColor: const Color(0xFFFFD180).withValues(alpha: 0.3),
      borderWidth: 1,
    );
  }

  @override
  void onClose() {
    if (!kIsWeb) {
      try {
        ScreenProtector.removeListener();
      } catch (_) {}
    }
    super.onClose();
  }
}
