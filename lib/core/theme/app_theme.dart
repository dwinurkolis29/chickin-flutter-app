import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_theme_option.dart';
import 'app_typography.dart';

/// Custom horizontal-slide page transition.
///
/// On Web: slides without registering a swipe-back gesture detector
/// (avoids conflict with Safari's native back-swipe).
/// On native iOS/macOS: falls back to the standard Cupertino transition.
class _HorizontalSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _HorizontalSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut));

    return SlideTransition(
      position: slideOut,
      child: SlideTransition(position: slideIn, child: child),
    );
  }
}

/// Single source of truth for ThemeData.
///
/// Shape rule (sesuai design system):
///   pill (999dp) = tombol, chip, nav, search, input field
///   24dp         = card & container utama
///   16dp         = sheet row / list tile decoration
///   4dp          = snackbar only
///
/// The application currently runs with [AppThemeOption.dark].
class AppTheme {
  AppTheme._();

  static const double pillRadius     = 999.0;
  static const double cardRadius     = 24.0;
  static const double rowRadius      = 16.0;
  static const double snackbarRadius = 4.0;

  static ThemeData build(AppThemeOption option) {
    final isDark = option == AppThemeOption.dark;

    // ── Resolved surface tokens ──────────────────────────────────────────────
    final Color surface              = isDark ? AppColors.surfaceDark              : AppColors.surface;
    final Color surfaceContainer     = isDark ? AppColors.surfaceContainerDark     : AppColors.surfaceContainer;
    final Color surfaceContainerHigh = isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerHigh;
    final Color onSurface            = isDark ? AppColors.onSurfaceDark            : AppColors.onSurface;
    final Color onSurfaceVariant     = isDark ? AppColors.onSurfaceVariantDark     : AppColors.onSurfaceVariant;
    final Color outline              = isDark ? AppColors.outlineDark              : AppColors.outline;
    final Color outlineVariant       = isDark ? AppColors.outlineVariantDark       : AppColors.outlineVariant;
    final Color background           = isDark ? AppColors.backgroundDark           : AppColors.background;

    // ── Primary tokens ───────────────────────────────────────────────────────
    const Color primary = AppColors.primaryBlue;
    const Color onPrimary = AppColors.blueOnPrimary;

    // primary container: tinted version of primary untuk chip/badge selected state
    final Color primaryContainer = isDark
        ? AppColors.bluePrimaryContainerDark
        : AppColors.bluePrimaryContainer;
    final Color onPrimaryContainer = isDark
        ? AppColors.blueOnPrimaryContainerDark
        : AppColors.blueOnPrimaryContainer;
    final Color secondary =
        isDark ? AppColors.blueSecondaryDark : AppColors.blueSecondary;
    final Color onSecondary =
        isDark ? AppColors.blueOnSecondaryDark : AppColors.blueOnSecondary;

    // ── ColorScheme ──────────────────────────────────────────────────────────
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondary,
      onSecondaryContainer: onSecondary,
      tertiary: primary,
      error: AppColors.formError,
      onError: const Color(0xFFFFFFFF),
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      outline: outline,
      outlineVariant: outlineVariant,
      onSurfaceVariant: onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: AppTypography.textTheme(onSurface, onSurfaceVariant),

      // Flutter Web: force standard density agar button tidak flat/pendek.
      visualDensity: VisualDensity.standard,

      iconTheme: IconThemeData(color: onPrimaryContainer),

      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: kIsWeb
              ? const _HorizontalSlidePageTransitionsBuilder()
              : const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: kIsWeb
              ? const _HorizontalSlidePageTransitionsBuilder()
              : const CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: surface,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceContainer,
          foregroundColor: onSurface,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer.withValues(alpha: isDark ? 0.6 : 1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: const BorderSide(color: AppColors.formError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: const BorderSide(color: AppColors.formError, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: TextStyle(color: onSurfaceVariant),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: primaryContainer,
        shape: const StadiumBorder(),
        side: BorderSide(color: outline),
        labelStyle:
            AppTypography.textTheme(onSurface, onSurfaceVariant).labelSmall,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceContainerHigh,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onSurface,
        contentTextStyle: const TextStyle(color: AppColors.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(snackbarRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(color: outlineVariant, thickness: 1),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        tileColor: Colors.transparent,
        iconColor: onSurfaceVariant,
      ),
    );
  }
}
