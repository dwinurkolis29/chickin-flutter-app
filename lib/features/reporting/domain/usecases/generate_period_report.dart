import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';

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

/// Computes all report KPIs from a [PeriodData] and its [List<RecordingData>].
///
/// FCR is delegated to [CalculateFCR] (same formula used throughout the app).
/// Falls back to [PeriodSummary] values when recordings is empty.
class GeneratePeriodReport {
  final CalculateFCR _calculateFCR;

  GeneratePeriodReport({CalculateFCR? calculateFCR})
      : _calculateFCR = calculateFCR ?? CalculateFCR();

  PeriodReport execute(PeriodData period, List<RecordingData> recordings) {
    final int initialPopulation = period.initialCapacity;

    // ── Duration ───────────────────────────────────────────────────────────────
    final endDate = period.endDate ?? DateTime.now();
    final durationDays =
        endDate.difference(period.startDate).inDays.clamp(1, 9999);

    // ── Fallback: use summary when no recordings available ─────────────────────
    if (recordings.isEmpty && period.summary != null) {
      final s = period.summary!;
      final totalMortality = s.totalMortality;
      final finalPopulation = s.finalPopulation;
      final totalFeedKg = s.totalFeedKg;
      final totalBiomassKg = s.finalBiomass;
      final initBiomass = initialPopulation * period.initialWeight;
      final weightGainKg =
          (totalBiomassKg - initBiomass).clamp(0.0, double.infinity);
      final mortalityRate = initialPopulation > 0
          ? (totalMortality / initialPopulation) * 100
          : 0.0;
      final survivalRate = initialPopulation > 0
          ? (finalPopulation / initialPopulation) * 100
          : 0.0;
      final feedPerBird =
          finalPopulation > 0 ? totalFeedKg / finalPopulation : 0.0;
      // avgDailyGain from summary
      final avgDailyGainGram = s.avgDailyGain;

      return PeriodReport(
        period: period,
        recordings: recordings,
        initialPopulation: initialPopulation,
        totalMortality: totalMortality,
        finalPopulation: finalPopulation,
        mortalityRate: mortalityRate,
        totalFeedKg: totalFeedKg,
        finalAvgWeightGram: (totalBiomassKg > 0 && finalPopulation > 0)
            ? ((totalBiomassKg / finalPopulation) * 1000).round()
            : 0,
        totalBiomassKg: totalBiomassKg,
        weightGainKg: weightGainKg,
        fcr: s.finalFCR,
        avgDailyGainGram: avgDailyGainGram,
        feedPerBird: feedPerBird,
        survivalRate: survivalRate,
        durationDays: durationDays,
      );
    }

    // ── Compute from recordings ────────────────────────────────────────────────
    final sorted = List<RecordingData>.from(recordings)
      ..sort((a, b) => a.day.compareTo(b.day));

    int totalMortality = 0;
    int totalFeedSacks = 0;
    for (final r in sorted) {
      totalMortality += r.mortality;
      totalFeedSacks += r.feedSack;
    }

    final finalPopulation =
        (initialPopulation - totalMortality).clamp(0, initialPopulation);
    final totalFeedKg = totalFeedSacks * 50.0;
    final finalAvgWeightGram =
        sorted.isNotEmpty ? sorted.last.avgWeightGram : 0;
    final totalBiomassKg = finalPopulation * finalAvgWeightGram / 1000.0;
    final initBiomassKg = initialPopulation * period.initialWeight;
    final weightGainKg =
        (totalBiomassKg - initBiomassKg).clamp(0.0, double.infinity);
    final mortalityRate = initialPopulation > 0
        ? (totalMortality / initialPopulation) * 100
        : 0.0;
    final survivalRate = initialPopulation > 0
        ? (finalPopulation / initialPopulation) * 100
        : 0.0;
    final feedPerBird =
        finalPopulation > 0 ? totalFeedKg / finalPopulation : 0.0;

    // initialWeight is in kg (default 0.4 kg = 400 g)
    final initialWeightGram = period.initialWeight * 1000;
    final avgDailyGainGram = durationDays > 0
        ? (finalAvgWeightGram - initialWeightGram) / durationDays
        : 0.0;

    // FCR: delegate to CalculateFCR, use last entry's cumulative FCR
    double fcr = 0.0;
    if (initialPopulation > 0) {
      final weeklyFCR = _calculateFCR.execute(sorted, initialPopulation);
      if (weeklyFCR.isNotEmpty) {
        fcr = weeklyFCR.last.fcr;
      }
    }

    return PeriodReport(
      period: period,
      recordings: sorted,
      initialPopulation: initialPopulation,
      totalMortality: totalMortality,
      finalPopulation: finalPopulation,
      mortalityRate: mortalityRate,
      totalFeedKg: totalFeedKg,
      finalAvgWeightGram: finalAvgWeightGram,
      totalBiomassKg: totalBiomassKg,
      weightGainKg: weightGainKg,
      fcr: fcr,
      avgDailyGainGram: avgDailyGainGram,
      feedPerBird: feedPerBird,
      survivalRate: survivalRate,
      durationDays: durationDays,
    );
  }
}
