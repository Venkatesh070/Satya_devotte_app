import 'package:flutter/material.dart';
import 'package:satya_devotte_app/core/theme/app_colors.dart';
import 'package:satya_devotte_app/core/theme/app_typography.dart';
import 'package:satya_devotte_app/shared/widgets/gradient_outline_input_border.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
    );
    return base.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
        focusedBorder: GradientOutlineInputBorder(
          gradient: AppColors.inputBorderGradient,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(width: 1.5),
        ),
      ),
      textTheme: AppTypography.buildTextTheme(base.textTheme),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.inputBorderColor),
        ),
        focusedBorder: GradientOutlineInputBorder(
          gradient: AppColors.inputBorderGradient,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(width: 1.5),
        ),
      ),
      textTheme: AppTypography.buildTextTheme(base.textTheme),
    );
  }
}
