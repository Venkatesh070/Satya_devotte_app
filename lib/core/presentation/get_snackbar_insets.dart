import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// GetX snackbars stretch to the full viewport width on web. This helper
/// supplies a max width and asymmetric margins so the bar sits in the
/// top-right (GetX top snackbars align from the start edge).
class GetSnackbarInsets {
  const GetSnackbarInsets({this.maxWidth, required this.margin});

  final double? maxWidth;
  final EdgeInsets margin;

  /// Web: capped width with a trailing-side bias. Other platforms: small
  /// uniform margin; width follows content/parent.
  factory GetSnackbarInsets.platformDefault() {
    const maxToastWidth = 400.0;
    const horizontalPad = 16.0;
    if (!kIsWeb) {
      return const GetSnackbarInsets(
        maxWidth: null,
        margin: EdgeInsets.all(12),
      );
    }
    final w = Get.width;
    final leftGap =
        (w - maxToastWidth - horizontalPad * 2).clamp(0.0, double.infinity);
    return GetSnackbarInsets(
      maxWidth: maxToastWidth,
      margin: EdgeInsets.only(
        top: 12,
        right: horizontalPad,
        bottom: 8,
        left: leftGap > 0 ? leftGap : horizontalPad,
      ),
    );
  }
}

void showAppSnackbar({
  required String title,
  required String message,
  bool isError = false,
}) {
  final inset = GetSnackbarInsets.platformDefault();

  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    maxWidth: inset.maxWidth,
    backgroundColor: isError
        ? const Color(0xFFF44336)
        : const Color(0xFF4CAF50),
    colorText: Colors.white,
    margin: inset.margin,
    borderRadius: 10,
    icon: Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      color: Colors.white,
    ),
    duration: const Duration(seconds: 3),
    boxShadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
