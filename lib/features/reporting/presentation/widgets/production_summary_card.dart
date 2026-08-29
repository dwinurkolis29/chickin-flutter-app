import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Kartu ringkasan total produksi peternakan dalam format yang rapi dan mudah dibaca.
class ProductionSummaryCard extends StatelessWidget {
  final double totalFeedKg;
  final double totalBiomassKg;
  final double avgDailyGainGram;
  final double feedPerBird;
  final int durationDays;

  const ProductionSummaryCard({
    super.key,
    required this.totalFeedKg,
    required this.totalBiomassKg,
    required this.avgDailyGainGram,
    required this.feedPerBird,
    required this.durationDays,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final numFmt = NumberFormat('#,###', 'id_ID');

    final feedSacks = (totalFeedKg / 50).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      color: cs.surfaceContainerLowest,
      child: Padding(
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
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ringkasan Data Produksi',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SummaryRow(
              label: 'Total Pakan Dikonsumsi',
              value: '${numFmt.format(totalFeedKg.round())} kg',
              sub: '$feedSacks sak (isi 50 kg)',
            ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'Total Bobot Daging Panen',
              value: '${numFmt.format(totalBiomassKg.round())} kg',
              sub: 'Total biomassa',
            ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'Pertambahan Bobot Harian (ADG)',
              value: '${avgDailyGainGram.toStringAsFixed(1)} g / hari',
              sub: 'Rata-rata kenaikan harian',
            ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'Konsumsi Pakan per Ekor',
              value: '${feedPerBird.toStringAsFixed(2)} kg / ekor',
              sub: 'Rata-rata konsumsi per ayam',
            ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'Durasi Pemeliharaan',
              value: '$durationDays Hari',
              sub: 'Lama siklus hingga panen',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              sub,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
