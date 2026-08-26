import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Evaluasi status berdasarkan FCR dan survival rate.
enum PeriodStatus { good, warning, bad }

class PeriodEvaluator {
  static PeriodStatus evaluate({required double fcr, required double survivalRate}) {
    if (fcr <= 0) return PeriodStatus.warning;
    if (fcr <= 1.8 && survivalRate >= 95) return PeriodStatus.good;
    if (fcr >= 2.2 || survivalRate < 90) return PeriodStatus.bad;
    return PeriodStatus.warning;
  }

  /// Warna status yang ditampilkan di atas hero card (background primary biru).
  /// Menggunakan pastel agar kontras di atas [AppColors.primary].
  static Color statusColor(BuildContext context, PeriodStatus status) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      switch (status) {
        case PeriodStatus.good:
          return AppColors.fcrGoodText;
        case PeriodStatus.warning:
          return AppColors.fcrWarnText;
        case PeriodStatus.bad:
          return AppColors.fcrBadText;
      }
    } else {
      // Pastel — kontras di atas hero card Vivid Blue (#1A47E5)
      switch (status) {
        case PeriodStatus.good:
          return const Color(0xFFA3E6BE); // pastel green
        case PeriodStatus.warning:
          return const Color(0xFFFFD580); // pastel amber
        case PeriodStatus.bad:
          return const Color(0xFFFF9A9A); // pastel red
      }
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
  final bool showPeriodSelector;
  final VoidCallback? onPeriodSelectorTap;

  const ReportSummaryHeader({
    super.key,
    required this.periodName,
    required this.dateRange,
    required this.durationDays,
    required this.fcr,
    required this.survivalRate,
    required this.finalAvgWeightGram,
    this.showPeriodSelector = false,
    this.onPeriodSelectorTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = PeriodEvaluator.evaluate(fcr: fcr, survivalRate: survivalRate);
    final color = PeriodEvaluator.statusColor(context, status);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
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
                      Material(
                        color: (showPeriodSelector && onPeriodSelectorTap != null)
                            ? cs.onPrimary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: (showPeriodSelector && onPeriodSelectorTap != null)
                              ? onPeriodSelectorTap
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    periodName,
                                    style: tt.titleLarge?.copyWith(
                                      color: cs.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (showPeriodSelector && onPeriodSelectorTap != null) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: cs.onPrimary,
                                    size: 24,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          '$dateRange • $durationDays Hari',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(color: color, width: 1.5),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
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
            Divider(color: cs.onPrimary.withValues(alpha: 0.2), height: 1),
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
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final color = status != null
        ? PeriodEvaluator.statusColor(context, status!)
        : onPrimary;

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
            style: tt.bodySmall?.copyWith(color: onPrimary.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: 1,
      height: 40,
      color: onPrimary.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
