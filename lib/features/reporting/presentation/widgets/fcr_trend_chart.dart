import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

/// Menampilkan tren FCR per minggu sebagai list visual.
/// Setiap row menunjukkan angka FCR dan arah tren (naik/turun/sama).
///
/// Tidak pakai chart library — list sederhana lebih readable untuk data kecil.
class FCRTrendChart extends StatelessWidget {
  final List<WeeklyFCR> weeklyFCR;

  const FCRTrendChart({super.key, required this.weeklyFCR});

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
            // Header
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Tren FCR Mingguan',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'FCR ideal: di bawah 1.8 — semakin rendah semakin efisien',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            if (weeklyFCR.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Data tren FCR belum tersedia',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
              // Bar track background
              ...weeklyFCR.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final prev = idx > 0 ? weeklyFCR[idx - 1].fcr : null;
                return _FCRWeekRow(
                  week: item.week,
                  fcr: item.fcr,
                  previousFcr: prev,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _FCRWeekRow extends StatelessWidget {
  final int week;
  final double fcr;
  final double? previousFcr;

  const _FCRWeekRow({
    required this.week,
    required this.fcr,
    this.previousFcr,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Status warna berdasarkan nilai FCR
    final Color barColor;
    if (fcr <= 1.8) {
      barColor = AppColors.success;
    } else if (fcr <= 2.2) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.error;
    }

    // Tren arah vs minggu sebelumnya
    Widget trendIcon = const SizedBox.shrink();
    if (previousFcr != null) {
      if (fcr < previousFcr! - 0.05) {
        trendIcon = Icon(Icons.trending_down_rounded, size: 16, color: AppColors.success);
      } else if (fcr > previousFcr! + 0.05) {
        trendIcon = Icon(Icons.trending_up_rounded, size: 16, color: AppColors.error);
      } else {
        trendIcon = Icon(Icons.trending_flat_rounded, size: 16, color: AppColors.warning);
      }
    }

    // Bar fill ratio — FCR 0–4 as reference scale
    final double barFraction = (fcr / 4.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  'Minggu $week',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Background track
                      Container(
                        height: 8,
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                      // Fill
                      FractionallySizedBox(
                        widthFactor: barFraction,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  fcr.toStringAsFixed(2),
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(width: 20, child: trendIcon),
            ],
          ),
        ],
      ),
    );
  }
}
