import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';

/// Menampilkan daftar insight sebagai bullet list dengan icon.
/// Insight dihasilkan oleh InsightGenerator saat periode ditutup.
class InsightCard extends StatelessWidget {
  final List<String> insights;

  const InsightCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Insight',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              Text(
                'Tidak ada insight tersedia untuk periode ini.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              )
            else
              ...insights.map((text) => _InsightRow(text: text)),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String text;
  const _InsightRow({required this.text});

  static IconData _iconFor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('baik') || lower.contains('optimal') || lower.contains('rendah')) {
      return Icons.check_circle_outline_rounded;
    }
    if (lower.contains('tinggi') || lower.contains('evaluasi') || lower.contains('perlu')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.info_outline_rounded;
  }

  static Color _colorFor(BuildContext context, String text) {
    final lower = text.toLowerCase();
    if (lower.contains('baik') || lower.contains('optimal') || lower.contains('rendah')) {
      return AppColors.success;
    }
    if (lower.contains('tinggi') || lower.contains('evaluasi') || lower.contains('perlu')) {
      return AppColors.warning;
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = _colorFor(context, text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(text), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: tt.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
