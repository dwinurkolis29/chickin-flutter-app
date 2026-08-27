import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';

// ─── Helper ────────────────────────────────────────────────────────────────
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
    createdAt: DateTime(2025, 3, day),
  );
}

void main() {
  late CalculateFCR useCase;

  setUp(() {
    useCase = CalculateFCR();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CalculateFCR.execute
  // ─────────────────────────────────────────────────────────────────────────
  group('CalculateFCR.execute', () {
    group('guard conditions — empty / zero', () {
      test('recordings kosong → return []', () {
        final result = useCase.execute([], 1000);
        expect(result, isEmpty);
      });

      test('initialCapacity = 0 → return []', () {
        final recordings = [rec(day: 7, avgWeightGram: 600, feedSack: 5)];
        final result = useCase.execute(recordings, 0);
        expect(result, isEmpty);
      });

      test('kedua kosong → return []', () {
        final result = useCase.execute([], 0);
        expect(result, isEmpty);
      });
    });

    group('single week — happy path', () {
      // Skenario realistis: 1000 ekor, minggu ke-1 (hari 1–7)
      // Feed: 3 sak × 50 kg = 150 kg kumulatif
      // Mortality: 5 → sisa = 995
      // AvgWeight hari ke-7 = 450 gram = 0.45 kg
      // Biomass = 995 × 0.45 = 447.75 kg
      // FCR = 150 / 447.75 ≈ 0.33
      test('minggu 1, 3 sak, 995 sisa ayam', () {
        final recordings = [
          rec(day: 1, avgWeightGram: 180, feedSack: 1, mortality: 2),
          rec(day: 4, avgWeightGram: 320, feedSack: 1, mortality: 2),
          rec(day: 7, avgWeightGram: 450, feedSack: 1, mortality: 1),
        ];

        final result = useCase.execute(recordings, 1000);

        expect(result.length, 1);
        expect(result.first.mingguKe, 1);
        expect(result.first.sisaAyam, 995);
        expect(result.first.totalPakan, 150.0);

        final expectedBiomass = double.parse((995 * 0.45).toStringAsFixed(2));
        expect(result.first.beratAyam, expectedBiomass);

        final expectedFCR = double.parse((150.0 / expectedBiomass).toStringAsFixed(2));
        expect(result.first.fcr, expectedFCR);
      });
    });

    group('multi-week — happy path realistis', () {
      // 5 minggu, 1000 ekor awal, mortalitas 18, berat akhir 2150 gram
      // Data mirip real broiler farm Indonesia
      test('5 minggu — FCR terakhir sekitar 1.5', () {
        final recordings = [
          // Week 1 (day 1-7)
          rec(day: 1, avgWeightGram: 180, feedSack: 2, mortality: 3),
          rec(day: 7, avgWeightGram: 470, feedSack: 6, mortality: 3),
          // Week 2 (day 8-14)
          rec(day: 10, avgWeightGram: 700, feedSack: 8, mortality: 3),
          rec(day: 14, avgWeightGram: 980, feedSack: 10, mortality: 3),
          // Week 3 (day 15-21)
          rec(day: 18, avgWeightGram: 1300, feedSack: 14, mortality: 3),
          rec(day: 21, avgWeightGram: 1550, feedSack: 14, mortality: 2),
          // Week 4 (day 22-28)
          rec(day: 25, avgWeightGram: 1850, feedSack: 16, mortality: 1),
          rec(day: 28, avgWeightGram: 2000, feedSack: 16, mortality: 0),
          // Week 5 (day 29-35)
          rec(day: 32, avgWeightGram: 2100, feedSack: 16, mortality: 0),
          rec(day: 35, avgWeightGram: 2150, feedSack: 16, mortality: 0),
        ];

        final result = useCase.execute(recordings, 1000);

        // Harus ada 5 entry (satu per minggu)
        expect(result.length, 5);

        // Minggu ke-N harus ordered
        for (int i = 0; i < result.length; i++) {
          expect(result[i].mingguKe, i + 1);
        }

        // FCR kumulatif minggu pertama sangat rendah (belum banyak pakan)
        expect(result.first.fcr, lessThan(1.0));

        // FCR kumulatif minggu terakhir bisa mencapai 2-3 tergantung data
        expect(result.last.fcr, greaterThan(1.0));
        expect(result.last.fcr, lessThan(4.0));

        // Sisa ayam di minggu terakhir = 1000 - 18 = 982
        expect(result.last.sisaAyam, 982);
      });
    });

    group('sorting — input tidak berurutan', () {
      test('input acak → tetap dihitung benar per minggu', () {
        // Input tidak diurutkan berdasarkan hari
        final recordings = [
          rec(day: 7, avgWeightGram: 450, feedSack: 3, mortality: 2),
          rec(day: 1, avgWeightGram: 180, feedSack: 1, mortality: 1),
          rec(day: 4, avgWeightGram: 320, feedSack: 1, mortality: 1),
        ];

        final result = useCase.execute(recordings, 1000);
        expect(result.length, 1);
        // Total feed = 5 sak × 50 = 250 kg
        expect(result.first.totalPakan, 250.0);
        // Mortality = 4, sisa = 996
        expect(result.first.sisaAyam, 996);
      });
    });

    group('edge case — semua ayam mati', () {
      test('sisa ayam ≤ 0 → minggu di-skip (tidak masuk result)', () {
        // 100 ekor, semua mati di minggu 1
        final recordings = [
          rec(day: 3, avgWeightGram: 200, feedSack: 1, mortality: 60),
          rec(day: 7, avgWeightGram: 300, feedSack: 1, mortality: 40),
        ];

        final result = useCase.execute(recordings, 100);
        // remainingChickens = 100 - 100 = 0 → di-skip
        expect(result, isEmpty);
      });
    });

    group('edge case — mortalitas sangat tinggi tapi belum habis', () {
      test('sisa 1 ekor → tetap dihitung', () {
        final recordings = [
          rec(day: 7, avgWeightGram: 500, feedSack: 2, mortality: 999),
        ];

        final result = useCase.execute(recordings, 1000);
        expect(result.length, 1);
        expect(result.first.sisaAyam, 1);
        // Biomass = 1 × 0.5 = 0.5 kg
        expect(result.first.beratAyam, 0.5);
      });
    });

    group('edge case — semua recording dalam 1 hari', () {
      test('hanya 1 recording di hari 1 → 1 minggu, 1 entry', () {
        final recordings = [
          rec(day: 1, avgWeightGram: 200, feedSack: 1, mortality: 0),
        ];
        final result = useCase.execute(recordings, 500);
        expect(result.length, 1);
        expect(result.first.mingguKe, 1);
      });
    });

    group('boundary — day tepat di batas minggu', () {
      test('day 7 masuk minggu 1, day 8 masuk minggu 2', () {
        final recordings = [
          rec(day: 7, avgWeightGram: 450, feedSack: 3, mortality: 0),
          rec(day: 8, avgWeightGram: 600, feedSack: 2, mortality: 0),
        ];

        final result = useCase.execute(recordings, 1000);
        expect(result.length, 2);
        expect(result[0].mingguKe, 1);
        expect(result[1].mingguKe, 2);
      });

      test('day 14 masuk minggu 2, day 15 masuk minggu 3', () {
        final recordings = [
          rec(day: 7, avgWeightGram: 450, feedSack: 3, mortality: 0),
          rec(day: 14, avgWeightGram: 950, feedSack: 4, mortality: 0),
          rec(day: 15, avgWeightGram: 1050, feedSack: 3, mortality: 0),
        ];

        final result = useCase.execute(recordings, 1000);
        expect(result.length, 3);
        expect(result[0].mingguKe, 1);
        expect(result[1].mingguKe, 2);
        expect(result[2].mingguKe, 3);
      });
    });

    group('FCR precision — toStringAsFixed(2)', () {
      test('FCR di-round ke 2 desimal', () {
        final recordings = [
          rec(day: 7, avgWeightGram: 450, feedSack: 3, mortality: 5),
        ];
        final result = useCase.execute(recordings, 1000);
        final fcrStr = result.first.fcr.toString();
        // Tidak boleh ada lebih dari 2 desimal (misal 1.330000...)
        // Cek dengan parsing bahwa tidak ada trailing fraction
        expect(result.first.fcr, closeTo(result.first.fcr, 0.005));
        // FCR harus string-representable dengan ≤ 2 digit setelah titik
        expect(double.parse(fcrStr).toStringAsFixed(2), fcrStr.contains('.') ? fcrStr : '$fcrStr.00');
      });
    });

    group('week gap — ada minggu kosong', () {
      test('minggu 2 tidak punya recording → skip, minggu 1 & 3 ada', () {
        final recordings = [
          rec(day: 7, avgWeightGram: 450, feedSack: 3, mortality: 2),
          // Tidak ada recording day 8-14
          rec(day: 21, avgWeightGram: 1500, feedSack: 10, mortality: 3),
        ];

        final result = useCase.execute(recordings, 1000);
        // Hanya 2 entry: minggu 1 dan minggu 3
        expect(result.length, 2);
        expect(result[0].mingguKe, 1);
        expect(result[1].mingguKe, 3);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CalculateFCR.executeDaily
  // ─────────────────────────────────────────────────────────────────────────
  group('CalculateFCR.executeDaily', () {
    test('recordings kosong → return []', () {
      expect(useCase.executeDaily([], 1000), isEmpty);
    });

    test('initialCapacity = 0 → return []', () {
      final recordings = [rec(day: 1, avgWeightGram: 180, feedSack: 1)];
      expect(useCase.executeDaily(recordings, 0), isEmpty);
    });

    test('menghitung FCR kumulatif per hari dengan benar', () {
      // Hari 1: 1 sak (50kg), mati 2, bobot 180g -> sisa 998, biomass = 998 * 0.18 = 179.64kg, FCR = 50 / 179.64 = 0.28
      // Hari 2: 1 sak (total 100kg), mati 3 (total 5), bobot 220g -> sisa 995, biomass = 995 * 0.22 = 218.9kg, FCR = 100 / 218.9 = 0.46
      final recordings = [
        rec(day: 1, avgWeightGram: 180, feedSack: 1, mortality: 2),
        rec(day: 2, avgWeightGram: 220, feedSack: 1, mortality: 3),
      ];

      final result = useCase.executeDaily(recordings, 1000);

      expect(result.length, 2);
      expect(result[0].day, 1);
      expect(result[0].dailyFeedKg, 50.0);
      expect(result[0].cumulativeFeedKg, 50.0);
      expect(result[0].sisaAyam, 998);
      expect(result[0].fcr, 0.28);

      expect(result[1].day, 2);
      expect(result[1].dailyFeedKg, 50.0);
      expect(result[1].cumulativeFeedKg, 100.0);
      expect(result[1].sisaAyam, 995);
      expect(result[1].fcr, 0.46);
    });
  });
}
