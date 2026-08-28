import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'base_dialog.dart';

/// Dialog konfirmasi tindakan pengguna dengan styling konsisten Material 3.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Konfirmasi',
    this.cancelText = 'Batal',
    this.isDestructive = false,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final defaultIcon = isDestructive
        ? Icons.warning_amber_rounded
        : Icons.help_outline_rounded;
    final defaultIconColor = isDestructive ? AppColors.error : cs.primary;
    final defaultIconBg = isDestructive
        ? AppColors.error.withValues(alpha: 0.12)
        : cs.secondaryContainer;

    return BaseDialog(
      title: title,
      icon: icon ?? defaultIcon,
      iconColor: iconColor ?? defaultIconColor,
      iconBackgroundColor: iconBackgroundColor ?? defaultIconBg,
      content: Text(
        message,
        style: tt.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.error : cs.primary,
            foregroundColor: isDestructive ? Colors.white : cs.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Membuka dialog konfirmasi dan mengembalikan true jika dikonfirmasi.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        onConfirm: onConfirm,
      ),
    );
  }
}
