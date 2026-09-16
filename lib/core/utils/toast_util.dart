import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

class ToastUtil {
  static String _cleanMessage(String msg) {
    var cleaned = msg
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();
    return cleaned
        .replaceAll('"', '')
        .replaceAll('\u201C', '')
        .replaceAll('\u201D', '')
        .trim();
  }

  static void showSuccess(String message, {String title = 'Success'}) {
    final context = Get.context;
    if (context != null) {
      _showCustomToast(context, title, _cleanMessage(message), true);
    }
  }

  static void showError(String message, {String title = 'Error'}) {
    final context = Get.context;
    if (context != null) {
      var cleanTitle = title;
      final cleanMsg = _cleanMessage(message);
      if (cleanTitle == 'Error') {
        if (cleanMsg.toLowerCase().contains('out of stock')) {
          cleanTitle = 'Out of Stock';
        } else if (cleanMsg.toLowerCase().contains('stock') ||
            cleanMsg.toLowerCase().contains('inventory') ||
            cleanMsg.toLowerCase().contains('can be built')) {
          cleanTitle = 'Stock Limit';
        }
      }
      _showCustomToast(context, cleanTitle, cleanMsg, false);
    }
  }

  static void showInfo(String message, {String title = 'Info'}) {
    final context = Get.context;
    if (context != null) {
      _showCustomToast(context, title, _cleanMessage(message), true);
    }
  }

  static void show(String title, String message) {
    final context = Get.context;
    if (context != null) {
      _showCustomToast(context, title, _cleanMessage(message), true);
    }
  }

  static void _showCustomToast(
    BuildContext context,
    String title,
    String message,
    bool isSuccess,
  ) {
    final overlayState = Navigator.of(context, rootNavigator: true).overlay;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    late OverlayEntry overlayEntry;

    final double toastWidth = isTablet
        ? screenSize.width * 0.85
        : screenSize.width * 0.85;
    final double horizontalPadding = (screenSize.width - toastWidth) / 2;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: kIsWeb ? 10 : 30,
          left: horizontalPadding,
          right: horizontalPadding,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFFCF7EF),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border(
                  left: BorderSide(
                    color: isSuccess ? Colors.green : Colors.red,
                    width: 5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTypography.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlayState?.insert(overlayEntry);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        try {
          overlayEntry.remove();
        } catch (_) {}
      });
    });
  }
}
