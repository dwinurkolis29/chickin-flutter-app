import 'package:flutter/material.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
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
              style: tt.titleSmall?.copyWith(color: cs.onSurface),
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
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const AppEmptyState(
              icon: Icons.layers_outlined,
              message: 'Belum ada periode',
              compact: true,
            ),
          )
        else
          ...periods.map((p) => PeriodCard(period: p, onTap: onPeriodTap)),
      ],
    );
  }
}
