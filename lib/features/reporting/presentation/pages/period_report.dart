import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/export/domain/usecases/export_period_csv.dart';
import 'package:recording_app/features/export/domain/usecases/export_period_excel.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'package:recording_app/features/reporting/presentation/widgets/population_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/performance_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/analytics_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/recording_table.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';

/// Navigate to this page using [Navigator.push] or push a named route.
/// [ReportingController] must be available in the provider tree
/// (registered in main_app.dart MultiProvider).
class PeriodReportView extends StatelessWidget {
  const PeriodReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PeriodReportView();
  }
}

class _PeriodReportView extends StatelessWidget {
  const _PeriodReportView();

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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea(top: false, child: _buildBody(context, controller)),
    );
  }

  Widget _buildBody(BuildContext context, ReportingController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.closedPeriods.isEmpty) {
      return _EmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodHeaderSection(controller: controller),
          const SizedBox(height: 16),
          _ExportButtons(controller: controller),
          const SizedBox(height: 16),
          if (controller.isLoadingRecordings)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (controller.report != null) ...[
            PopulationCard(report: controller.report!),
            const SizedBox(height: 12),
            PerformanceCard(report: controller.report!),
            const SizedBox(height: 12),
            AnalyticsCard(report: controller.report!),
            const SizedBox(height: 12),
            RecordingTable(report: controller.report!),
          ],
        ],
      ),
    );
  }
}

// ── Header Section ─────────────────────────────────────────────────────────────

class PeriodHeaderSection extends StatelessWidget {
  final ReportingController controller;
  const PeriodHeaderSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final period = controller.selectedPeriod;

    final dateFmt = DateFormat('dd MMM yyyy');

    String startStr = '-';
    String endStr = '-';
    String durationStr = '-';
    String statusStr = '-';
    String periodName = 'Pilih Periode';

    if (period != null) {
      startStr = dateFmt.format(period.startDate);
      endStr =
          period.endDate != null ? dateFmt.format(period.endDate!) : 'Ongoing';
      durationStr =
          controller.report != null
              ? '${controller.report!.durationDays} Hari'
              : '-';
      statusStr = period.isActive ? 'Active' : 'Closed';
      periodName = period.name;
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Period selector row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Periode',
                  style: tt.titleMedium?.copyWith(color: cs.onSurface),
                ),
                const Spacer(),
                _PeriodDropdown(controller: controller),
              ],
            ),
          ),
          const Divider(height: 20),
          // Info rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _InfoRow(label: 'Nama', value: periodName),
                const SizedBox(height: 6),
                _InfoRow(label: 'Mulai', value: startStr),
                const SizedBox(height: 6),
                _InfoRow(label: 'Selesai', value: endStr),
                const SizedBox(height: 6),
                _InfoRow(label: 'Durasi', value: durationStr),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Status',
                  value: statusStr,
                  valueColor:
                      period?.isActive == true
                          ? AppColors.success
                          : AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  final ReportingController controller;
  const _PeriodDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final periods = controller.closedPeriods;

    if (periods.isEmpty) return const SizedBox.shrink();

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
          icon: Icon(Icons.expand_more, size: 18, color: cs.primary),
          style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          items:
              periods
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.name,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (id) {
            if (id != null) controller.selectPeriod(id);
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6)),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Export Buttons ─────────────────────────────────────────────────────────────

class _ExportButtons extends StatelessWidget {
  final ReportingController controller;
  const _ExportButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ExportChip(
            label: 'Export CSV',
            icon: Icons.table_rows_outlined,
            onTap: controller.report == null ? null : () => _exportCsv(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ExportChip(
            label: 'Export Excel',
            icon: Icons.grid_on_outlined,
            onTap:
                controller.report == null ? null : () => _exportExcel(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ExportChip(
            label: 'Export PDF',
            icon: Icons.picture_as_pdf_outlined,
            onTap: () => _showComingSoon(context),
          ),
        ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      await ExportPeriodCsv().execute(controller.report!);
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'CSV export gagal: $e');
      }
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    try {
      await ExportPeriodExcel().execute(controller.report!);
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Excel export gagal: $e');
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    AppSnackbar.showInfo(context, 'PDF export: coming soon');
  }

  void _showError(BuildContext context, String msg) {
    AppSnackbar.showError(context, msg);
  }
}

class _ExportChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ExportChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: disabled ? cs.surface.withOpacity(0.5) : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? cs.outlineVariant : cs.primary.withOpacity(0.4),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: disabled ? cs.onSurface.withOpacity(0.3) : cs.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color: disabled ? cs.onSurface.withOpacity(0.3) : cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

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
            Icon(Icons.bar_chart_outlined, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
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
