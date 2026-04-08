import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      );
    final interText = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: interText.copyWith(
        displayLarge: GoogleFonts.lora(textStyle: interText.displayLarge),
        displayMedium: GoogleFonts.lora(textStyle: interText.displayMedium),
        displaySmall: GoogleFonts.lora(textStyle: interText.displaySmall),
        headlineLarge: GoogleFonts.lora(textStyle: interText.headlineLarge),
        headlineMedium: GoogleFonts.lora(textStyle: interText.headlineMedium),
        headlineSmall: GoogleFonts.lora(textStyle: interText.headlineSmall),
        titleLarge: GoogleFonts.lora(textStyle: interText.titleLarge),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final interText = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: interText.copyWith(
        displayLarge: GoogleFonts.lora(textStyle: interText.displayLarge),
        displayMedium: GoogleFonts.lora(textStyle: interText.displayMedium),
        displaySmall: GoogleFonts.lora(textStyle: interText.displaySmall),
        headlineLarge: GoogleFonts.lora(textStyle: interText.headlineLarge),
        headlineMedium: GoogleFonts.lora(textStyle: interText.headlineMedium),
        headlineSmall: GoogleFonts.lora(textStyle: interText.headlineSmall),
        titleLarge: GoogleFonts.lora(textStyle: interText.titleLarge),
      ),
    );
  }
}
