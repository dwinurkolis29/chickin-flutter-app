import 'package:flutter/material.dart';

/// App-wide text scale definitions.
/// No color hardcoded here — colors are inherited from the active ColorScheme.
class AppTextTheme {
  AppTextTheme._();

  static TextTheme get textTheme => const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(fontSize: 10),
      );
}
