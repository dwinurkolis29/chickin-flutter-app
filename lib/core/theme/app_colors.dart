import 'package:flutter/material.dart';

/// Brand color constants for Chickin (BroilerKu).
///
/// Rules (dari flutter-design skill):
/// - DILARANG menulis `Color(0xFF...)` baru langsung di widget/screen.
/// - Selalu referensikan via `AppColors.*` atau `Theme.of(context).colorScheme.*`.
/// - Gunakan `colorScheme.*` di widget agar light/dark otomatis switch.
/// - Warna semantic (error, warning, success) hanya untuk status/badge — bukan elemen struktural.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  /// Vivid Blue — satu-satunya brand color. Dipakai untuk CTA, icon aktif,
  /// badge, progress indicator, tombol utama.
  static const Color primary = Color(0xFF4B92DB);

  // ── Light Mode Surface Tokens ─────────────────────────────────────────────
  /// Scaffold background — putih dengan blue tint ringan.
  static const Color background           = Color(0xFFEEF2FF);
  /// Card / dialog / sheet surface utama.
  static const Color surface              = Color(0xFFFFFFFF);
  /// Default card background, input fill.
  static const Color surfaceContainer     = Color(0xFFF5F7FF);
  /// Elevated card / bottom sheet.
  static const Color surfaceContainerHigh = Color(0xFFEBF0FF);
  /// Teks utama (dark navy, bukan hitam murni).
  static const Color onSurface           = Color(0xFF0A1128);
  /// Teks muted / label / hint.
  static const Color onSurfaceVariant    = Color(0xFF5A6680);
  /// Border aktif / input border.
  static const Color outline             = Color(0xFFCDD5EE);
  /// Divider tipis / border pasif.
  static const Color outlineVariant      = Color(0xFFE8ECFB);

  // ── Dark Mode Surface Tokens ──────────────────────────────────────────────
  static const Color backgroundDark           = Color(0xFF0C1229);
  static const Color surfaceDark              = Color(0xFF111827);
  static const Color surfaceContainerDark     = Color(0xFF1A2340);
  static const Color surfaceContainerHighDark = Color(0xFF222D4A);
  static const Color onSurfaceDark            = Color(0xFFDDE3FF);
  static const Color onSurfaceVariantDark     = Color(0xFF8090B5);
  static const Color outlineDark              = Color(0xFF2E3D66);
  static const Color outlineVariantDark       = Color(0xFF1E2A4A);

  // ── Semantic Status Colors ────────────────────────────────────────────────
  /// Gunakan hanya di status badge, snackbar, dan teks status.
  /// Jangan gunakan sebagai warna struktural / background lebar.
  static const Color success  = Color(0xFF22C55E);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = Color(0xFFEF4444);

  /// Alias untuk InputDecorationTheme.errorBorder.
  static const Color formError = error;

  // ── FCR Domain Status Colors ──────────────────────────────────────────────
  /// Warna khusus domain FCR (Feed Conversion Ratio).
  /// Hanya dipakai di komponen FCR badge / card.
  static const Color fcrGoodBg     = Color(0xFFEAF3DE);
  static const Color fcrGoodText   = Color(0xFF27500A);
  static const Color fcrGoodBorder = Color(0xFF639922);

  static const Color fcrWarnBg     = Color(0xFFFAEEDA);
  static const Color fcrWarnText   = Color(0xFF633806);
  static const Color fcrWarnBorder = Color(0xFFBA7517);

  static const Color fcrBadBg      = Color(0xFFFCEBEB);
  static const Color fcrBadText    = Color(0xFF791F1F);
  static const Color fcrBadBorder  = Color(0xFFE24B4A);
}
