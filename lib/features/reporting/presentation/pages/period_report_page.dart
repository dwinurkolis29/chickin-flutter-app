import 'package:flutter/material.dart';
import 'package:recording_app/core/tour/tour_controller.dart';
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

/// Entry point laporan periode.
/// Menampilkan summary: hero, key metrics, tren FCR, insight, detail collapsible.
/// Tombol "Lihat Detail" membuka [DetailPeriodReport] (tabel + export).
class PeriodReportPage extends StatelessWidget {
  const PeriodReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PeriodReportPageView();
  }
}

class _PeriodReportPageView extends StatefulWidget {
  const _PeriodReportPageView();

  @override
  State<_PeriodReportPageView> createState() => _PeriodReportPageViewState();
}

class _PeriodReportPageViewState extends State<_PeriodReportPageView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TourController>().complete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportingController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: cs.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Laporan Periode',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
        ),
        centerTitle: true,
        actions: [
          // Period selector di appbar
          if (!controller.isLoading && controller.closedPeriods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PeriodSelector(controller: controller),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReportingController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.closedPeriods.isEmpty) {
      return _EmptyState();
    }

    if (controller.isLoadingRecordings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.report == null) {
      return _EmptyState();
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

    // Insights: ambil dari summary jika ada, fallback kosong
    final insights = summary?.insights ?? [];

    // WeeklyFCR: dari summary (snapshot) atau dari report fallback
    final weeklyFCR = summary?.weeklyFCR ?? [];

    return SingleChildScrollView(
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
    );
  }
}

// ── Period Selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final ReportingController controller;
  const _PeriodSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final periods = controller.closedPeriods;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedPeriodId,
          isDense: true,
          icon: Icon(Icons.expand_more, size: 16, color: cs.primary),
          style: tt.bodySmall?.copyWith(color: cs.onSurface),
          items: periods
              .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      p.name,
                      style: tt.bodySmall?.copyWith(color: cs.onSurface),
                    ),
                  ))
              .toList(),
          onChanged: (id) {
            if (id != null) controller.selectPeriod(id);
          },
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

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Belum ada periode yang selesai',
              style: tt.bodyMedium?.copyWith(color: cs.outlineVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
