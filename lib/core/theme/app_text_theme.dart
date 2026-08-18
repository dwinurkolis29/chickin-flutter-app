// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';

/// @deprecated Gunakan [AppTypography] sebagai pengganti.
///
/// File ini dipertahankan agar tidak ada breaking change selama transisi.
/// Referensi lama di [AppTheme] sudah dipindah ke [AppTypography].
/// Hapus file ini setelah semua referensi [AppTextTheme] di-update.
@Deprecated('Gunakan AppTypography dari app_typography.dart')
class AppTextTheme {
  AppTextTheme._();

  @Deprecated('Gunakan AppTypography.textTheme(onSurface, onSurfaceVariant)')
  static TextTheme get textTheme => const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(fontSize: 10),
      );
}
