import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

/// Immutable value object holding all computed metrics for a period report.
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

  // Harvest Data & IP (Indeks Performa)
  final int? harvestedChicks;
  final double? harvestedWeightKg;
  final double? avgHarvestWeightKg;
  final double? ipScore;

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
    this.harvestedChicks,
    this.harvestedWeightKg,
    this.avgHarvestWeightKg,
    this.ipScore,
  });
}
