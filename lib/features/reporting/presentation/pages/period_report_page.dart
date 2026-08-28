import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
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
        top: false,
        child: _buildBody(context, controller),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppHeader(
        title: 'Laporan Periode',
      ),
      body: SafeArea(
        top: false,
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
        icon: Icons.bar_chart_outlined,
        message: 'Belum ada periode yang selesai dipanen',
      );
    }

    if (controller.isLoadingRecordings) {
      return const ReportSkeleton();
    }

    if (controller.report == null) {
      return const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'Belum ada data laporan untuk periode ini',
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO SUMMARY (IP / EPEF + Status + Export)
            ReportSummaryHeader(
              periodName: period.name,
              dateRange: dateRange,
              durationDays: report.durationDays,
              fcr: report.fcr,
              survivalRate: report.survivalRate,
              finalAvgWeightGram: report.finalAvgWeightGram,
              ipScore: report.ipScore,
              showPeriodSelector: controller.closedPeriods.length > 1,
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
          ],
        ),
      ),
    );
  }
}
