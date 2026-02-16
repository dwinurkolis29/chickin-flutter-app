import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// Error/Info dialog for displaying messages to the user
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool showIcon;
  final IconData? icon;
  final Color? iconColor;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.showIcon = false,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              icon ?? Icons.error_outline,
              size: 48,
              color: iconColor ?? Colors.red,
            ),
            const SizedBox(height: 16),
          ],
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Show error dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    bool showIcon = false,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        showIcon: showIcon,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}
