import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/presentation/widgets/section_card.dart';

class PopulationCard extends StatelessWidget {
  final PeriodReport report;

  const PopulationCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SectionCard(
      title: 'Populasi',
      icon: Icons.pets_outlined,
      children: [
        MetricRow(
          label: 'Populasi Awal',
          value: _fmt(report.initialPopulation),
        ),
        MetricRow(
          label: 'Total Mati',
          value: _fmt(report.totalMortality),
        ),
        MetricRow(
          label: 'Populasi Akhir',
          value: _fmt(report.finalPopulation),
        ),
        MetricRow(
          label: 'Mortality Rate',
          value: '${report.mortalityRate.toStringAsFixed(1)} %',
        ),
      ],
    );
  }

  String _fmt(int n) => NumberFormat('#,###').format(n);
}
