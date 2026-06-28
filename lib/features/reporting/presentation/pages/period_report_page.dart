import 'package:flutter/material.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'package:recording_app/features/reporting/presentation/pages/detail_period_report.dart';
import 'package:recording_app/features/reporting/presentation/widgets/expandable_detail_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/fcr_trend_chart.dart';
import 'package:recording_app/features/reporting/presentation/widgets/insight_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/key_metrics_grid.dart';
import 'package:recording_app/features/reporting/presentation/widgets/report_summary_header.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';

/// Entry point laporan periode.
/// Menampilkan summary: hero, key metrics, tren FCR, insight, detail collapsible.
/// Tombol "Lihat Detail" membuka [DetailPeriodReport] (tabel + export).
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
  const _PeriodReportPageView({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportingController>();
    final cs = Theme.of(context).colorScheme;

    // Saat dipakai sebagai tab di Dashboard, cukup return body tanpa Scaffold
    // agar AppHeader dari Dashboard tidak terduplikasi.
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
        message: 'Belum ada periode yang selesai',
      );
    }

    if (controller.isLoadingRecordings) {
      return const ReportSkeleton();
    }

    if (controller.report == null) {
      return const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'Belum ada periode yang selesai',
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
    final dateFmt = DateFormat('dd MMM yyyy');

    final startStr = dateFmt.format(period.startDate);
    final endStr = period.endDate != null ? dateFmt.format(period.endDate!) : 'Aktif';
    final dateRange = '$startStr – $endStr';

    final insights = summary?.insights ?? [];
    final weeklyFCR = summary?.weeklyFCR ?? [];

    return RefreshIndicator(
      onRefresh: () async => controller.reload(),
      child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO SUMMARY
          ReportSummaryHeader(
            periodName: period.name,
            dateRange: dateRange,
            durationDays: report.durationDays,
            fcr: report.fcr,
            survivalRate: report.survivalRate,
            finalAvgWeightGram: report.finalAvgWeightGram,
            showPeriodSelector: controller.closedPeriods.length > 1,
            onPeriodSelectorTap: () => DialogHelper.showPeriodPicker(
              context,
              periods: controller.closedPeriods,
              selectedPeriodId: controller.selectedPeriodId,
              onSelected: controller.selectPeriod,
            ),
          ),
          const SizedBox(height: 16),

          // 2. KEY METRICS
          KeyMetricsGrid(
            initialPopulation: report.initialPopulation,
            totalMortality: report.totalMortality,
            finalPopulation: report.finalPopulation,
            totalFeedKg: report.totalFeedKg,
            fcr: report.fcr,
            survivalRate: report.survivalRate,
          ),
          const SizedBox(height: 16),

          // 3. TREND FCR
          FCRTrendChart(weeklyFCR: weeklyFCR),
          const SizedBox(height: 16),

          // 4. INSIGHT
          InsightCard(insights: insights),
          const SizedBox(height: 16),

          // 5. DETAIL (collapsible)
          ExpandableDetailCard(
            totalBiomassKg: report.totalBiomassKg,
            avgDailyGainGram: report.avgDailyGainGram,
            feedPerBird: report.feedPerBird,
            weightGainKg: report.weightGainKg,
            finalAvgWeightGram: report.finalAvgWeightGram,
          ),
          const SizedBox(height: 24),

          // 6. DETAIL BUTTON — menuju halaman rekap lengkap + export
          _DetailButton(controller: controller),
        ],
      ),
    ),
    );
  }
}


// ── Detail Button ─────────────────────────────────────────────────────────────

class _DetailButton extends StatelessWidget {
  final ReportingController controller;
  const _DetailButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: controller,
              child: const DetailPeriodReport(),
            ),
          ),
        );
      },
      icon: Icon(Icons.table_rows_outlined, size: 18, color: cs.primary),
      label: Text(
        'Lihat Detail & Export',
        style: tt.labelLarge?.copyWith(color: cs.primary),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: cs.primary.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
