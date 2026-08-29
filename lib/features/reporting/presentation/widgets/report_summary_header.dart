import 'package:flutter/material.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';

/// Predikat Indeks Performa (IP / EPEF) Broiler
enum IPStatus { excellent, veryGood, good, needsImprovement }

class IPEvaluator {
  static IPStatus evaluate(double? ip) {
    if (ip == null || ip <= 0) return IPStatus.good;
    if (ip >= 400) return IPStatus.excellent;
    if (ip >= 350) return IPStatus.veryGood;
    if (ip >= 300) return IPStatus.good;
    return IPStatus.needsImprovement;
  }

  static Color statusColor(BuildContext context, IPStatus status) {
    switch (status) {
      case IPStatus.excellent:
        return const Color(0xFFA3E6BE); // pastel emerald green
      case IPStatus.veryGood:
        return const Color(0xFF90CAF9); // pastel light blue
      case IPStatus.good:
        return const Color(0xFFFFD580); // pastel amber
      case IPStatus.needsImprovement:
        return const Color(0xFFFF9A9A); // pastel soft red
    }
  }

  static String statusLabel(IPStatus status) {
    switch (status) {
      case IPStatus.excellent:
        return 'Istimewa';
      case IPStatus.veryGood:
        return 'Sangat Baik';
      case IPStatus.good:
        return 'Baik / Standar';
      case IPStatus.needsImprovement:
        return 'Perlu Perbaikan';
    }
  }

  static IconData statusIcon(IPStatus status) {
    switch (status) {
      case IPStatus.excellent:
        return Icons.emoji_events_rounded;
      case IPStatus.veryGood:
        return Icons.verified_rounded;
      case IPStatus.good:
        return Icons.check_circle_rounded;
      case IPStatus.needsImprovement:
        return Icons.warning_amber_rounded;
    }
  }

  static String conclusionText(IPStatus status, double? ip) {
    final ipText = ip != null && ip > 0 ? ' (IP ${ip.toStringAsFixed(0)})' : '';
    switch (status) {
      case IPStatus.excellent:
        return 'Hasil panen luar biasa$ipText! Efisiensi pakan dan kelangsungan hidup ayam sangat prima.';
      case IPStatus.veryGood:
        return 'Performa panen optimal$ipText. Manajemen pemeliharaan berhasil memenuhi target di atas rata-rata.';
      case IPStatus.good:
        return 'Siklus panen berhasil$ipText dan mencapai standar efisiensi broiler komersial.';
      case IPStatus.needsImprovement:
        return 'Hasil panen masih di bawah target$ipText. Evaluasi efisiensi pakan dan penanganan kematian di periode berikutnya.';
    }
  }
}

/// Hero card yang langsung menjawab "Periode ini bagus atau tidak?".
/// Menampilkan Skor IP, FCR, Daya Hidup, serta tombol pemilih periode dan export cepat.
class ReportSummaryHeader extends StatelessWidget {
  final String periodName;
  final String dateRange;
  final int durationDays;
  final double fcr;
  final double survivalRate;
  final int finalAvgWeightGram;
  final double? ipScore;
  final bool showPeriodSelector;
  final VoidCallback? onPeriodSelectorTap;
  final ReportingController controller;

  const ReportSummaryHeader({
    super.key,
    required this.periodName,
    required this.dateRange,
    required this.durationDays,
    required this.fcr,
    required this.survivalRate,
    required this.finalAvgWeightGram,
    this.ipScore,
    this.showPeriodSelector = false,
    this.onPeriodSelectorTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final double resolvedIP = (ipScore != null && ipScore! > 0)
        ? ipScore!
        : (durationDays > 0 && fcr > 0 && survivalRate > 0 && finalAvgWeightGram > 0
            ? ((survivalRate * (finalAvgWeightGram / 1000.0) * 100.0) / (durationDays * fcr))
            : 0.0);

    final ipStatus = IPEvaluator.evaluate(resolvedIP);
    final badgeColor = IPEvaluator.statusColor(context, ipStatus);
    final conclusion = IPEvaluator.conclusionText(ipStatus, resolvedIP);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.85),
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
            // Top Bar: Period Name Selector & Quick Export Icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: (showPeriodSelector && onPeriodSelectorTap != null)
                        ? onPeriodSelectorTap
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                // Export Buttons
                _QuickExportButton(
                  icon: Icons.table_chart_outlined,
                  tooltip: 'Export Excel',
                  isLoading: controller.isExporting,
                  onTap: () => controller.exportExcel(
                    onError: (err) => AppSnackbar.showError(context, err),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$dateRange • $durationDays Hari',
              style: tt.bodySmall?.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),

            // Hero Section: Indeks Performa (IP / EPEF)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.onPrimary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_events_outlined,
                              size: 16,
                              color: badgeColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Indeks Performa (IP)',
                            style: tt.labelMedium?.copyWith(
                              color: cs.onPrimary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          border: Border.all(color: badgeColor, width: 1.2),
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(IPEvaluator.statusIcon(ipStatus), size: 13, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              IPEvaluator.statusLabel(ipStatus),
                              style: tt.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        resolvedIP > 0 ? resolvedIP.toStringAsFixed(0) : '-',
                        style: tt.headlineMedium?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Poin',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conclusion,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.95),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bottom 3 Quick Metrics
            Row(
              children: [
                _HeroMetric(
                  label: 'FCR Panen',
                  value: fcr > 0 ? fcr.toStringAsFixed(2) : '-',
                  statusText: fcr <= 1.80 ? 'Efisien' : (fcr <= 2.20 ? 'Normal' : 'Boros'),
                ),
                _VerticalDivider(),
                _HeroMetric(
                  label: 'Daya Hidup',
                  value: '${survivalRate.toStringAsFixed(1)}%',
                  statusText: survivalRate >= 95 ? 'Sangat Baik' : 'Cukup',
                ),
                _VerticalDivider(),
                _HeroMetric(
                  label: 'Rata-rata Bobot',
                  value: finalAvgWeightGram > 0
                      ? '${(finalAvgWeightGram / 1000).toStringAsFixed(2)} kg'
                      : '-',
                  statusText: 'Panen',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickExportButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isLoading;
  final VoidCallback onTap;

  const _QuickExportButton({
    required this.icon,
    required this.tooltip,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.onPrimary.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: cs.onPrimary),
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final String statusText;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: tt.titleMedium?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: onPrimary.withValues(alpha: 0.7),
              fontSize: 11,
            ),
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
      height: 32,
      color: onPrimary.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
