import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Standard card surface for Chickin.
///
/// App cards use the surface color, the shared card radius, and no elevation.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: padding == null
          ? child
          : Padding(
              padding: padding!,
              child: child,
            ),
    );

    return card;
  }
}
