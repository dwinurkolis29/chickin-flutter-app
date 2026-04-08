import 'package:flutter/material.dart';

class TourTooltip extends StatelessWidget {
  final String title;
  final String description;
  final String stepText;
  final bool showSkip;
  final VoidCallback onSkip;
  
  /// Teks untuk tombol aksi utama (contoh: "Selesai" atau "Mengerti").
  /// Jika null, tombol ini tidak akan ditampilkan.
  final String? actionButtonText;
  
  /// Callback ketika tombol aksi utama ditekan.
  final VoidCallback? onAction;

  const TourTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.stepText,
    this.showSkip = false,
    required this.onSkip,
    this.actionButtonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 8,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stepText,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showSkip)
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Lewati',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (actionButtonText != null)
                  ElevatedButton(
                    onPressed: onAction ?? onSkip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(actionButtonText!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

