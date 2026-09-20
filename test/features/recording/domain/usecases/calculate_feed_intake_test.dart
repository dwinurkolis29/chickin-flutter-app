import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_feed_intake.dart';

void main() {
  const calculator = CalculateFeedIntake();
  final baseDate = DateTime(2025, 6, 1);

  group('CalculateFeedIntake', () {
    group('Edge cases / empty inputs', () {
      test('mengembalikan map kosong jika recordings kosong', () {
        // Arrange
        final recordings = <RecordingData>[];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 3000,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('mengembalikan map kosong jika initialCapacity <= 0', () {
        // Arrange
        final recordings = [
          RecordingData(id: '1', day: 1, feedSack: 2, mortality: 1, createdAt: baseDate),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 0,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Single day calculation', () {
      test('menghitung FI harian dan kumulatif secara presisi untuk 1 hari', () {
        // Arrange
        // Pop awal 3000, mati 10 -> live = 2990 ekor.
        // Pakan: 2 sak = 100 kg = 100.000 g.
        // Daily FI = 100.000 / 2990 ≈ 33.4448 g/ekor/hari.
        final recordings = [
          RecordingData(
            id: 'rec-1',
            day: 1,
            feedSack: 2,
            mortality: 10,
            createdAt: baseDate,
          ),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 3000,
        );

        // Assert
        expect(result.containsKey(1), isTrue);
        final fi = result[1]!;
        expect(fi.day, 1);
        expect(fi.liveChicks, 2990);
        expect(fi.dailyFeedKg, 100.0);
        expect(fi.cumulativeFeedKg, 100.0);
        expect(fi.dailyGrams, closeTo(33.44, 0.01));
        expect(fi.cumulativeGrams, closeTo(33.44, 0.01));
        expect(fi.isDrop, isFalse);
        expect(fi.dropPercentage, 0.0);
      });

      test('mendukung pakan berdesimal (misal 10.5 sak)', () {
        // Arrange
        // Pop awal 3000, mati 0 -> live = 3000 ekor.
        // Pakan: 10.5 sak = 525 kg = 525.000 g.
        // Daily FI = 525.000 / 3000 = 175.0 g/ekor/hari.
        final recordings = [
          RecordingData(
            id: 'rec-1',
            day: 28,
            feedSack: 10.5,
            mortality: 0,
            createdAt: baseDate,
          ),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 3000,
        );

        // Assert
        final fi = result[28]!;
        expect(fi.dailyFeedKg, 525.0);
        expect(fi.dailyGrams, closeTo(175.0, 0.001));
        expect(fi.cumulativeGrams, closeTo(175.0, 0.001));
      });
    });

    group('Multiple days & cumulative calculation', () {
      test('mengakumulasi kematian dan pakan lintas hari dengan benar', () {
        // Arrange
        // Pop awal: 1000
        // H1: pakan 1 sak (50kg), mati 5 -> live: 995, FI harian: 50.000/995 ≈ 50.25 g, Kum: 50.25 g
        // H2: pakan 1.5 sak (75kg), mati 5 -> live: 990, FI harian: 75.000/990 ≈ 75.76 g, Kum: 125.000/990 ≈ 126.26 g
        final recordings = [
          RecordingData(id: 'r1', day: 1, feedSack: 1.0, mortality: 5, createdAt: baseDate),
          RecordingData(id: 'r2', day: 2, feedSack: 1.5, mortality: 5, createdAt: baseDate),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 1000,
        );

        // Assert
        expect(result.length, 2);
        final fi1 = result[1]!;
        expect(fi1.liveChicks, 995);
        expect(fi1.dailyGrams, closeTo(50.25, 0.01));
        expect(fi1.cumulativeGrams, closeTo(50.25, 0.01));

        final fi2 = result[2]!;
        expect(fi2.liveChicks, 990);
        expect(fi2.dailyFeedKg, 75.0);
        expect(fi2.cumulativeFeedKg, 125.0);
        expect(fi2.dailyGrams, closeTo(75.76, 0.01));
        expect(fi2.cumulativeGrams, closeTo(126.26, 0.01));
        expect(fi2.isDrop, isFalse);
      });

      test('mengurutkan data jika diberikan secara acak/tidak urut hari', () {
        // Arrange
        final recordings = [
          RecordingData(id: 'r2', day: 2, feedSack: 2, mortality: 0, createdAt: baseDate),
          RecordingData(id: 'r1', day: 1, feedSack: 1, mortality: 0, createdAt: baseDate),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 1000,
        );

        // Assert
        expect(result[1]!.cumulativeFeedKg, 50.0);
        expect(result[2]!.cumulativeFeedKg, 150.0);
      });
    });

    group('Appetite drop detection (>10%)', () {
      test('mendeteksi penurunan nafsu makan jika FI turun lebih dari 10%', () {
        // Arrange
        // Pop awal: 1000, tanpa kematian (live = 1000)
        // H1: pakan 2 sak (100kg = 100.000g) -> FI = 100 g/ekor
        // H2: pakan 1.7 sak (85kg = 85.000g) -> FI = 85 g/ekor (Turun 15%)
        final recordings = [
          RecordingData(id: 'r1', day: 1, feedSack: 2.0, mortality: 0, createdAt: baseDate),
          RecordingData(id: 'r2', day: 2, feedSack: 1.7, mortality: 0, createdAt: baseDate),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 1000,
        );

        // Assert
        final fi1 = result[1]!;
        expect(fi1.isDrop, isFalse);

        final fi2 = result[2]!;
        expect(fi2.isDrop, isTrue);
        expect(fi2.dropPercentage, closeTo(15.0, 0.01));
      });

      test('tidak men-trigger drop jika penurunan <= 10%', () {
        // Arrange
        // H1: FI = 100 g
        // H2: FI = 91 g (Turun 9% <= 10%)
        final recordings = [
          RecordingData(id: 'r1', day: 1, feedSack: 2.0, mortality: 0, createdAt: baseDate),
          RecordingData(id: 'r2', day: 2, feedSack: 1.82, mortality: 0, createdAt: baseDate),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 1000,
        );

        // Assert
        final fi2 = result[2]!;
        expect(fi2.isDrop, isFalse);
        expect(fi2.dropPercentage, 0.0);
      });
    });

    group('Partial harvest integration', () {
      test('mengurangi populasi ayam hidup berdasarkan panen parsial s/d hari tersebut', () {
        // Arrange
        // Pop awal: 3000
        // H25: pakan 10 sak (500kg), tanpa mati -> live: 3000. FI = 500.000 / 3000 ≈ 166.67 g
        // H26: terjadi panen parsial 500 ekor pada H26.
        // H26 pakan 8 sak (400kg), tanpa mati -> live: 3000 - 500 = 2500 ekor.
        // FI H26 = 400.000 / 2500 = 160.0 g/ekor/hari.
        final recordings = [
          RecordingData(id: 'r25', day: 25, feedSack: 10.0, mortality: 0, createdAt: baseDate),
          RecordingData(id: 'r26', day: 26, feedSack: 8.0, mortality: 0, createdAt: baseDate),
        ];
        final harvests = <HarvestRecord>[
          HarvestRecord(
            id: 'h1',
            day: 26,
            date: baseDate,
            chicks: 500,
            weightKg: 900.0,
            avgWeightKg: 1.8,
            pricePerKg: 20000,
            createdAt: baseDate,
          ),
        ];

        // Act
        final result = calculator.execute(
          recordings: recordings,
          initialCapacity: 3000,
          harvests: harvests,
        );

        // Assert
        final fi25 = result[25]!;
        expect(fi25.liveChicks, 3000);
        expect(fi25.dailyGrams, closeTo(166.67, 0.01));

        final fi26 = result[26]!;
        expect(fi26.liveChicks, 2500);
        expect(fi26.dailyGrams, closeTo(160.0, 0.01));
      });
    });
  });
}
