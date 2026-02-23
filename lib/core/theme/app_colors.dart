import 'package:flutter/material.dart';

/// Brand color constants.
/// semantic colors (error, warning, info, success) are used directly
/// in components like AppSnackbar. All other colors flow through ColorScheme.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary    = Color(0xFF09637E);
  static const Color secondary  = Color(0xFF7AB2B2);
  static const Color background = Color(0xFFEBF4F6);

  // Semantic
  static const Color error   = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFC107);
  static const Color info    = Color(0xFF2196F3);
  static const Color success = Color(0xFF4CAF50);
}
