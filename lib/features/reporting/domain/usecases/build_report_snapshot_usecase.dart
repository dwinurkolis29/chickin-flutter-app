import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/analytics_calculator.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';

/// Membangun [PeriodReport] dari snapshot yang sudah disimpan di [PeriodSummary].
///
/// Digunakan oleh [ReportingController] ketika periode sudah closed dan memiliki
/// summary yang valid di Firebase (periode ditutup setelah refactor ini).
///
/// Tidak perlu fetch recordings — semua angka sudah ada di [PeriodSummary].
class BuildReportSnapshotUseCase {
  final AnalyticsCalculator _analyticsCalculator;

  BuildReportSnapshotUseCase({AnalyticsCalculator? analyticsCalculator})
      : _analyticsCalculator = analyticsCalculator ?? AnalyticsCalculator();

  PeriodReport execute(PeriodData period) {
    final s = period.summary ?? const PeriodSummary();
    final initialPopulation = period.initialCapacity;

    // Re-derive snapshot shape untuk AnalyticsCalculator
    final snapshot = PeriodSnapshot(
      totalFeedKg: s.totalFeedKg,
      finalPopulation: s.finalPopulation,
      totalMortality: s.totalMortality,
      finalBiomassKg: s.finalBiomass,
      finalAvgWeightGram: s.finalPopulation > 0 && s.finalBiomass > 0
          ? ((s.finalBiomass / s.finalPopulation) * 1000).round()
          : 0,
      finalFCR: s.finalFCR,
      avgDailyGain: s.avgDailyGain,
      durationDays: _computeDuration(period),
      weeklyFCR: s.weeklyFCR,
    );

    final analytics = _analyticsCalculator.execute(snapshot, initialPopulation);

    final initBiomass = initialPopulation * period.initialWeight;
    final weightGainKg =
        (s.finalBiomass - initBiomass).clamp(0.0, double.infinity);

    final computedIP = (s.ipScore != null && s.ipScore! > 0)
        ? s.ipScore
        : (snapshot.durationDays > 0 && s.finalFCR > 0 && analytics.survivalRate > 0 && snapshot.finalAvgWeightGram > 0
            ? ((analytics.survivalRate * (snapshot.finalAvgWeightGram / 1000.0) * 100.0) / (snapshot.durationDays * s.finalFCR))
            : null);

    return PeriodReport(
      period: period,
      recordings: const [],
      initialPopulation: initialPopulation,
      totalMortality: s.totalMortality,
      finalPopulation: s.finalPopulation,
      mortalityRate: analytics.mortalityRate,
      totalFeedKg: s.totalFeedKg,
      finalAvgWeightGram: snapshot.finalAvgWeightGram,
      totalBiomassKg: s.finalBiomass,
      weightGainKg: weightGainKg,
      fcr: s.finalFCR,
      avgDailyGainGram: s.avgDailyGain,
      feedPerBird: analytics.feedPerBird,
      survivalRate: analytics.survivalRate,
      durationDays: snapshot.durationDays,
      harvestedChicks: s.harvestedChicks,
      harvestedWeightKg: s.harvestedWeightKg,
      avgHarvestWeightKg: s.avgHarvestWeightKg,
      ipScore: computedIP,
    );
  }

  int _computeDuration(PeriodData period) {
    final end = period.endDate ?? DateTime.now();
    return end.difference(period.startDate).inDays.clamp(1, 9999);
  }
}
