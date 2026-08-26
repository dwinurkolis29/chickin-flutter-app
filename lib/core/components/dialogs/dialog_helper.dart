import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'confirm_dialog.dart';
import 'error_dialog.dart';
import 'period_picker_dialog.dart';
import 'string_picker_dialog.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

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
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
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

  /// Show period picker dialog
  static Future<void> showPeriodPicker(
    BuildContext context, {
    required List<PeriodData> periods,
    required String? selectedPeriodId,
    required void Function(String) onSelected,
  }) {
    return PeriodPickerDialog.show(
      context: context,
      periods: periods,
      selectedPeriodId: selectedPeriodId,
      onSelected: onSelected,
    );
  }

  /// Show string options picker dialog
  static Future<void> showStringPicker(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? selectedOption,
    required void Function(String) onSelected,
  }) {
    return StringPickerDialog.show(
      context: context,
      title: title,
      options: options,
      selectedOption: selectedOption,
      onSelected: onSelected,
    );
  }

  /// Show modal bottom sheet wrapper
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      builder: (_) => builder,
    );
  }

  /// Show custom dialog wrapper
  static Future<T?> showCustomDialog<T>(
    BuildContext context, {
    required Widget builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => builder,
    );
  }
}
