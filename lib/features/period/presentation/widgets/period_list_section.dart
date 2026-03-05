import 'package:flutter/material.dart';
import '../../data/models/period_data.dart';
import 'period_card.dart';

class PeriodListSection extends StatelessWidget {
  final List<PeriodData> periods;
  final VoidCallback? onSeeAllTap;
  final void Function(PeriodData)? onPeriodTap;

  const PeriodListSection({
    super.key,
    required this.periods,
    this.onSeeAllTap,
    this.onPeriodTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semua Periode',
              style: tt.titleSmall?.copyWith(color: cs.onBackground),
            ),
            GestureDetector(
              onTap: onSeeAllTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'lihat semua',
                  style: tt.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (periods.isEmpty)
          const PeriodEmptyState()
        else
          ...periods.map((p) => PeriodCard(period: p, onTap: onPeriodTap)),
      ],
    );
  }
}

class PeriodEmptyState extends StatelessWidget {
  const PeriodEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 36, color: cs.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Belum ada periode',
            style: tt.bodyMedium?.copyWith(color: cs.outlineVariant),
          ),
        ],
      ),
    );
  }
}
