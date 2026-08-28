import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Base dialog widget dengan styling konsisten di seluruh aplikasi (Material 3 & Card Radius).
class BaseDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget content;
  final List<Widget>? actions;
  final bool barrierDismissible;

  const BaseDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.content,
    this.actions,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget? headerTitle;
    if (titleWidget != null) {
      headerTitle = titleWidget;
    } else if (title != null) {
      if (icon != null) {
        headerTitle = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? cs.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Icon(
                icon,
                color: iconColor ?? cs.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title!,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        );
      } else {
        headerTitle = Text(
          title!,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        );
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      title: headerTitle,
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    );
  }

  /// Helper untuk memunculkan dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => BaseDialog(
        title: title,
        titleWidget: titleWidget,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        content: content,
        actions: actions,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}
