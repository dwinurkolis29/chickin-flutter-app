import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/export/presentation/pages/pdf_preview_page.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/period_comparison_calculator.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'package:recording_app/features/reporting/presentation/widgets/fcr_trend_chart.dart';
import 'package:recording_app/features/reporting/presentation/widgets/insight_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/key_metrics_grid.dart';
import 'package:recording_app/features/reporting/presentation/widgets/production_summary_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/report_summary_header.dart';

/// Halaman Laporan Periode yang berfokus pada kesimpulan performa panen peternakan,
/// Indeks Performa (IP), FCR, Daya Hidup, serta rekomendasi untuk periode berikutnya.
class PeriodReportPage extends StatelessWidget {
  final bool isTab;
  const PeriodReportPage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return _PeriodReportPageView(isTab: isTab);
  }
}

class _PeriodReportPageView extends StatelessWidget {
  final bool isTab;
  const _PeriodReportPageView({this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportingController>();
    final cs = Theme.of(context).colorScheme;

    if (isTab) {
      return SafeArea(
        child: _buildBody(context, controller),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppHeader(
        title: 'Laporan',
        actions: [
          if (controller.closedPeriods.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Pilih Periode',
              onPressed: () => DialogHelper.showPeriodPicker(
                context,
                periods: controller.closedPeriods,
                selectedPeriodId: controller.selectedPeriodId,
                onSelected: controller.selectPeriod,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReportingController controller) {
    if (controller.isLoading) {
      return const ReportSkeleton();
    }

    if (controller.errorMessage != null) {
      return AppErrorState(
        message: 'Gagal memuat data laporan',
        subtitle: controller.errorMessage,
        onRetry: () => controller.reload(),
      );
    }

    if (controller.closedPeriods.isEmpty) {
      return const AppEmptyState(
        icon: Icons.assignment_turned_in_outlined,
        message: 'Belum Ada Periode Panen',
        subtitle:
            'Laporan performa akhir, kalkulasi Indeks Performa (IP), FCR Panen, dan HPP akan terbentuk otomatis setelah siklus pemeliharaan ayam diselesaikan.',
      );
    }

    if (controller.isLoadingRecordings) {
      return const ReportSkeleton();
    }

    if (controller.report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppEmptyState(
                icon: Icons.bar_chart_outlined,
                message: 'Belum Ada Data Laporan',
                subtitle: 'Data ringkasan panen untuk siklus ini belum tersedia.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => DialogHelper.showPeriodPicker(
                  context,
                  periods: controller.closedPeriods,
                  selectedPeriodId: controller.selectedPeriodId,
                  onSelected: controller.selectPeriod,
                ),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Pilih Periode Lain'),
              ),
            ],
          ),
        ),
      );
    }

    return _SummaryContent(
      controller: controller,
      report: controller.report!,
    );
  }
}

// ── Summary Content ───────────────────────────────────────────────────────────

class _SummaryContent extends StatelessWidget {
  final ReportingController controller;
  final PeriodReport report;

  const _SummaryContent({required this.controller, required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final period = report.period;
    final summary = period.summary;
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

    final startStr = dateFmt.format(period.startDate);
    final endStr = period.endDate != null ? dateFmt.format(period.endDate!) : 'Aktif';
    final dateRange = '$startStr – $endStr';

    final insights = summary?.insights ?? [];
    final weeklyFCR = summary?.weeklyFCR ?? [];

    return RefreshIndicator(
      onRefresh: () async => controller.reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. TOMBOL PILIH PERIODE
            Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                onTap: () => DialogHelper.showPeriodPicker(
                  context,
                  periods: controller.closedPeriods,
                  selectedPeriodId: controller.selectedPeriodId,
                  onSelected: controller.selectPeriod,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Periode Panen',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              period.name,
                              style: tt.titleSmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 16,
                              color: cs.onPrimaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pilih Periode',
                              style: tt.labelMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 1. HERO SUMMARY (IP / EPEF + Status + Export)
            ReportSummaryHeader(
              periodName: period.name,
              dateRange: dateRange,
              durationDays: report.durationDays,
              fcr: report.fcr,
              survivalRate: report.survivalRate,
              finalAvgWeightGram: report.finalAvgWeightGram,
              ipScore: report.ipScore,
              showPeriodSelector: true,
              onPeriodSelectorTap: () => DialogHelper.showPeriodPicker(
                context,
                periods: controller.closedPeriods,
                selectedPeriodId: controller.selectedPeriodId,
                onSelected: controller.selectPeriod,
              ),
              controller: controller,
            ),
            const SizedBox(height: 16),

            // 2. 4 INDIKATOR UTAMA (Simpel, Berwarna, dan Tidak Teknis)
            KeyMetricsGrid(
              initialPopulation: report.initialPopulation,
              totalMortality: report.totalMortality,
              finalPopulation: report.finalPopulation,
              totalFeedKg: report.totalFeedKg,
              fcr: report.fcr,
              survivalRate: report.survivalRate,
              harvestedChicks: report.harvestedChicks,
              harvestedWeightKg: report.harvestedWeightKg,
              avgHarvestWeightKg: report.avgHarvestWeightKg,
            ),
            const SizedBox(height: 16),

            // 3. TREN FCR MINGGUAN
            if (weeklyFCR.isNotEmpty) ...[
              FCRTrendChart(weeklyFCR: weeklyFCR),
              const SizedBox(height: 16),
            ],

            // 4. KESIMPULAN & SARAN PERIODE BERIKUTNYA
            InsightCard(insights: insights),
            const SizedBox(height: 16),

            // 5. RINGKASAN DATA PRODUKSI
            ProductionSummaryCard(
              totalFeedKg: report.totalFeedKg,
              totalBiomassKg: report.totalBiomassKg,
              avgDailyGainGram: report.avgDailyGainGram,
              feedPerBird: report.feedPerBird,
              durationDays: report.durationDays,
            ),
            const SizedBox(height: 20),

            // 6. TOMBOL UTAMA PRATINJAU & CETAK LAPORAN PDF
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfPreviewPage(
                      report: report,
                      finance: controller.financeSummary,
                      comparison: controller.comparison ??
                          PeriodComparisonCalculator().execute(
                            currentReport: report,
                            currentFinance: controller.financeSummary,
                          ),
                      cage: controller.cageData,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                'Pratinjau & Cetak Laporan PDF',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
