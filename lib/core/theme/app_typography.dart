import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  const AppTypography._();

  /// Inter is the default app font. Lora is used for display/title styles.
  static TextTheme buildTextTheme(TextTheme base) {
    final interText = GoogleFonts.interTextTheme(base);
    return interText.copyWith(
      displayLarge: GoogleFonts.lora(textStyle: interText.displayLarge),
      displayMedium: GoogleFonts.lora(textStyle: interText.displayMedium),
      displaySmall: GoogleFonts.lora(textStyle: interText.displaySmall),
      headlineLarge: GoogleFonts.lora(textStyle: interText.headlineLarge),
      headlineMedium: GoogleFonts.lora(textStyle: interText.headlineMedium),
      headlineSmall: GoogleFonts.lora(textStyle: interText.headlineSmall),
      titleLarge: GoogleFonts.lora(textStyle: interText.titleLarge),
    );
  }

  /// Use these helpers for explicit one-off styling in widgets.
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }

  static TextStyle lora({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }
}
