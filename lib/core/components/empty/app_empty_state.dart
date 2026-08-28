import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Widget Empty State modern dan informatif untuk memandu peternak
/// mengisi data ketika belum ada catatan atau data pada layar.
///
/// Gunakan [compact] = true jika empty state berada di dalam card atau Column
/// yang sudah memiliki padding tersendiri (contoh: section list atau tabel dashboard).
/// Gunakan [compact] = false (default) saat empty state mengisi seluruh layar.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget? resolvedAction = action;
    if (resolvedAction == null && actionLabel != null && onAction != null) {
      resolvedAction = FilledButton.icon(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 22,
            vertical: compact ? 10 : 12,
          ),
        ),
        onPressed: onAction,
        icon: Icon(actionIcon ?? Icons.add_rounded, size: compact ? 18 : 20),
        label: Text(
          actionLabel!,
          style: (compact ? tt.labelMedium : tt.labelLarge)?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Wadah Ikon Melingkar dengan aksen lembut
        Container(
          padding: EdgeInsets.all(compact ? 14 : 20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: compact ? 36 : 48,
            color: cs.primary,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),

        // Judul Pesan
        Text(
          message,
          style: (compact ? tt.titleSmall : tt.titleMedium)?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        // Subtitle / Panduan Aksi
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 320 : 420),
            child: Text(
              subtitle!,
              style: (compact ? tt.bodySmall : tt.bodyMedium)?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        // Tombol Aksi / Call-to-Action
        if (resolvedAction != null) ...[
          SizedBox(height: compact ? 16 : 20),
          resolvedAction,
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(child: content),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: content,
      ),
    );
  }
}
