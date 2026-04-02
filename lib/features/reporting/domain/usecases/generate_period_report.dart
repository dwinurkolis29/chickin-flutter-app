import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

/// Immutable value object holding all computed metrics for a period report.
///
/// Dihasilkan oleh:
/// - [BuildReportSnapshotUseCase] → untuk periode closed (pakai PeriodSummary)
/// - [BuildRealtimeReportUseCase] → untuk periode aktif atau data lama
class PeriodReport {
  final PeriodData period;
  final List<RecordingData> recordings;

  // Population
  final int initialPopulation;
  final int totalMortality;
  final int finalPopulation;
  final double mortalityRate;

  // Performance
  final double totalFeedKg;
  final int finalAvgWeightGram;
  final double totalBiomassKg;
  final double weightGainKg;
  final double fcr;

  // Analytics
  final double avgDailyGainGram;
  final double feedPerBird;
  final double survivalRate;

  // Meta
  final int durationDays;

  const PeriodReport({
    required this.period,
    required this.recordings,
    required this.initialPopulation,
    required this.totalMortality,
    required this.finalPopulation,
    required this.mortalityRate,
    required this.totalFeedKg,
    required this.finalAvgWeightGram,
    required this.totalBiomassKg,
    required this.weightGainKg,
    required this.fcr,
    required this.avgDailyGainGram,
    required this.feedPerBird,
    required this.survivalRate,
    required this.durationDays,
  });
}
