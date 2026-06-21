import 'package:flutter/material.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'package:recording_app/features/reporting/presentation/widgets/analytics_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/performance_card.dart';
import 'package:recording_app/features/reporting/presentation/widgets/population_card.dart';
import 'package:recording_app/core/components/snackbars/app_snackbar.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';

/// Halaman detail laporan lengkap: periode info, kartu metrik, tabel harian, export.
/// Dibuka dari [PeriodReportPage] via tombol "Lihat Detail & Export".
/// Tidak perlu navigator baru — menggunakan [ReportingController] yang sudah ada di tree.
class DetailPeriodReport extends StatelessWidget {
  const DetailPeriodReport({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportingController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: const AppHeader(title: 'Detail Laporan'),
      body: SafeArea(
        top: false,
        child: _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReportingController controller) {
    if (controller.isLoadingRecordings) {
      return const ReportSkeleton();
    }

    if (controller.errorMessage != null) {
      return AppErrorState(
        message: 'Gagal memuat detail laporan',
        subtitle: controller.errorMessage,
        onRetry: () => controller.reload(),
      );
    }

    if (controller.report == null) {
      return const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'Tidak ada data laporan',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => controller.reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PeriodInfoCard(controller: controller),
            const SizedBox(height: 16),
            _ExportButtons(controller: controller),
            const SizedBox(height: 16),
            PopulationCard(report: controller.report!),
            const SizedBox(height: 12),
            PerformanceCard(report: controller.report!),
            const SizedBox(height: 12),
            AnalyticsCard(report: controller.report!),
            const SizedBox(height: 16),
            _RecapHarianButton(),
          ],
        ),
      ),
    );
  }
}

// ── Period Info Card ──────────────────────────────────────────────────────────

class _PeriodInfoCard extends StatelessWidget {
  final ReportingController controller;
  const _PeriodInfoCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final period = controller.selectedPeriod;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Info Periode',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (period != null) ...[
              _InfoRow(label: 'Nama', value: period.name),
              const SizedBox(height: 6),
              _InfoRow(label: 'Mulai', value: dateFmt.format(period.startDate)),
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Selesai',
                value: period.endDate != null
                    ? dateFmt.format(period.endDate!)
                    : 'Ongoing',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Durasi',
                value: controller.report != null
                    ? '${controller.report!.durationDays} Hari'
                    : '-',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Status',
                value: period.isActive ? 'Aktif' : 'Ditutup',
                valueColor:
                    period.isActive ? AppColors.success : AppColors.error,
              ),
            ],
          ],
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
        Text(label,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
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

// ── Export Buttons ────────────────────────────────────────────────────────────

class _ExportButtons extends StatelessWidget {
  final ReportingController controller;
  const _ExportButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Disable semua tombol saat sedang export — cegah double tap.
    final busy = controller.isExporting;

    return Row(
      children: [
        Expanded(
          child: _ExportChip(
            label: 'Ekspor CSV',
            icon: Icons.table_rows_outlined,
            isLoading: busy,
            onTap: busy ? null : () => _exportCsv(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ExportChip(
            label: 'Ekspor Excel',
            icon: Icons.grid_on_outlined,
            isLoading: busy,
            onTap: busy ? null : () => _exportExcel(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ExportChip(
            label: 'Ekspor PDF',
            icon: Icons.picture_as_pdf_outlined,
            isLoading: false,
            onTap: busy
                ? null
                : () => AppSnackbar.showInfo(context, 'PDF export: coming soon'),
          ),
        ),
      ],
    );
  }

  void _exportCsv(BuildContext context) {
    controller.exportCsv(
      onError: (msg) {
        if (context.mounted) AppSnackbar.showError(context, 'CSV export gagal: $msg');
      },
    );
  }

  void _exportExcel(BuildContext context) {
    controller.exportExcel(
      onError: (msg) {
        if (context.mounted) AppSnackbar.showError(context, 'Excel export gagal: $msg');
      },
    );
  }
}

class _ExportChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;
  const _ExportChip({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.onTap,
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
          color: disabled
              ? (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(0.6)
              : (Theme.of(context).cardTheme.color ?? Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? cs.outlineVariant : cs.primary.withOpacity(0.15),
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            else
              Icon(icon, size: 20,
                  color: disabled ? cs.onSurface.withOpacity(0.3) : cs.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                color:
                    disabled ? cs.onSurface.withOpacity(0.3) : cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rekap Harian Button ───────────────────────────────────────────────────────

/// Button "Rekap Harian" — mengambil recordings langsung dari DB saat diklik,
/// lalu membuka [DetailRecording] dalam mode read-only.
///
/// Tidak bergantung pada [PeriodReport.recordings] yang bisa kosong
/// (misal: periode yang menggunakan snapshot).
class _RecapHarianButton extends StatelessWidget {
  const _RecapHarianButton();

  @override
  Widget build(BuildContext context) {
    // watch agar rebuild otomatis saat isLoadingRecordingDetail berubah.
    final controller = context.watch<ReportingController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loading = controller.isLoadingRecordingDetail;

    return OutlinedButton.icon(
      onPressed: loading ? null : () => _open(context, controller),
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
            )
          : Icon(Icons.receipt_long_outlined, size: 18, color: cs.primary),
      label: Text(
        loading ? 'Memuat data...' : 'Rekap Harian',
        style: tt.labelLarge?.copyWith(
          color: loading ? cs.onSurface.withOpacity(0.5) : cs.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: cs.primary.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _open(BuildContext context, ReportingController controller) {
    controller.viewRecordingDetail(
      onReady: (recordings) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailRecording(
              recordings: recordings,
              readOnly: true,
            ),
          ),
        );
      },
      onError: (msg) {
        if (context.mounted) AppSnackbar.showError(context, msg);
      },
    );
  }
}
