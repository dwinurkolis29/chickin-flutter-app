import 'package:flutter/material.dart';
import 'confirm_dialog.dart';
import 'error_dialog.dart';

/// Helper class for showing common dialogs with one-liner API
class DialogHelper {
  /// Show error dialog
  static Future<void> showError(
    BuildContext context,
    String title,
    String message, {
    bool showIcon = false,
  }) {
    return ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      showIcon: showIcon,
    );
  }

  /// Show info dialog (same as error but with info icon)
  static Future<void> showInfo(
    BuildContext context,
    String title,
    String message, {
    bool showIcon = true,
  }) {
    return ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      showIcon: showIcon,
      icon: Icons.info_outline,
      iconColor: Colors.blue,
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirm(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    VoidCallback? onConfirm,
  }) {
    return ConfirmDialog.show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      onConfirm: onConfirm,
    );
  }
}
