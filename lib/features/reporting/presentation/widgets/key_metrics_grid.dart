import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Data holder untuk satu tile metric.
class MetricItem {
  final String label;
  final String value;
  final IconData icon;

  const MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// Grid 2 kolom menampilkan 5 key metrics ringkas.
/// Tidak pakai SectionCard — layout grid ini beda dari list row.
class KeyMetricsGrid extends StatelessWidget {
  final int initialPopulation;
  final int totalMortality;
  final int finalPopulation;
  final double totalFeedKg;
  final double fcr;
  final double survivalRate;

  const KeyMetricsGrid({
    super.key,
    required this.initialPopulation,
    required this.totalMortality,
    required this.finalPopulation,
    required this.totalFeedKg,
    required this.fcr,
    required this.survivalRate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,###');

    final metrics = [
      MetricItem(
        label: 'Total Pakan',
        value: '${NumberFormat('#,###.#').format(totalFeedKg)} kg',
        icon: Icons.set_meal_outlined,
      ),
      MetricItem(
        label: 'Total Mati',
        value: fmt.format(totalMortality),
        icon: Icons.remove_circle_outline,
      ),
      MetricItem(
        label: 'Populasi Akhir',
        value: fmt.format(finalPopulation),
        icon: Icons.group_outlined,
      ),
      MetricItem(
        label: 'FCR',
        value: fcr > 0 ? fcr.toStringAsFixed(2) : '-',
        icon: Icons.show_chart_rounded,
      ),
      MetricItem(
        label: 'Survival Rate',
        value: '${survivalRate.toStringAsFixed(1)}%',
        icon: Icons.favorite_outline_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Key Metrics',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, i) => _MetricTile(item: metrics[i]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final MetricItem item;
  const _MetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.value,
                  style: tt.titleSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
