import 'package:flutter/material.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Komponen reusable Bottom Sheet untuk form interaktif pop-up di seluruh aplikasi.
/// Menerapkan standar visual Chickin: Drag handle, Header Icon Bulat, Judul,
/// Subtitle deskriptif, dan penanganan tinggi keyboard virtual otomatis.
class AppFormBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? titleColor;
  final Widget content;

  const AppFormBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleColor,
    required this.content,
  });

  /// Helper statis untuk menampilkan AppFormBottomSheet secara konsisten.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    Color? titleColor,
    bool isDismissible = true,
    required Widget Function(BuildContext context, StateSetter setModalState)
        builder,
  }) {
    return DialogHelper.showBottomSheet<T>(
      context,
      isDismissible: isDismissible,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final cs = Theme.of(sheetContext).colorScheme;
          final tt = Theme.of(sheetContext).textTheme;
          final paddingBottom =
              MediaQuery.of(sheetContext).viewInsets.bottom + 24;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: paddingBottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Drag Handle Bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // 2. Header Row (Icon + Title)
                    Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconBackgroundColor ??
                                  cs.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: iconColor ?? cs.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: titleColor ?? cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 3. Subtitle / Deskripsi Bantuan
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.only(
                          left: icon != null ? 42.0 : 0.0,
                        ),
                        child: Text(
                          subtitle,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 4. Form / Content Body
                    builder(sheetContext, setModalState),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: titleColor ?? cs.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: icon != null ? 42.0 : 0.0),
            child: Text(
              subtitle!,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        content,
      ],
    );
  }
}
