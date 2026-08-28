import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/recording/data/models/daily_adg_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_adg.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';

/// Screen visualisasi lengkap grafik pertumbuhan bobot ayam harian dari Hari 1 hingga hari terakhir pengisian.
class ChickenWeightScreen extends StatefulWidget {
  final List<RecordingData>? recordings;

  const ChickenWeightScreen({super.key, this.recordings});

  @override
  State<ChickenWeightScreen> createState() => _ChickenWeightScreenState();
}

class _ChickenWeightScreenState extends State<ChickenWeightScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.recordings == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RecordingController>().loadActivePeriod();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecordingController>();

    return Scaffold(
      appBar: const AppHeader(title: 'Pertumbuhan Bobot Ayam'),
      body: widget.recordings != null
          ? _buildContent(context, widget.recordings!)
          : StreamBuilder<List<RecordingData>>(
              stream: controller.recordingsStream,
              builder: (context, snapshot) {
                if (controller.isLoadingPeriod ||
                    (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData)) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recordings = snapshot.data ?? [];
                return _buildContent(context, recordings);
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, List<RecordingData> recordings) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Filter data recording dengan bobot > 0 dan urutkan berdasarkan hari
    final validRecordings = recordings
        .where((r) => r.avgWeightGram > 0)
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    if (validRecordings.isEmpty) {
      return AppEmptyState(
        icon: Icons.scale_outlined,
        message: 'Belum Ada Data Penimbangan',
        subtitle:
            'Grafik dan statistik pertumbuhan ADG akan muncul otomatis setelah Anda mencatat rata-rata bobot ayam pada catatan recording harian.',
        actionLabel: 'Kembali ke Catatan',
        actionIcon: Icons.arrow_back_rounded,
        onAction: () => Navigator.pop(context),
      );
    }

    // Perhitungan statistik pertumbuhan
    final firstRecording = validRecordings.first;
    final latestRecording = validRecordings.last;
    final firstWeight = firstRecording.avgWeightGram;
    final latestWeight = latestRecording.avgWeightGram;
    final totalGain = latestWeight - firstWeight;
    final daySpan = (latestRecording.day - firstRecording.day).clamp(1, 999);
    final adg = totalGain / daySpan; // Average Daily Gain (gr/hari)

    // Data spot untuk fl_chart
    final spots = validRecordings
        .map((r) => FlSpot(r.day.toDouble(), r.avgWeightGram.toDouble()))
        .toList();

    final maxY = (latestWeight * 1.15).ceilToDouble();
    final maxX = (latestRecording.day >= 7 ? latestRecording.day.toDouble() : 7.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Hero Ringkasan Statistik ──────────────────────────────────
          _buildMetricsSection(
            cs: cs,
            tt: tt,
            latestWeight: latestWeight,
            latestDay: latestRecording.day,
            totalGain: totalGain,
            adg: adg,
          ),
          const SizedBox(height: 16),

          // ── 2. Kartu Grafik Pertumbuhan Interaktif ────────────────────────
          _buildChartCard(
            context: context,
            cs: cs,
            tt: tt,
            spots: spots,
            maxX: maxX,
            maxY: maxY,
            validRecordings: validRecordings,
          ),
          const SizedBox(height: 20),

          // ── 3. Riwayat Kenaikan Bobot Harian ─────────────────────────────
          _buildHistorySection(
            context: context,
            cs: cs,
            tt: tt,
            validRecordings: validRecordings,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Grid ringkasan metrik bobot terkini, kenaikan total, dan ADG.
  Widget _buildMetricsSection({
    required ColorScheme cs,
    required TextTheme tt,
    required int latestWeight,
    required int latestDay,
    required int totalGain,
    required double adg,
  }) {
    final numberFmt = NumberFormat('#,###');

    return Row(
      children: [
        // Bobot Terakhir
        Expanded(
          flex: 3,
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.scale_rounded, size: 16, color: cs.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bobot Terakhir',
                        style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          numberFmt.format(latestWeight),
                          style: tt.titleLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Gram',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Hari ke-$latestDay (${(latestWeight / 1000).toStringAsFixed(2)} Kg)',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // ADG (Rata-rata Kenaikan Harian)
        Expanded(
          flex: 2,
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.trending_up_rounded, size: 16, color: cs.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rata-rata',
                        style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '+${adg.toStringAsFixed(1)}',
                          style: tt.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'g/hr',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ADG harian',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu grafik lengkap dengan styling FlChart Material 3 Vivid Blue.
  Widget _buildChartCard({
    required BuildContext context,
    required ColorScheme cs,
    required TextTheme tt,
    required List<FlSpot> spots,
    required double maxX,
    required double maxY,
    required List<RecordingData> validRecordings,
  }) {
    final numberFmt = NumberFormat('#,###');

    // Interval title sumbu X (Hari)
    final double xInterval = maxX <= 7 ? 1.0 : (maxX <= 21 ? 3.0 : 7.0);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.show_chart_rounded, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kurva Pertumbuhan Bobot',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Umur 1 s.d. ${validRecordings.last.day} Hari (Satuan Gram)',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Area LineChart
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 1000 ? 500 : 200,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      interval: maxY > 1000 ? 500 : 200,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${numberFmt.format(value.toInt())} g',
                          style: tt.bodySmall?.copyWith(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'H${value.toInt()}',
                            style: tt.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => cs.inverseSurface,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        return LineTooltipItem(
                          'Hari ${barSpot.x.toInt()}\n',
                          tt.bodySmall?.copyWith(
                            color: cs.onInverseSurface.withValues(alpha: 0.8),
                            fontSize: 11,
                          ) ?? const TextStyle(),
                          children: [
                            TextSpan(
                              text: '${numberFmt.format(barSpot.y.toInt())} Gram',
                              style: tt.titleSmall?.copyWith(
                                color: cs.onInverseSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: cs.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4.0,
                          color: cs.surface,
                          strokeWidth: 2.5,
                          strokeColor: cs.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.primary.withValues(alpha: 0.25),
                          cs.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Riwayat kenaikan bobot harian dalam format kartu simpel & mudah dibaca (terbaru di atas).
  Widget _buildHistorySection({
    required BuildContext context,
    required ColorScheme cs,
    required TextTheme tt,
    required List<RecordingData> validRecordings,
  }) {
    final dailyAdgList = CalculateADG().executeDaily(validRecordings);
    final reversedList = dailyAdgList.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RIWAYAT KENAIKAN BOBOT',
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: cs.primary,
              ),
            ),
            Text(
              '${dailyAdgList.length} Hari Catatan',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reversedList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = reversedList[index];
            return _buildDailyCard(context, item);
          },
        ),
      ],
    );
  }

  Widget _buildDailyCard(BuildContext context, DailyADGData item) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat.decimalPattern('id_ID');
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

    final String statusLabel;
    final Color statusColor;
    final Color statusBg;

    if (item.status == 'Optimal') {
      statusLabel = 'Bagus';
      statusColor = AppColors.success;
      statusBg = AppColors.success.withValues(alpha: 0.12);
    } else if (item.status == 'Standar') {
      statusLabel = 'Normal';
      statusColor = cs.primary;
      statusBg = cs.primary.withValues(alpha: 0.1);
    } else {
      statusLabel = 'Kurang';
      statusColor = AppColors.warning;
      statusBg = AppColors.warning.withValues(alpha: 0.15);
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Hari & Badge Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                      child: Text(
                        'HARI ${item.day}',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFmt.format(item.date),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    statusLabel,
                    style: tt.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Baris 2: Kenaikan & Bobot
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kenaikan Bobot',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.trending_up_rounded, size: 20, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            '+${item.dailyGainGram.toStringAsFixed(0)} g/hari',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bobot Timbang',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${numFmt.format(item.weightGram)} gram',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
