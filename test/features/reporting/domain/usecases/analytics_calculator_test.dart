import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/reporting/domain/usecases/analytics_calculator.dart';
import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

// ─── Helper: buat PeriodSnapshot manual ─────────────────────────────────────
PeriodSnapshot snapshot({
  double totalFeedKg = 0,
  int finalPopulation = 0,
  int totalMortality = 0,
  double finalBiomassKg = 0,
  int finalAvgWeightGram = 0,
  double finalFCR = 0,
  double avgDailyGain = 0,
  int durationDays = 35,
  List<WeeklyFCR> weeklyFCR = const [],
}) {
  return PeriodSnapshot(
    totalFeedKg: totalFeedKg,
    finalPopulation: finalPopulation,
    totalMortality: totalMortality,
    finalBiomassKg: finalBiomassKg,
    finalAvgWeightGram: finalAvgWeightGram,
    finalFCR: finalFCR,
    avgDailyGain: avgDailyGain,
    durationDays: durationDays,
    weeklyFCR: weeklyFCR,
  );
}

void main() {
  late AnalyticsCalculator calculator;

  setUp(() {
    calculator = AnalyticsCalculator();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AnalyticsCalculator.execute
  // ─────────────────────────────────────────────────────────────────────────
  group('AnalyticsCalculator.execute', () {
    group('happy path — skenario realistis', () {
      // 1000 ekor awal, 18 mati, 982 sisa, feed 5900 kg
      // mortalityRate = (18 / 1000) × 100 = 1.8%
      // survivalRate = (982 / 1000) × 100 = 98.2%
      // feedPerBird = 5900 / 982 ≈ 6.01 kg/ekor

      late PeriodSnapshot snap;

      setUp(() {
        snap = snapshot(
          totalFeedKg: 5900.0,
          finalPopulation: 982,
          totalMortality: 18,
        );
      });

      test('mortalityRate = 1.8%', () {
        final result = calculator.execute(snap, 1000);
        expect(result.mortalityRate, closeTo(1.8, 0.01));
      });

      test('survivalRate = 98.2%', () {
        final result = calculator.execute(snap, 1000);
        expect(result.survivalRate, closeTo(98.2, 0.01));
      });

      test('feedPerBird ≈ 6.01 kg', () {
        final result = calculator.execute(snap, 1000);
        expect(result.feedPerBird, closeTo(5900.0 / 982, 0.01));
      });

      test('initialPopulation di-forward ke result', () {
        final result = calculator.execute(snap, 1000);
        expect(result.initialPopulation, 1000);
      });

      test('mortalityRate + survivalRate ≈ 100%', () {
        final result = calculator.execute(snap, 1000);
        expect(result.mortalityRate + result.survivalRate, closeTo(100.0, 0.01));
      });
    });

    group('zero initialPopulation', () {
      test('initialPopulation = 0 → mortalityRate = 0.0', () {
        final s = snapshot(totalMortality: 50, finalPopulation: 0);
        final result = calculator.execute(s, 0);
        expect(result.mortalityRate, 0.0);
      });

      test('initialPopulation = 0 → survivalRate = 0.0', () {
        final s = snapshot(finalPopulation: 0);
        final result = calculator.execute(s, 0);
        expect(result.survivalRate, 0.0);
      });

      test('initialPopulation = 0 → feedPerBird fallback ke 0.0', () {
        // finalPopulation = 0 juga → feedPerBird = 0
        final s = snapshot(totalFeedKg: 5000.0, finalPopulation: 0);
        final result = calculator.execute(s, 0);
        expect(result.feedPerBird, 0.0);
      });
    });

    group('zero finalPopulation — semua mati', () {
      test('finalPopulation = 0 → feedPerBird = 0.0', () {
        final s = snapshot(totalFeedKg: 3000.0, finalPopulation: 0, totalMortality: 500);
        final result = calculator.execute(s, 500);
        expect(result.feedPerBird, 0.0);
      });

      test('finalPopulation = 0, mortalityRate = 100%', () {
        final s = snapshot(finalPopulation: 0, totalMortality: 1000);
        final result = calculator.execute(s, 1000);
        expect(result.mortalityRate, closeTo(100.0, 0.01));
        expect(result.survivalRate, closeTo(0.0, 0.01));
      });
    });

    group('zero mortality — tidak ada kematian', () {
      test('mortalityRate = 0%', () {
        final s = snapshot(finalPopulation: 1000, totalMortality: 0);
        final result = calculator.execute(s, 1000);
        expect(result.mortalityRate, 0.0);
      });

      test('survivalRate = 100%', () {
        final s = snapshot(finalPopulation: 1000, totalMortality: 0);
        final result = calculator.execute(s, 1000);
        expect(result.survivalRate, closeTo(100.0, 0.01));
      });
    });

    group('boundary — 1 ekor sisa', () {
      test('1 ekor sisa dari 1000 — feedPerBird = totalFeedKg', () {
        final s = snapshot(totalFeedKg: 5000.0, finalPopulation: 1, totalMortality: 999);
        final result = calculator.execute(s, 1000);
        expect(result.feedPerBird, 5000.0);
        expect(result.mortalityRate, closeTo(99.9, 0.01));
        expect(result.survivalRate, closeTo(0.1, 0.01));
      });
    });

    group('variasi skala kandang', () {
      test('kandang kecil 100 ekor', () {
        final s = snapshot(
          totalFeedKg: 600.0,
          finalPopulation: 95,
          totalMortality: 5,
        );
        final result = calculator.execute(s, 100);
        expect(result.mortalityRate, closeTo(5.0, 0.01));
        expect(result.survivalRate, closeTo(95.0, 0.01));
        expect(result.feedPerBird, closeTo(600.0 / 95, 0.01));
      });

      test('kandang besar 20000 ekor', () {
        final s = snapshot(
          totalFeedKg: 120000.0,
          finalPopulation: 19600,
          totalMortality: 400,
        );
        final result = calculator.execute(s, 20000);
        expect(result.mortalityRate, closeTo(2.0, 0.01));
        expect(result.survivalRate, closeTo(98.0, 0.01));
      });
    });
  });
}
