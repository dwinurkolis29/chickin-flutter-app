import 'package:flutter/material.dart';

/// Brand color constants.
/// semantic colors (error, warning, info, success) are used directly
/// in components like AppSnackbar. All other colors flow through ColorScheme.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary        = Color(0xFF09637E);
  static const Color secondary      = Color(0xFF7AB2B2);
  static const Color background     = Color(0xFFEBF4F6);
  static const Color backgroundDark = Color(0xFF0F2027);

  // Semantic — gunakan di atas background TERANG (surface, white, #EBF4F6)
  static const Color error   = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);
  static const Color info    = Color(0xFF0277BD);
  static const Color success = Color(0xFF2E7D32);

  // Semantic ON PRIMARY — gunakan di atas hero card (#09637E)
  static const Color errorOnPrimary   = Color(0xFFFF8A80);
  static const Color warningOnPrimary = Color(0xFFFFD180);
  static const Color infoOnPrimary    = Color(0xFF80D8FF);
  static const Color successOnPrimary = Color(0xFFCCFF90);
}
