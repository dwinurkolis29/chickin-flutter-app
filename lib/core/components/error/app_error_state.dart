import 'package:flutter/material.dart';

/// A consistent, beautifully designed error state widget for the application.
///
/// Can be used as a full-screen layout or compact section.
/// Supports customization of the icon, error title, message, and customizable retry/actions.
class AppErrorState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;
  final Widget? action;
  final bool compact;

  const AppErrorState({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.message,
    this.subtitle,
    this.onRetry,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: compact ? 48 : 64,
          color: cs.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: (compact ? tt.titleMedium : tt.titleLarge)?.copyWith(
            color: cs.error,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (onRetry != null || action != null) ...[
          const SizedBox(height: 24),
          if (action != null)
            action!
          else if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: content,
      ),
    );
  }
}
