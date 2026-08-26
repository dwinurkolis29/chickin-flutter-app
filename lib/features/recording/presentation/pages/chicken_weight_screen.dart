import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
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
      return const AppEmptyState(
        icon: Icons.show_chart_rounded,
        message: 'Belum Ada Data Bobot',
        subtitle:
            'Data grafik pertumbuhan bobot akan muncul secara otomatis setelah Anda mengisi penimbangan bobot ayam pada catatan harian.',
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

          // ── 3. Tabel Riwayat Penimbangan Bobot Harian ─────────────────────
          _buildHistorySection(
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

  /// Riwayat penimbangan harian per baris dalam format list (ascending: Hari 1 teratas).
  Widget _buildHistorySection({
    required ColorScheme cs,
    required TextTheme tt,
    required List<RecordingData> validRecordings,
  }) {
    final numberFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd MMM yyyy');

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Bobot Harian',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total ${validRecordings.length} data penimbangan tercatat',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: validRecordings.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              // Urutan tampil ascending dari hari 1 s.d. hari terakhir
              final recording = validRecordings[index];
              final int? prevWeight =
                  index > 0 ? validRecordings[index - 1].avgWeightGram : null;
              final int? diff =
                  prevWeight != null ? recording.avgWeightGram - prevWeight : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Badge Hari
                    Container(
                      width: 54,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      ),
                      child: Center(
                        child: Text(
                          'H-${recording.day}',
                          style: tt.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Detail Bobot dan Tanggal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${numberFmt.format(recording.avgWeightGram)} Gram',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFmt.format(recording.createdAt),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kenaikan vs Hari Sebelumnya
                    if (diff != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: diff >= 0
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              diff >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 12,
                              color: diff >= 0 ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${diff >= 0 ? '+' : ''}$diff g',
                              style: tt.labelSmall?.copyWith(
                                color: diff >= 0 ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Text(
                          'Awal (DOC)',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
