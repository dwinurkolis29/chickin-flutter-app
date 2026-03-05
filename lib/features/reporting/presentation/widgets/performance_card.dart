import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/presentation/widgets/section_card.dart';

class PerformanceCard extends StatelessWidget {
  final PeriodReport report;

  const PerformanceCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Performa',
      icon: Icons.speed_outlined,
      children: [
        MetricRow(
          label: 'Total Pakan',
          value: '${NumberFormat('#,###.##').format(report.totalFeedKg)} kg',
        ),
        MetricRow(
          label: 'Bobot Rata-rata Akhir',
          value: '${NumberFormat('#,###').format(report.finalAvgWeightGram)} g',
        ),
        MetricRow(
          label: 'Total Biomassa',
          value: '${NumberFormat('#,###.##').format(report.totalBiomassKg)} kg',
        ),
        MetricRow(
          label: 'Pertambahan Bobot',
          value: '${NumberFormat('#,###.##').format(report.weightGainKg)} kg',
        ),
        MetricRow(
          label: 'FCR',
          value: report.fcr.toStringAsFixed(2),
        ),
      ],
    );
  }
}
