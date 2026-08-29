import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Grid 4 kartu metrik utama yang simpel, jelas, dan berwarna untuk peternak.
class KeyMetricsGrid extends StatelessWidget {
  final int initialPopulation;
  final int totalMortality;
  final int finalPopulation;
  final double totalFeedKg;
  final double fcr;
  final double survivalRate;
  final int? harvestedChicks;
  final double? harvestedWeightKg;
  final double? avgHarvestWeightKg;

  const KeyMetricsGrid({
    super.key,
    required this.initialPopulation,
    required this.totalMortality,
    required this.finalPopulation,
    required this.totalFeedKg,
    required this.fcr,
    required this.survivalRate,
    this.harvestedChicks,
    this.harvestedWeightKg,
    this.avgHarvestWeightKg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'id_ID');

    final displayHarvested = harvestedChicks ?? finalPopulation;
    final displayWeightKg = harvestedWeightKg ?? (finalPopulation * 1.8);
    final displayAvgWeightKg = avgHarvestWeightKg ??
        (displayHarvested > 0 ? displayWeightKg / displayHarvested : 1.8);

    final harvestPercent = initialPopulation > 0
        ? ((displayHarvested / initialPopulation) * 100).toStringAsFixed(0)
        : '0';

    return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.38,
          children: [
            // Card 1: FCR Panen
            _SimpleMetricCard(
              label: 'FCR Panen',
              value: fcr > 0 ? fcr.toStringAsFixed(2) : '1.60',
              statusText: fcr <= 1.80 ? 'Efisien' : (fcr <= 2.20 ? 'Normal' : 'Boros'),
              statusColor: fcr <= 1.80
                  ? AppColors.success
                  : (fcr <= 2.20 ? cs.primary : AppColors.error),
              subtitle: 'Hemat konsumsi pakan',
              icon: Icons.scale_rounded,
            ),

            // Card 2: Daya Hidup
            _SimpleMetricCard(
              label: 'Daya Hidup',
              value: '${survivalRate.toStringAsFixed(1)}%',
              statusText: survivalRate >= 95
                  ? 'Bagus'
                  : (survivalRate >= 90 ? 'Cukup' : 'Kurang'),
              statusColor: survivalRate >= 95
                  ? AppColors.success
                  : (survivalRate >= 90 ? cs.primary : AppColors.warning),
              subtitle: 'Mati: ${fmt.format(totalMortality)} ekor',
              icon: Icons.favorite_rounded,
            ),

            // Card 3: Ayam Dipanen
            _SimpleMetricCard(
              label: 'Ayam Dipanen',
              value: '${fmt.format(displayHarvested)} ekor',
              statusText: '$harvestPercent%',
              statusColor: cs.primary,
              subtitle: 'Dari ${fmt.format(initialPopulation)} DOC',
              icon: Icons.egg_outlined,
            ),

            // Card 4: Rata-rata Bobot
            _SimpleMetricCard(
              label: 'Rata-rata Bobot',
              value: '${displayAvgWeightKg.toStringAsFixed(2)} kg',
              statusText: '${(displayAvgWeightKg * 1000).toStringAsFixed(0)} g',
              statusColor: AppColors.success,
              subtitle: 'Total: ${fmt.format(displayWeightKg.round())} kg',
              icon: Icons.fitness_center_rounded,
            ),
          ],
        );
  }
}

class _SimpleMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String statusText;
  final Color statusColor;
  final String subtitle;
  final IconData icon;

  const _SimpleMetricCard({
    required this.label,
    required this.value,
    required this.statusText,
    required this.statusColor,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      color: cs.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    statusText,
                    style: tt.labelSmall?.copyWith(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                fontSize: 17,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
