import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// Single source of truth for ThemeData.
/// Use AppTheme.light() and AppTheme.dark() in MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      secondary:        AppColors.secondary,
      surface:          AppColors.background,
      error:            AppColors.error,
    );
    return ThemeData.from(
      colorScheme: scheme,
      textTheme: AppTextTheme.textTheme,
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: AppColors.secondary,
      error:     AppColors.error,
      // background keeps M3 dark default — light background on dark is wrong
    );
    return ThemeData.from(
      colorScheme: scheme,
      textTheme: AppTextTheme.textTheme,
      useMaterial3: true,
    );
  }
}
