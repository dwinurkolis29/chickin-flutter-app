import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_adg.dart';

void main() {
  late CalculateADG useCase;

  setUp(() {
    useCase = CalculateADG();
  });

  group('CalculateADG.executeDaily Unit Tests', () {
    test('mengembalikan list kosong jika data recording kosong', () {
      final result = useCase.executeDaily([]);
      expect(result, isEmpty);
    });

    test('mengembalikan list kosong jika seluruh recording tidak memiliki data timbang bobot (avgWeightGram <= 0)', () {
      final recordings = [
        RecordingData(
          id: '1',
          day: 1,
          createdAt: DateTime(2026, 8, 1),
          feedSack: 1,
          mortality: 0,
          avgWeightGram: 0,
        ),
        RecordingData(
          id: '2',
          day: 2,
          createdAt: DateTime(2026, 8, 2),
          feedSack: 2,
          mortality: 1,
          avgWeightGram: 0,
        ),
      ];

      final result = useCase.executeDaily(recordings);
      expect(result, isEmpty);
    });

    test('menghitung ADG harian dan kumulatif dengan benar untuk sampling teratur', () {
      final recordings = [
        RecordingData(
          id: '1',
          day: 7,
          createdAt: DateTime(2026, 8, 7),
          feedSack: 2,
          mortality: 2,
          avgWeightGram: 180, // Hari 7: 180g
        ),
        RecordingData(
          id: '2',
          day: 14,
          createdAt: DateTime(2026, 8, 14),
          feedSack: 4,
          mortality: 1,
          avgWeightGram: 460, // Hari 14: 460g
        ),
        RecordingData(
          id: '3',
          day: 21,
          createdAt: DateTime(2026, 8, 21),
          feedSack: 6,
          mortality: 3,
          avgWeightGram: 900, // Hari 21: 900g
        ),
      ];

      // Default DOC weight = 0.04 kg (40g)
      final result = useCase.executeDaily(recordings, initialWeightKg: 0.04);

      expect(result.length, 3);

      // Hari 7:
      // Interval = (180 - 40) / 7 = 20.0 g/hari
      // Kumulatif = (180 - 40) / 7 = 20.0 g/hari
      expect(result[0].day, 7);
      expect(result[0].weightGram, 180);
      expect(result[0].previousWeightGram, 40);
      expect(result[0].dailyGainGram, 20.0);
      expect(result[0].cumulativeADGGram, 20.0);
      expect(result[0].status, 'Optimal');

      // Hari 14:
      // Interval = (460 - 180) / 7 = 40.0 g/hari
      // Kumulatif = (460 - 40) / 14 = 30.0 g/hari
      expect(result[1].day, 14);
      expect(result[1].weightGram, 460);
      expect(result[1].previousWeightGram, 180);
      expect(result[1].dailyGainGram, 40.0);
      expect(result[1].cumulativeADGGram, 30.0);
      expect(result[1].status, 'Optimal');

      // Hari 21:
      // Interval = (900 - 460) / 7 = 62.9 g/hari
      // Kumulatif = (900 - 40) / 21 = 41.0 g/hari
      expect(result[2].day, 21);
      expect(result[2].weightGram, 900);
      expect(result[2].previousWeightGram, 460);
      expect(result[2].dailyGainGram, 62.9);
      expect(result[2].cumulativeADGGram, 41.0);
      expect(result[2].status, 'Optimal');
    });

    test('mengurutkan data secara otomatis jika input tidak urut hari', () {
      final recordings = [
        RecordingData(
          id: '2',
          day: 14,
          createdAt: DateTime(2026, 8, 14),
          avgWeightGram: 450,
        ),
        RecordingData(
          id: '1',
          day: 7,
          createdAt: DateTime(2026, 8, 7),
          avgWeightGram: 160,
        ),
      ];

      final result = useCase.executeDaily(recordings);
      expect(result.length, 2);
      expect(result[0].day, 7);
      expect(result[1].day, 14);
    });

    test('mengevaluasi status Lambat jika kenaikan bobot di bawah standar', () {
      final recordings = [
        RecordingData(
          id: '1',
          day: 7,
          createdAt: DateTime(2026, 8, 7),
          avgWeightGram: 100, // Kenaikan (100 - 40)/7 = 8.6 g/hari (Lambat < 14)
        ),
      ];

      final result = useCase.executeDaily(recordings);
      expect(result.first.status, 'Lambat');
    });
  });
}
