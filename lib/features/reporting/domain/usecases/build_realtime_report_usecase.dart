import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/analytics_calculator.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';

/// Membangun [PeriodReport] dari recordings secara realtime.
///
/// Digunakan oleh [ReportingController] ketika:
/// - Period masih aktif (belum punya snapshot di Firebase), atau
/// - Snapshot belum tersedia karena periode lama dibuat sebelum refactor.
///
/// Output-nya identik dengan [BuildReportSnapshotUseCase] agar UI tidak perlu tahu
/// dari mana data berasal.
class BuildRealtimeReportUseCase {
  final SummaryCalculator _summaryCalculator;
  final AnalyticsCalculator _analyticsCalculator;

  BuildRealtimeReportUseCase({
    SummaryCalculator? summaryCalculator,
    AnalyticsCalculator? analyticsCalculator,
  })  : _summaryCalculator = summaryCalculator ?? SummaryCalculator(),
        _analyticsCalculator = analyticsCalculator ?? AnalyticsCalculator();

  PeriodReport execute(PeriodData period, List<RecordingData> recordings) {
    final snapshot = _summaryCalculator.execute(period, recordings);
    final analytics = _analyticsCalculator.execute(snapshot, period.initialCapacity);

    return PeriodReport(
      period: period,
      recordings: recordings,
      initialPopulation: period.initialCapacity,
      totalMortality: snapshot.totalMortality,
      finalPopulation: snapshot.finalPopulation,
      mortalityRate: analytics.mortalityRate,
      totalFeedKg: snapshot.totalFeedKg,
      finalAvgWeightGram: snapshot.finalAvgWeightGram,
      totalBiomassKg: snapshot.finalBiomassKg,
      weightGainKg: (snapshot.finalBiomassKg - period.initialCapacity * period.initialWeight)
          .clamp(0.0, double.infinity),
      fcr: snapshot.finalFCR,
      avgDailyGainGram: snapshot.avgDailyGain,
      feedPerBird: analytics.feedPerBird,
      survivalRate: analytics.survivalRate,
      durationDays: snapshot.durationDays,
    );
  }
}
