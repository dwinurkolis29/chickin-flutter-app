import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';
import '../transitions/slide_fade_transition_builder.dart';

const _pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: SlideFadeTransitionBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), // Menjaga swipe back iOS
    TargetPlatform.windows: SlideFadeTransitionBuilder(),
    TargetPlatform.macOS: SlideFadeTransitionBuilder(),
    TargetPlatform.linux: SlideFadeTransitionBuilder(),
  },
);

/// Single source of truth for ThemeData.
/// Use AppTheme.light() and AppTheme.dark() in MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2DFDF),
      onSecondaryContainer: AppColors.primary,
      surface: AppColors.background,
      error: AppColors.error,
    );
    return ThemeData.from(
      colorScheme: scheme,
      textTheme: AppTextTheme.textTheme,
      useMaterial3: true,
    ).copyWith(
      pageTransitionsTheme: _pageTransitionsTheme,
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: AppColors.secondary,
      error: AppColors.error,
      // background keeps M3 dark default — light background on dark is wrong
    );
    return ThemeData.from(
      colorScheme: scheme,
      textTheme: AppTextTheme.textTheme,
      useMaterial3: true,
    ).copyWith(
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }
}
