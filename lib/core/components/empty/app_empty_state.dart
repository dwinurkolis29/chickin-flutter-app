import 'package:flutter/material.dart';

/// Widget empty state yang konsisten untuk semua list screen.
///
/// Gunakan [compact] = true jika empty state berada di dalam card atau Column
/// yang sudah punya padding sendiri (contoh: dalam widget list section).
/// Gunakan [compact] = false (default) saat empty state mengisi seluruh layar.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: cs.outlineVariant),
        const SizedBox(height: 12),
        Text(
          message,
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: tt.bodyMedium?.copyWith(color: cs.outlineVariant),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 20),
          action!,
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(child: content),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: content,
      ),
    );
  }
}
