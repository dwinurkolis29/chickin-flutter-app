import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/reporting/domain/usecases/insight_generator.dart';
import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';

// ─── Helper ────────────────────────────────────────────────────────────────
PeriodSnapshot snap({
  double finalFCR = 0,
  int totalMortality = 0,
  double avgDailyGain = 0,
  int finalPopulation = 1000,
  double totalFeedKg = 0,
}) {
  return PeriodSnapshot(
    totalFeedKg: totalFeedKg,
    finalPopulation: finalPopulation,
    totalMortality: totalMortality,
    finalBiomassKg: 0,
    finalAvgWeightGram: 0,
    finalFCR: finalFCR,
    avgDailyGain: avgDailyGain,
    durationDays: 35,
    weeklyFCR: const <WeeklyFCR>[],
  );
}

void main() {
  late InsightGenerator generator;

  setUp(() {
    generator = InsightGenerator();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // InsightGenerator.execute
  // ─────────────────────────────────────────────────────────────────────────
  group('InsightGenerator.execute', () {
    group('guard — initialPopulation = 0', () {
      test('initialPopulation = 0 → return []', () {
        final result = generator.execute(
          snap(finalFCR: 1.5, totalMortality: 5, avgDailyGain: 55.0),
          0, // initialPopulation
        );
        expect(result, isEmpty);
      });
    });

    // ── FCR insights ────────────────────────────────────────────────────────
    group('FCR insight', () {
      test('FCR = 0 → tidak ada FCR insight', () {
        final result = generator.execute(snap(finalFCR: 0), 1000);
        final fcrInsights = result.where((s) => s.contains('FCR')).toList();
        expect(fcrInsights, isEmpty);
      });

      test('FCR ≤ 1.8 (sangat baik) → insight FCR baik', () {
        final result = generator.execute(snap(finalFCR: 1.8), 1000);
        expect(result.any((s) => s.contains('FCR sangat baik')), true);
        expect(result.any((s) => s.contains('1.80')), true);
      });

      test('FCR = 1.5 (baik) → insight FCR baik', () {
        final result = generator.execute(snap(finalFCR: 1.5), 1000);
        expect(result.any((s) => s.contains('FCR sangat baik')), true);
      });

      test('FCR = 1.0 (sangat efisien) → insight FCR baik', () {
        final result = generator.execute(snap(finalFCR: 1.0), 1000);
        expect(result.any((s) => s.contains('FCR sangat baik')), true);
      });

      test('FCR ≥ 2.2 (tinggi) → insight evaluasi pakan', () {
        final result = generator.execute(snap(finalFCR: 2.2), 1000);
        expect(result.any((s) => s.contains('FCR tinggi')), true);
        expect(result.any((s) => s.contains('evaluasi manajemen pakan')), true);
      });

      test('FCR = 3.0 (sangat tinggi) → insight evaluasi pakan', () {
        final result = generator.execute(snap(finalFCR: 3.0), 1000);
        expect(result.any((s) => s.contains('FCR tinggi')), true);
      });

      test('FCR antara 1.8 dan 2.2 (zona abu-abu) → tidak ada FCR insight', () {
        // FCR > 1.8 tapi < 2.2 → tidak masuk kriteria manapun
        final result = generator.execute(snap(finalFCR: 2.0), 1000);
        final fcrInsights = result.where((s) => s.contains('FCR sangat baik') || s.contains('FCR tinggi')).toList();
        expect(fcrInsights, isEmpty);
      });
    });

    // ── Mortality insights ─────────────────────────────────────────────────
    group('Mortality insight', () {
      test('mortalityRate ≤ 5% → mortalitas rendah', () {
        // 1000 ekor, 50 mati = 5.0%
        final result = generator.execute(snap(totalMortality: 50), 1000);
        expect(result.any((s) => s.contains('Mortalitas rendah')), true);
      });

      test('mortalityRate = 0% → mortalitas rendah', () {
        final result = generator.execute(snap(totalMortality: 0), 1000);
        expect(result.any((s) => s.contains('Mortalitas rendah')), true);
        expect(result.any((s) => s.contains('0.0%')), true);
      });

      test('mortalityRate = 1.8% → mortalitas rendah', () {
        // 1000 ekor, 18 mati = 1.8%
        final result = generator.execute(snap(totalMortality: 18), 1000);
        expect(result.any((s) => s.contains('Mortalitas rendah')), true);
        expect(result.any((s) => s.contains('1.8%')), true);
      });

      test('mortalityRate ≥ 10% → mortalitas tinggi', () {
        // 1000 ekor, 100 mati = 10.0%
        final result = generator.execute(snap(totalMortality: 100), 1000);
        expect(result.any((s) => s.contains('Mortalitas tinggi')), true);
        expect(result.any((s) => s.contains('biosekuriti')), true);
      });

      test('mortalityRate = 25% → mortalitas tinggi', () {
        final result = generator.execute(snap(totalMortality: 250), 1000);
        expect(result.any((s) => s.contains('Mortalitas tinggi')), true);
      });

      test('mortalityRate antara 5% dan 10% → tidak ada mortality insight', () {
        // 1000 ekor, 70 mati = 7% — zona abu-abu
        final result = generator.execute(snap(totalMortality: 70), 1000);
        final mortalityInsights = result.where(
          (s) => s.contains('Mortalitas rendah') || s.contains('Mortalitas tinggi'),
        ).toList();
        expect(mortalityInsights, isEmpty);
      });
    });

    // ── ADG insights ─────────────────────────────────────────────────────────
    group('ADG insight', () {
      test('ADG = 0 → tidak ada ADG insight', () {
        final result = generator.execute(snap(avgDailyGain: 0), 1000);
        final adgInsights = result.where((s) => s.contains('Pertumbuhan harian')).toList();
        expect(adgInsights, isEmpty);
      });

      test('ADG ≥ 50 g/hari → pertumbuhan baik', () {
        final result = generator.execute(snap(avgDailyGain: 50.0), 1000);
        expect(result.any((s) => s.contains('Pertumbuhan harian baik')), true);
        expect(result.any((s) => s.contains('50.0 g/hari')), true);
      });

      test('ADG = 70 g/hari → pertumbuhan baik', () {
        final result = generator.execute(snap(avgDailyGain: 70.0), 1000);
        expect(result.any((s) => s.contains('Pertumbuhan harian baik')), true);
      });

      test('ADG < 30 g/hari → pertumbuhan lambat', () {
        final result = generator.execute(snap(avgDailyGain: 25.0), 1000);
        expect(result.any((s) => s.contains('Pertumbuhan harian lambat')), true);
        expect(result.any((s) => s.contains('cek kualitas pakan')), true);
      });

      test('ADG = 10 g/hari → pertumbuhan lambat', () {
        final result = generator.execute(snap(avgDailyGain: 10.0), 1000);
        expect(result.any((s) => s.contains('Pertumbuhan harian lambat')), true);
      });

      test('ADG antara 30 dan 50 → tidak ada ADG insight', () {
        // 40 g/hari — zona abu-abu
        final result = generator.execute(snap(avgDailyGain: 40.0), 1000);
        final adgInsights = result.where((s) => s.contains('Pertumbuhan harian')).toList();
        expect(adgInsights, isEmpty);
      });
    });

    // ── Kombinasi insight ────────────────────────────────────────────────────
    group('kombinasi insight', () {
      test('performa sangat baik → 3 insight positif', () {
        // FCR 1.5 (baik), mortality 1.8% (rendah), ADG 57 (baik)
        final result = generator.execute(
          snap(finalFCR: 1.5, totalMortality: 18, avgDailyGain: 57.0),
          1000,
        );
        expect(result.length, 3);
        expect(result.any((s) => s.contains('FCR sangat baik')), true);
        expect(result.any((s) => s.contains('Mortalitas rendah')), true);
        expect(result.any((s) => s.contains('Pertumbuhan harian baik')), true);
      });

      test('performa buruk → insight negatif', () {
        // FCR 2.5 (buruk), mortality 15% (tinggi), ADG 20 (lambat)
        final result = generator.execute(
          snap(finalFCR: 2.5, totalMortality: 150, avgDailyGain: 20.0),
          1000,
        );
        expect(result.any((s) => s.contains('FCR tinggi')), true);
        expect(result.any((s) => s.contains('Mortalitas tinggi')), true);
        expect(result.any((s) => s.contains('Pertumbuhan harian lambat')), true);
      });

      test('tidak ada insight jika semua di zona abu-abu', () {
        // FCR 2.0, mortality 7%, ADG 40 — semua di zona tengah
        final result = generator.execute(
          snap(finalFCR: 2.0, totalMortality: 70, avgDailyGain: 40.0),
          1000,
        );
        expect(result, isEmpty);
      });
    });

    // ── Format output ─────────────────────────────────────────────────────────
    group('format string output', () {
      test('FCR insight mencantumkan nilai FCR 2 desimal', () {
        final result = generator.execute(snap(finalFCR: 1.512), 1000);
        // 1.512 → toStringAsFixed(2) → "1.51"
        expect(result.any((s) => s.contains('1.51')), true);
      });

      test('Mortality insight mencantumkan 1 desimal', () {
        final result = generator.execute(snap(totalMortality: 18), 1000);
        expect(result.any((s) => s.contains('1.8%')), true);
      });

      test('ADG insight mencantumkan 1 desimal', () {
        final result = generator.execute(snap(avgDailyGain: 57.46), 1000);
        expect(result.any((s) => s.contains('57.5 g/hari')), true);
      });
    });
  });
}
