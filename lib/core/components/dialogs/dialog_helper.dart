import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'base_dialog.dart';
import 'confirm_dialog.dart';
import 'error_dialog.dart';
import 'period_picker_dialog.dart';
import 'string_picker_dialog.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/widgets/close_period_harvest_dialog.dart';

/// Helper terpusat untuk menampilkan dialog dan modal dengan standar visual aplikasi.
class DialogHelper {
  /// Menampilkan dialog Error
  static Future<void> showError(
    BuildContext context,
    String title,
    String message, {
    bool showIcon = true,
    String buttonText = 'Tutup',
  }) {
    return ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      showIcon: showIcon,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      buttonText: buttonText,
    );
  }

  /// Menampilkan dialog Informasi
  static Future<void> showInfo(
    BuildContext context,
    String title,
    String message, {
    bool showIcon = true,
    String buttonText = 'Tutup',
  }) {
    final cs = Theme.of(context).colorScheme;
    return ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      showIcon: showIcon,
      icon: Icons.info_outline_rounded,
      iconColor: cs.primary,
      iconBackgroundColor: cs.secondaryContainer,
      buttonText: buttonText,
    );
  }

  /// Menampilkan dialog Sukses
  static Future<void> showSuccess(
    BuildContext context,
    String title,
    String message, {
    String buttonText = 'Selesai',
  }) {
    return ErrorDialog.show(
      context: context,
      title: title,
      message: message,
      showIcon: true,
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
      iconBackgroundColor: AppColors.success.withValues(alpha: 0.12),
      buttonText: buttonText,
    );
  }

  /// Menampilkan dialog Konfirmasi tindakan
  static Future<bool?> showConfirm(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    VoidCallback? onConfirm,
  }) {
    return ConfirmDialog.show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      onConfirm: onConfirm,
    );
  }

  /// Menampilkan dialog picker Periode
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

  /// Menampilkan dialog picker Opsi String
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

  /// Menampilkan dialog interaktif Tutup Panen Periode
  static Future<ClosePeriodHarvestResult?> showClosePeriodHarvest(
    BuildContext context,
    PeriodData period,
  ) {
    return ClosePeriodHarvestDialog.show(
      context: context,
      period: period,
    );
  }

  /// Menampilkan dialog Tentang Aplikasi
  static Future<void> showAbout(
    BuildContext context, {
    String appName = 'Chickin BroilerKu',
    String version = 'Versi 1.0.0 • Production Ready',
    String description =
        'Aplikasi Manajemen Peternakan Ayam Broiler untuk pencatatan harian, perhitungan FCR otomatis, grafik pertumbuhan bobot, dan analisis performa.',
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return BaseDialog.show<void>(
      context: context,
      title: appName,
      icon: Icons.egg_outlined,
      iconColor: cs.primary,
      iconBackgroundColor: cs.secondaryContainer,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  version,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  /// Menampilkan Modal Bottom Sheet
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool isDismissible = true,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor,
      shape: shape ??
          const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
          ),
      builder: (_) => builder,
    );
  }

  /// Menampilkan Custom Dialog
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
