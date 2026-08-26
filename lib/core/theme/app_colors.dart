import 'package:flutter/material.dart';

/// Design tokens for the single Blue palette.
///
/// Screens must use ColorScheme roles instead of declaring colors locally.
class AppColors {
  AppColors._();

  // ── Light neutral tokens ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF5FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFEAF3F7);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF526B78);
  static const Color outline = Color(0xFF7899A8);
  static const Color outlineVariant = Color(0xFFD5E4EA);

  // ── Dark neutral tokens ───────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF101010);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceContainerDark = Color(0xFF2B2B2B);
  static const Color surfaceContainerHighDark = Color(0xFF383838);
  static const Color onSurfaceDark = Color(0xFFE2E2E2);
  static const Color onSurfaceVariantDark = Color(0xFFABABAB);
  static const Color outlineDark = Color(0xFF757575);
  static const Color outlineVariantDark = Color(0xFF474747);

  // ── Blue palette ───────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1B4965);
  static const Color primary = primaryBlue;
  static const Color blueOnPrimary = Color(0xFFFFFFFF);
  static const Color bluePrimaryContainer = Color(0xFFDCEAF2);
  static const Color blueOnPrimaryContainer = Color(0xFF123B50);
  static const Color blueSecondary = Color(0xFFEAF3F7);
  static const Color blueOnSecondary = Color(0xFF1B4965);
  static const Color blueSecondaryContainer = blueSecondary;
  static const Color blueOnSecondaryContainer = blueOnSecondary;

  // Dark theme counterparts from the same Blue palette.
  static const Color bluePrimaryContainerDark = Color(0xFF2B5D77);
  static const Color blueOnPrimaryContainerDark = Color(0xFFDCEAF2);
  static const Color blueSecondaryDark = Color(0xFF23485E);
  static const Color blueOnSecondaryDark = Color(0xFFDCEAF2);

  // ── Semantic status colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color formError = error;

  // ── FCR domain status colors ──────────────────────────────────────────────
  static const Color fcrGoodBg = Color(0xFFEAF3DE);
  static const Color fcrGoodText = Color(0xFF27500A);
  static const Color fcrGoodBorder = Color(0xFF639922);
  static const Color fcrWarnBg = Color(0xFFFAEEDA);
  static const Color fcrWarnText = Color(0xFF633806);
  static const Color fcrWarnBorder = Color(0xFFBA7517);
  static const Color fcrBadBg = Color(0xFFFCEBEB);
  static const Color fcrBadText = Color(0xFF791F1F);
  static const Color fcrBadBorder = Color(0xFFE24B4A);
}
