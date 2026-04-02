import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';

/// Evaluasi status berdasarkan FCR dan survival rate.
enum PeriodStatus { good, warning, bad }

class PeriodEvaluator {
  static PeriodStatus evaluate({required double fcr, required double survivalRate}) {
    if (fcr <= 0) return PeriodStatus.warning;
    if (fcr <= 1.8 && survivalRate >= 95) return PeriodStatus.good;
    if (fcr >= 2.2 || survivalRate < 90) return PeriodStatus.bad;
    return PeriodStatus.warning;
  }

  static Color statusColor(PeriodStatus status) {
    switch (status) {
      case PeriodStatus.good: return AppColors.success;
      case PeriodStatus.warning: return AppColors.warning;
      case PeriodStatus.bad: return AppColors.error;
    }
  }

  static String statusLabel(PeriodStatus status) {
    switch (status) {
      case PeriodStatus.good: return 'Baik';
      case PeriodStatus.warning: return 'Cukup';
      case PeriodStatus.bad: return 'Perlu Evaluasi';
    }
  }

  static IconData statusIcon(PeriodStatus status) {
    switch (status) {
      case PeriodStatus.good: return Icons.check_circle_rounded;
      case PeriodStatus.warning: return Icons.warning_amber_rounded;
      case PeriodStatus.bad: return Icons.cancel_rounded;
    }
  }
}

/// Hero card yang langsung menjawab "Periode ini bagus atau tidak?".
/// Menampilkan FCR, Survival Rate, dan Bobot Rata-rata dengan warna status.
class ReportSummaryHeader extends StatelessWidget {
  final String periodName;
  final String dateRange;
  final int durationDays;
  final double fcr;
  final double survivalRate;
  final int finalAvgWeightGram;

  const ReportSummaryHeader({
    super.key,
    required this.periodName,
    required this.dateRange,
    required this.durationDays,
    required this.fcr,
    required this.survivalRate,
    required this.finalAvgWeightGram,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = PeriodEvaluator.evaluate(fcr: fcr, survivalRate: survivalRate);
    final color = PeriodEvaluator.statusColor(status);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period name + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodName,
                        style: tt.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateRange • $durationDays Hari',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    border: Border.all(color: color, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PeriodEvaluator.statusIcon(status), size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        PeriodEvaluator.statusLabel(status),
                        style: tt.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 20),
            // Key 3 metrics hero
            Row(
              children: [
                _HeroMetric(
                  label: 'FCR',
                  value: fcr > 0 ? fcr.toStringAsFixed(2) : '-',
                  status: _fcrStatus(fcr),
                ),
                _VerticalDivider(),
                _HeroMetric(
                  label: 'Survival',
                  value: '${survivalRate.toStringAsFixed(1)}%',
                  status: _survivalStatus(survivalRate),
                ),
                _VerticalDivider(),
                _HeroMetric(
                  label: 'Berat Akhir',
                  value: finalAvgWeightGram > 0
                      ? '${(finalAvgWeightGram / 1000).toStringAsFixed(2)} kg'
                      : '-',
                  status: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PeriodStatus? _fcrStatus(double fcr) {
    if (fcr <= 0) return null;
    if (fcr <= 1.8) return PeriodStatus.good;
    if (fcr >= 2.2) return PeriodStatus.bad;
    return PeriodStatus.warning;
  }

  PeriodStatus? _survivalStatus(double rate) {
    if (rate >= 95) return PeriodStatus.good;
    if (rate < 90) return PeriodStatus.bad;
    return PeriodStatus.warning;
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final PeriodStatus? status;

  const _HeroMetric({required this.label, required this.value, this.status});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = status != null
        ? PeriodEvaluator.statusColor(status!)
        : Colors.white;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
