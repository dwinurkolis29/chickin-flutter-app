import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';

// ─── Helper factories ────────────────────────────────────────────────────────
RecordingData rec({
  required int day,
  required int avgWeightGram,
  required int feedSack,
  int mortality = 0,
}) {
  return RecordingData(
    day: day,
    avgWeightGram: avgWeightGram,
    feedSack: feedSack,
    mortality: mortality,
    createdAt: DateTime(2025, 3, day.clamp(1, 28)),
  );
}

PeriodData period({
  int initialCapacity = 1000,
  double initialWeight = 0.4,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final start = startDate ?? DateTime(2025, 3, 1);
  return PeriodData(
    id: 'period-001',
    name: 'Periode Maret 2025',
    initialCapacity: initialCapacity,
    initialWeight: initialWeight,
    startDate: start,
    endDate: endDate ?? start.add(const Duration(days: 35)),
    isActive: false,
    createdAt: start,
  );
}

void main() {
  late SummaryCalculator calculator;

  setUp(() {
    calculator = SummaryCalculator(calculateFCR: CalculateFCR());
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SummaryCalculator.execute
  // ─────────────────────────────────────────────────────────────────────────
  group('SummaryCalculator.execute', () {
    group('empty recordings', () {
      test('recordings kosong → snapshot dengan zero metrics', () {
        final p = period(initialCapacity: 1000);
        final result = calculator.execute(p, []);

        expect(result.totalFeedKg, 0.0);
        expect(result.totalMortality, 0);
        expect(result.finalPopulation, 1000); // semua hidup
        expect(result.finalBiomassKg, 0.0);
        expect(result.finalAvgWeightGram, 0);
        expect(result.finalFCR, 0.0);
        expect(result.avgDailyGain, 0.0);
        expect(result.weeklyFCR, isEmpty);
      });

      test('durationDays dihitung meski tidak ada recording', () {
        final start = DateTime(2025, 3, 1);
        final end = DateTime(2025, 4, 5); // 35 hari
        final p = period(startDate: start, endDate: end);
        final result = calculator.execute(p, []);
        expect(result.durationDays, 35);
      });
    });

    group('happy path — skenario realistis 35 hari, 1000 ekor', () {
      // Feed total: (2+6+8+10+14+14+16+16+16+16) = 118 sak × 50 kg = 5900 kg
      // Mortality total: 3+3+3+3+3+2+1+0+0+0 = 18
      // finalPopulation = 1000 - 18 = 982
      // finalAvgWeightGram = 2150 gram
      // finalBiomassKg = 982 × 2.15 = 2111.3 kg
      // ADG = (2150 - 400) / 35 = 50.0 gram/hari  (initialWeight 0.4 kg = 400 gram)

      late List<RecordingData> recordings35hari;

      setUp(() {
        recordings35hari = [
          rec(day: 1, avgWeightGram: 180, feedSack: 2, mortality: 3),
          rec(day: 7, avgWeightGram: 470, feedSack: 6, mortality: 3),
          rec(day: 10, avgWeightGram: 700, feedSack: 8, mortality: 3),
          rec(day: 14, avgWeightGram: 980, feedSack: 10, mortality: 3),
          rec(day: 18, avgWeightGram: 1300, feedSack: 14, mortality: 3),
          rec(day: 21, avgWeightGram: 1550, feedSack: 14, mortality: 2),
          rec(day: 25, avgWeightGram: 1850, feedSack: 16, mortality: 1),
          rec(day: 28, avgWeightGram: 2000, feedSack: 16, mortality: 0),
          rec(day: 32, avgWeightGram: 2100, feedSack: 16, mortality: 0),
          rec(day: 35, avgWeightGram: 2150, feedSack: 16, mortality: 0),
        ];
      });

      test('totalFeedKg = 118 sak × 50 kg = 5900', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.totalFeedKg, 5900.0);
      });

      test('totalMortality = 18', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.totalMortality, 18);
      });

      test('finalPopulation = 1000 - 18 = 982', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.finalPopulation, 982);
      });

      test('finalAvgWeightGram = 2150', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.finalAvgWeightGram, 2150);
      });

      test('finalBiomassKg = 982 × 2.15 = 2111.3', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.finalBiomassKg, closeTo(2111.3, 0.01));
      });

      test('durationDays = 35', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.durationDays, 35);
      });

      test('avgDailyGain = (2150 - 400) / 35 = 50.0 g/hari', () {
        final result = calculator.execute(period(initialWeight: 0.4), recordings35hari);
        expect(result.avgDailyGain, closeTo(50.0, 0.1));
      });

      test('weeklyFCR tidak kosong', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.weeklyFCR, isNotEmpty);
      });

      test('finalFCR = FCR minggu terakhir', () {
        final result = calculator.execute(period(), recordings35hari);
        expect(result.finalFCR, greaterThan(1.0));
        expect(result.finalFCR, lessThan(3.5));
        expect(result.finalFCR, result.weeklyFCR.last.fcr);
      });
    });

    group('mortality clamp — tidak bisa lebih dari initialCapacity', () {
      test('mortality > initialCapacity → finalPopulation = 0', () {
        final p = period(initialCapacity: 100);
        final recordings = [
          rec(day: 7, avgWeightGram: 400, feedSack: 2, mortality: 200), // lebih dari kapasitas
        ];
        final result = calculator.execute(p, recordings);
        expect(result.finalPopulation, 0); // clamp(0, 100) = 0
      });
    });

    group('durationDays — endDate null (pakai DateTime.now())', () {
      test('endDate null → durationDays ≥ 1 (clamp 1)', () {
        final p = PeriodData(
          id: 'period-002',
          name: 'Active',
          initialCapacity: 500,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          // endDate null → akan pakai DateTime.now()
        );
        final result = calculator.execute(p, []);
        expect(result.durationDays, greaterThanOrEqualTo(1));
        expect(result.durationDays, lessThanOrEqualTo(11)); // buffer 1 hari
      });
    });

    group('input tidak diurutkan → tetap benar', () {
      test('recordings acak → sorted secara internal', () {
        // Input di-shuffle
        final recordings = [
          rec(day: 35, avgWeightGram: 2150, feedSack: 16, mortality: 0),
          rec(day: 1, avgWeightGram: 180, feedSack: 2, mortality: 3),
          rec(day: 14, avgWeightGram: 980, feedSack: 10, mortality: 3),
          rec(day: 7, avgWeightGram: 470, feedSack: 6, mortality: 3),
        ];
        final result = calculator.execute(period(), recordings);
        // finalAvgWeightGram harus dari last sorted = hari 35
        expect(result.finalAvgWeightGram, 2150);
        // totalMortality = 9
        expect(result.totalMortality, 9);
      });
    });

    group('dependency injection — custom CalculateFCR', () {
      test('calculator menerima custom CalculateFCR melalui constructor', () {
        // Verifikasi DI bekerja — tidak throw saat dipass custom instance
        final customCalc = SummaryCalculator(calculateFCR: CalculateFCR());
        expect(() => customCalc.execute(period(), []), returnsNormally);
      });

      test('default constructor — tanpa inject → default CalculateFCR', () {
        final defaultCalc = SummaryCalculator();
        expect(() => defaultCalc.execute(period(), []), returnsNormally);
      });
    });

    group('single recording', () {
      test('hanya 1 recording → metrics tetap dihitung', () {
        final recordings = [
          rec(day: 35, avgWeightGram: 2150, feedSack: 64, mortality: 18),
        ];
        final result = calculator.execute(period(), recordings);
        expect(result.totalFeedKg, 64 * 50.0);
        expect(result.totalMortality, 18);
        expect(result.finalPopulation, 982);
        expect(result.finalAvgWeightGram, 2150);
      });
    });
  });
}
