import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      );
    return base.copyWith(textTheme: AppTypography.buildTextTheme(base.textTheme));
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(textTheme: AppTypography.buildTextTheme(base.textTheme));
  }
}
