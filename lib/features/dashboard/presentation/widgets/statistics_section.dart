import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/features/recording/presentation/pages/chicken_weight_screen.dart';

class StatisticsSection extends StatelessWidget {
  final double fcr;
  final int umur;
  final Stream<List<FlSpot>>? weightStream;

  const StatisticsSection({
    super.key,
    required this.fcr,
    required this.umur,
    required this.weightStream,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: WeightChartCard(weightStream: weightStream),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.calendar_today,
                    label: 'Umur\nAyam',
                    value: '$umur',
                    unit: 'Hari',
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.percent,
                    label: 'FCR',
                    value: '$fcr',
                    unit: 'Ratio',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeightChartCard extends StatelessWidget {
  final Stream<List<FlSpot>>? weightStream;
  final VoidCallback? onTap;

  const WeightChartCard({
    super.key,
    required this.weightStream,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChickenWeightScreen(),
                ),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: weightStream == null
              ? Center(
                  child: Text(
                    'Belum ada periode aktif',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : StreamBuilder<List<FlSpot>>(
                  stream: weightStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final flSpot = snapshot.data ?? [];

                      // Cek apakah data bobot ayam kosong
                      if (flSpot.isEmpty) {
                        return Center(
                          child: Text(
                            'Data recording belum diisi',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      // Ambil data bobot terakhir untuk ditampilkan
                      final lastWeight = flSpot.last.y;
                      final isIncreasing = flSpot.length >= 2
                          ? flSpot.last.y > flSpot[flSpot.length - 2].y
                          : true;
                      final chartColor =
                          isIncreasing ? AppColors.success : AppColors.error;
                      final diff = flSpot.length >= 2
                          ? (flSpot.last.y - flSpot[flSpot.length - 2].y).round()
                          : null;

                      return Column(
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
                                child: Icon(
                                  Icons.show_chart,
                                  color: cs.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bobot Ayam',
                                  style: tt.labelMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 70,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: flSpot,
                                    isCurved: true,
                                    color: chartColor,
                                    barWidth: 3.5,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          chartColor.withValues(alpha: 0.22),
                                          chartColor.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${lastWeight % 1 == 0 ? lastWeight.toInt() : lastWeight}',
                                style: tt.titleLarge?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Gram',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (diff != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chartColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isIncreasing
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 11,
                                        color: chartColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${isIncreasing ? '+' : ''}$diff g',
                                        style: tt.labelSmall?.copyWith(
                                          color: chartColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: cs.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: tt.labelMedium?.copyWith(height: 1.2),
                  maxLines: 2,
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
                fit: FlexFit.loose,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: tt.titleLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
