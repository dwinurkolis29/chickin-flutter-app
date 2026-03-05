import 'package:flutter/material.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/presentation/widgets/section_card.dart';

class AnalyticsCard extends StatelessWidget {
  final PeriodReport report;

  const AnalyticsCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Analitik',
      icon: Icons.analytics_outlined,
      children: [
        MetricRow(
          label: 'Pertambahan Bobot Harian',
          value: '${report.avgDailyGainGram.toStringAsFixed(1)} g/hari',
        ),
        MetricRow(
          label: 'Pakan per Ekor',
          value: '${report.feedPerBird.toStringAsFixed(3)} kg',
        ),
        MetricRow(
          label: 'Survival Rate',
          value: '${report.survivalRate.toStringAsFixed(1)} %',
        ),
      ],
    );
  }
}
