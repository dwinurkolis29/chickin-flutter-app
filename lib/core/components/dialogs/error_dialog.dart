import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'base_dialog.dart';

/// Dialog Error, Peringatan, atau Informasi dengan styling konsisten Material 3.
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool showIcon;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String buttonText;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.showIcon = true,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.buttonText = 'Tutup',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultIcon = icon ?? Icons.error_outline_rounded;
    final defaultIconColor = iconColor ?? AppColors.error;
    final defaultIconBg = iconBackgroundColor ??
        (defaultIconColor == AppColors.error
            ? AppColors.error.withValues(alpha: 0.12)
            : cs.secondaryContainer);

    return BaseDialog(
      title: title,
      icon: showIcon ? defaultIcon : null,
      iconColor: showIcon ? defaultIconColor : null,
      iconBackgroundColor: showIcon ? defaultIconBg : null,
      content: Text(
        message,
        style: tt.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Menampilkan dialog error/info
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    bool showIcon = true,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    String buttonText = 'Tutup',
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        showIcon: showIcon,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        buttonText: buttonText,
      ),
    );
  }
}
