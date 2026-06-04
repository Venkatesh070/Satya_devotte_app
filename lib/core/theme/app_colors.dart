import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4E342E);
  static const Color secondary = Color(0xFF8D6E63);
  static const Color background = Color(0xFFFAF7F5);
  static const Color gradientStart = Color(0xFF1F4CB7);
  static const Color gradientEnd = Color(0xFFED5A00);
  static const Color inputBorderGradientStart = Color(0xFF183EA4);
  static const Color inputBorderGradientEnd = Color(0xFFE35600);
  static const Color inputBorderColor = Color(0xFFFCF7EF);
  static const LinearGradient inputBorderGradient = LinearGradient(
    colors: [inputBorderGradientStart, inputBorderGradientEnd],
  );
  static const Color chakraOverlayColor = Color(0xFFDB5F00);
  static const Color black = Color(0xFF1F1F1F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color appBgColor = Color(0xFFFAECD2);
  static const Color donationBgColor = Color(0xFFFAECD2);
  static const Color textColor = Color(0xFF4A1C00);

  // Background Gradient from image
  static const Color bgGradientTop = Color(0xFF000000);
  static const Color bgGradientMiddle = Color(0xFF4A1C00);
  static const Color bgGradientBottom = Color(0xFFED5A00);
}
