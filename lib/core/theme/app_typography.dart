import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide typography using Plus Jakarta Sans.
///
/// Accepts dynamic [onSurface] and [onSurfaceVariant] so colors adapt
/// correctly to both light and dark ColorScheme — no hardcoded hex here.
///
/// Scale:
///   displayLarge  (32sp, w800) — angka besar: populasi, FCR value
///   titleLarge    (20sp, w600) — judul layar
///   titleMedium   (18sp, w600) — judul section / card header
///   titleSmall    (16sp, w500) — sub-judul
///   bodyLarge     (16sp, w400) — konten utama
///   bodyMedium    (14sp, w400) — konten umum
///   bodySmall     (12sp, w400) — caption / helper text
///   labelLarge    (14sp, w700) — tombol / label penting
///   labelMedium   (12sp, w700) — badge / label kecil
///   labelSmall    (10sp, w500) — chip / tag
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    return GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: onSurface,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: onSurface,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
      ),
    );
  }
}
