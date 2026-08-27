import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/error/app_error_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/components/loading/shimmer_loading.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/fcr_datacard.dart';
import 'package:recording_app/features/recording/data/models/daily_fcr_data.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

/// Screen Monitoring FCR (Harian & Mingguan) untuk peternak mandiri.
/// Menyajikan kesimpulan kondisi efisiensi pakan yang cepat dan mudah dipahami.
class FCRMonitoringScreen extends StatefulWidget {
  const FCRMonitoringScreen({super.key});

  @override
  State<FCRMonitoringScreen> createState() => _FCRMonitoringScreenState();
}

class _FCRMonitoringScreenState extends State<FCRMonitoringScreen> {
  int _selectedTab = 0; // 0: Harian, 1: Mingguan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        title: 'Monitoring FCR',
      ),
      body: SafeArea(
        bottom: false,
        child: Consumer<HomeController>(
          builder: (context, controller, _) {
            if (controller.isLoadingPeriod) {
              return const ReportSkeleton();
            }

            if (controller.activePeriodId == null) {
              return const AppEmptyState(
                icon: Icons.calendar_today_outlined,
                message: 'Tidak ada periode aktif',
                subtitle: 'Buat atau pilih periode terlebih dahulu untuk memantau FCR.',
              );
            }

            return StreamBuilder<List<RecordingData>>(
              stream: controller.recordingsStream,
              initialData: controller.cachedRecordings,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const TableSkeleton();
                }

                if (snapshot.hasError && !snapshot.hasData) {
                  return AppErrorState(
                    message: 'Gagal memuat data monitoring FCR',
                    subtitle: snapshot.error.toString(),
                    onRetry: () => controller.loadActivePeriod(),
                  );
                }

                final recordings = snapshot.data ?? <RecordingData>[];
                if (recordings.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.scale_outlined,
                    message: 'Belum ada data recording',
                    subtitle: 'Tambahkan data recording harian untuk melihat kalkulasi FCR.',
                  );
                }

                final weeklyFcrList = controller.calculateWeeklyFCR(recordings);
                final dailyFcrList = controller.calculateDailyFCR(recordings);

                final latestFcr = dailyFcrList.isNotEmpty ? dailyFcrList.last.fcr : 0.0;
                final latestAge = recordings.isNotEmpty ? recordings.last.day : 0;
                final totalFeedKg = dailyFcrList.isNotEmpty ? dailyFcrList.last.cumulativeFeedKg : 0.0;
                final totalBiomassKg = dailyFcrList.isNotEmpty ? dailyFcrList.last.totalBiomassKg : 0.0;
                final remainingChickens = dailyFcrList.isNotEmpty ? dailyFcrList.last.sisaAyam : 0;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── 1. Hero Summary Card (Kesimpulan Langsung) ────
                          _buildHeroSummaryCard(
                            context: context,
                            fcr: latestFcr,
                            age: latestAge,
                            totalFeedKg: totalFeedKg,
                            totalBiomassKg: totalBiomassKg,
                            remainingChickens: remainingChickens,
                            periodName: controller.activePeriodName ?? 'Periode Aktif',
                          ),
                          const SizedBox(height: 16),

                          // ── 2. Tab Switcher Harian vs Mingguan ────────────
                          _buildTabSwitcher(context),
                          const SizedBox(height: 16),

                          // ── 3. Tab Body ──────────────────────────────────
                          if (_selectedTab == 0)
                            _buildDailyList(context, dailyFcrList)
                          else
                            _buildWeeklyView(context, weeklyFcrList),

                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Hero Summary Card ──────────────────────────────────────────────────────
  Widget _buildHeroSummaryCard({
    required BuildContext context,
    required double fcr,
    required int age,
    required double totalFeedKg,
    required double totalBiomassKg,
    required int remainingChickens,
    required String periodName,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat.decimalPattern('id_ID');

    final status = _getFcrStatus(fcr);
    final statusText = _getFcrStatusLabel(status);
    final statusColor = _getFcrStatusTextColor(status);
    final statusBg = _getFcrStatusBgColor(status);
    final statusIcon = _getFcrStatusIcon(status);
    final statusDescription = _getFcrStatusDescription(status);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Periode & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodName,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Umur $age Hari • Akumulasi Saat Ini',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: tt.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nilai Besar FCR & Target
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.rowRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nilai FCR Kumulatif',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target Standar: ≤ 1,80',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    fmt.format(fcr),
                    style: tt.headlineMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Kesimpulan Kondisi Pakan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusDescription,
                      style: tt.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid Ringkasan Fisik (Pakan, Bobot, Sisa Ayam)
            Row(
              children: [
                Expanded(
                  child: _buildMetricMiniTile(
                    context: context,
                    label: 'Total Pakan',
                    value: '${fmt.format(totalFeedKg)} kg',
                    subValue: '${(totalFeedKg / 50).toStringAsFixed(1)} sak',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricMiniTile(
                    context: context,
                    label: 'Total Bobot',
                    value: '${fmt.format(totalBiomassKg)} kg',
                    subValue: 'Biomassa hidup',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricMiniTile(
                    context: context,
                    label: 'Sisa Ayam',
                    value: fmt.format(remainingChickens),
                    subValue: 'Ekor hidup',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMiniTile({
    required BuildContext context,
    required String label,
    required String value,
    required String subValue,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.rowRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subValue,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Tab Switcher ───────────────────────────────────────────────────────────
  Widget _buildTabSwitcher(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  '1. FCR Harian',
                  style: tt.labelMedium?.copyWith(
                    color: _selectedTab == 0 ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  '2. FCR Mingguan',
                  style: tt.labelMedium?.copyWith(
                    color: _selectedTab == 1 ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Daily FCR List ─────────────────────────────────────────────────────────
  Widget _buildDailyList(BuildContext context, List<DailyFCRData> dailyList) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (dailyList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Belum ada data FCR harian.',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    // Urutkan dari hari terbaru ke hari awal agar peternak langsung melihat perkembangan terakhir
    final reversedList = dailyList.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'RIWAYAT FCR PER HARI (TERBARU DULU)',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...reversedList.map((daily) => _DailyFCRCard(data: daily)),
      ],
    );
  }

  // ── Weekly FCR View ────────────────────────────────────────────────────────
  Widget _buildWeeklyView(BuildContext context, List<FCRData> weeklyList) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'RIWAYAT FCR PER MINGGU',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        FCRDataCard(fcrData: weeklyList),
      ],
    );
  }

  // ── Helper Status FCR ──────────────────────────────────────────────────────
  _FCRStatusType _getFcrStatus(double fcr) {
    if (fcr <= 1.80) return _FCRStatusType.good;
    if (fcr <= 2.20) return _FCRStatusType.warn;
    return _FCRStatusType.bad;
  }

  String _getFcrStatusLabel(_FCRStatusType status) {
    switch (status) {
      case _FCRStatusType.good:
        return 'Efisien (Bagus)';
      case _FCRStatusType.warn:
        return 'Cukup (Waspada)';
      case _FCRStatusType.bad:
        return 'Boros (Perhatian)';
    }
  }

  String _getFcrStatusDescription(_FCRStatusType status) {
    switch (status) {
      case _FCRStatusType.good:
        return 'Penggunaan pakan sangat hemat dan efisien. Bobot ayam bertambah optimal.';
      case _FCRStatusType.warn:
        return 'Rasio pakan mendekati batas toleransi. Periksa pakan tercecer atau suhu kandang.';
      case _FCRStatusType.bad:
        return 'FCR tinggi (boros pakan). Segera periksa kesehatan ayam dan efisiensi ransum pakan.';
    }
  }

  Color _getFcrStatusTextColor(_FCRStatusType status) {
    switch (status) {
      case _FCRStatusType.good:
        return AppColors.fcrGoodText;
      case _FCRStatusType.warn:
        return AppColors.fcrWarnText;
      case _FCRStatusType.bad:
        return AppColors.fcrBadText;
    }
  }

  Color _getFcrStatusBgColor(_FCRStatusType status) {
    switch (status) {
      case _FCRStatusType.good:
        return AppColors.fcrGoodBg;
      case _FCRStatusType.warn:
        return AppColors.fcrWarnBg;
      case _FCRStatusType.bad:
        return AppColors.fcrBadBg;
    }
  }

  IconData _getFcrStatusIcon(_FCRStatusType status) {
    switch (status) {
      case _FCRStatusType.good:
        return Icons.check_circle_rounded;
      case _FCRStatusType.warn:
        return Icons.warning_amber_rounded;
      case _FCRStatusType.bad:
        return Icons.error_outline_rounded;
    }
  }
}

enum _FCRStatusType { good, warn, bad }

/// Kartu FCR Harian yang ringkas dan ramah peternak
class _DailyFCRCard extends StatelessWidget {
  final DailyFCRData data;

  const _DailyFCRCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat.decimalPattern('id_ID');
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

    final status = data.fcr <= 1.80
        ? _FCRStatusType.good
        : (data.fcr <= 2.20 ? _FCRStatusType.warn : _FCRStatusType.bad);

    final statusColor = status == _FCRStatusType.good
        ? AppColors.fcrGoodText
        : (status == _FCRStatusType.warn ? AppColors.fcrWarnText : AppColors.fcrBadText);

    final statusBg = status == _FCRStatusType.good
        ? AppColors.fcrGoodBg
        : (status == _FCRStatusType.warn ? AppColors.fcrWarnBg : AppColors.fcrBadBg);

    final statusLabel = status == _FCRStatusType.good
        ? 'Efisien'
        : (status == _FCRStatusType.warn ? 'Cukup' : 'Boros');

    final dateStr = dateFmt.format(data.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris 1: Hari & Nilai FCR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hari ke-${data.day}',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    child: Text(
                      'FCR ${fmt.format(data.fcr)} • $statusLabel',
                      style: tt.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Baris 2: Metrik Fisik (Pakan Hari Ini, Bobot, Mati, Sisa)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMiniMetric(
                        label: 'Pakan Hari Ini',
                        value: '${fmt.format(data.dailyFeedKg)} kg',
                        sub: '${(data.dailyFeedKg / 50).toStringAsFixed(1)} sak',
                        tt: tt,
                        cs: cs,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniMetric(
                        label: 'Bobot Sampling',
                        value: '${fmt.format(data.avgWeightGram)} g',
                        sub: 'Rata-rata',
                        tt: tt,
                        cs: cs,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniMetric(
                        label: 'Mati Hari Ini',
                        value: '${data.dailyMortality} ekor',
                        sub: 'Sisa: ${fmt.format(data.sisaAyam)}',
                        tt: tt,
                        cs: cs,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required String sub,
    required TextTheme tt,
    required ColorScheme cs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: tt.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            fontSize: 11.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          sub,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 9.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
