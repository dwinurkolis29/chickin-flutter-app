import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';

/// Kalkulasi derived analytics dari [PeriodSnapshot].
///
/// Dipisah dari [SummaryCalculator] karena:
/// - Tidak butuh akses ke recordings mentah
/// - Bisa dipakai ulang di reporting UI tanpa re-fetch data
class AnalyticsResult {
  final double mortalityRate; // persen
  final double survivalRate; // persen
  final double feedPerBird; // kg/ekor
  final int initialPopulation;

  const AnalyticsResult({
    required this.mortalityRate,
    required this.survivalRate,
    required this.feedPerBird,
    required this.initialPopulation,
  });
}

class AnalyticsCalculator {
  AnalyticsResult execute(PeriodSnapshot snapshot, int initialPopulation) {
    final mortalityRate = initialPopulation > 0
        ? (snapshot.totalMortality / initialPopulation) * 100
        : 0.0;

    final survivalRate = initialPopulation > 0
        ? (snapshot.finalPopulation / initialPopulation) * 100
        : 0.0;

    final feedPerBird = snapshot.finalPopulation > 0
        ? snapshot.totalFeedKg / snapshot.finalPopulation
        : 0.0;

    return AnalyticsResult(
      mortalityRate: mortalityRate,
      survivalRate: survivalRate,
      feedPerBird: feedPerBird,
      initialPopulation: initialPopulation,
    );
  }
}
