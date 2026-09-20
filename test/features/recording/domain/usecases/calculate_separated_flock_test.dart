import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_separated_flock.dart';

void main() {
  group('CalculateSeparatedFlock', () {
    const useCase = CalculateSeparatedFlock();

    test('correctly calculates Farm Tarmiasih PPL real case', () {
      // Data peternak Tarmiasih:
      // Pop awal = 3.000, Deplesi = 165 -> Live = 2.835
      // Regular BW = 1.685 g
      // Sekat seleksian = 150 ek, BW = 1.206 g
      const totalLiveBirds = 2835;
      const regularBW = 1685;
      final hospitalPen = HospitalPenData(
        count: 150,
        avgWeightGram: 1206,
        day: 28,
        conditions: const ['Kerdil', 'Kalah Bersaing'],
      );

      final summary = useCase.execute(
        totalLiveBirds: totalLiveBirds,
        regularAvgWeightGram: regularBW,
        hospitalPen: hospitalPen,
      );

      // 1. Regular count = 2835 - 150 = 2685 ekor
      expect(summary.regularCount, 2685);
      expect(summary.sekatCount, 150);

      // 2. Persentase sekat = 150 / 2835 * 100 = 5.291% (~5.3%)
      expect(summary.sekatPercentage, closeTo(5.291, 0.01));

      // 3. Selisih bobot = 1685 - 1206 = 479 g
      expect(summary.weightGapGram, 479);

      // 4. Bobot terbobot riil (Weighted BW):
      // (2685 * 1685 + 150 * 1206) / 2835 = (4524225 + 180900) / 2835 = 4705125 / 2835 = 1659.65 -> 1660 g
      expect(summary.weightedAvgWeightGram, 1660);

      // 5. Total biomassa sekat kg: 150 * 1.206 kg = 180.9 kg
      // Total biomassa keseluruhan kg: 4705.125 kg
      expect(summary.totalBiomassKg, closeTo(4705.125, 0.01));

      // 6. Status: > 5% -> danger (Tinggi)
      expect(summary.status, SeparatedFlockStatus.danger);
      expect(summary.statusLabel, 'Tinggi');
      expect(summary.recommendation, contains('melebihi batas wajar'));
    });

    test('returns normal status when sekat count is 0 or null', () {
      final summary = useCase.execute(
        totalLiveBirds: 3000,
        regularAvgWeightGram: 1500,
        hospitalPen: null,
      );

      expect(summary.sekatCount, 0);
      expect(summary.regularCount, 3000);
      expect(summary.sekatPercentage, 0.0);
      expect(summary.weightGapGram, 0);
      expect(summary.weightedAvgWeightGram, 1500);
      expect(summary.status, SeparatedFlockStatus.normal);
      expect(summary.statusLabel, 'Normal');
    });

    test('returns normal status when sekat percentage <= 3.0%', () {
      // 30 ekor dari 1000 ekor = 3.0%
      final summary = useCase.execute(
        totalLiveBirds: 1000,
        regularAvgWeightGram: 1000,
        hospitalPen: HospitalPenData(
          count: 30,
          avgWeightGram: 800,
          day: 20,
        ),
      );

      expect(summary.sekatPercentage, 3.0);
      expect(summary.status, SeparatedFlockStatus.normal);
      expect(summary.statusLabel, 'Normal');
    });

    test('returns warning status when sekat percentage between 3.1% and 5.0%', () {
      // 40 ekor dari 1000 ekor = 4.0%
      final summary = useCase.execute(
        totalLiveBirds: 1000,
        regularAvgWeightGram: 1000,
        hospitalPen: HospitalPenData(
          count: 40,
          avgWeightGram: 750,
          day: 20,
        ),
      );

      expect(summary.sekatPercentage, 4.0);
      expect(summary.status, SeparatedFlockStatus.warning);
      expect(summary.statusLabel, 'Waspada');
      expect(summary.recommendation, contains('cukup tinggi'));
    });

    test('handles zero total live birds gracefully without zero division error', () {
      final summary = useCase.execute(
        totalLiveBirds: 0,
        regularAvgWeightGram: 0,
        hospitalPen: HospitalPenData(
          count: 10,
          avgWeightGram: 500,
          day: 1,
        ),
      );

      expect(summary.totalLiveBirds, 0);
      expect(summary.sekatCount, 0);
      expect(summary.regularCount, 0);
      expect(summary.sekatPercentage, 0.0);
      expect(summary.weightedAvgWeightGram, 0);
      expect(summary.totalBiomassKg, 0.0);
      expect(summary.status, SeparatedFlockStatus.normal);
    });

    test('clamps sekat count when it exceeds total live birds', () {
      final summary = useCase.execute(
        totalLiveBirds: 500,
        regularAvgWeightGram: 1200,
        hospitalPen: HospitalPenData(
          count: 600, // melebihi live birds
          avgWeightGram: 800,
          day: 22,
        ),
      );

      expect(summary.sekatCount, 500);
      expect(summary.regularCount, 0);
      expect(summary.sekatPercentage, 100.0);
      expect(summary.status, SeparatedFlockStatus.danger);
    });
  });
}
