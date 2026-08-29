import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Menampilkan kesimpulan dan saran konkret untuk periode pemeliharaan berikutnya.
class InsightCard extends StatelessWidget {
  final List<String> insights;

  const InsightCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      color: cs.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kesimpulan & Saran Periode Berikutnya',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (insights.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Siklus pemeliharaan berjalan lancar. Pertahankan SOP pemberian pakan dan brooding pada periode selanjutnya.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              )
            else
              ...insights.map((text) => _InsightTile(text: text)),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String text;
  const _InsightTile({required this.text});

  static bool _isPositive(String text) {
    final lower = text.toLowerCase();
    return lower.contains('baik') ||
        lower.contains('optimal') ||
        lower.contains('rendah') ||
        lower.contains('istimewa') ||
        lower.contains('tercapai');
  }

  static bool _isWarning(String text) {
    final lower = text.toLowerCase();
    return lower.contains('tinggi') ||
        lower.contains('evaluasi') ||
        lower.contains('perlu') ||
        lower.contains('kurang') ||
        lower.contains('lambat');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isPos = _isPositive(text);
    final isWarn = _isWarning(text);

    final Color accentColor = isPos
        ? AppColors.success
        : (isWarn ? AppColors.warning : cs.primary);

    final IconData icon = isPos
        ? Icons.check_circle_rounded
        : (isWarn ? Icons.warning_amber_rounded : Icons.info_outline_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
