import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/domain/usecases/calculate_fcr.dart';

/// Hasil kalkulasi inti dari recordings sebuah periode.
/// Semua field yang dibutuhkan untuk menyusun [PeriodSummary] ada di sini.
class PeriodSnapshot {
  final double totalFeedKg;
  final int finalPopulation;
  final int totalMortality;
  final double finalBiomassKg;
  final int finalAvgWeightGram;
  final double finalFCR;
  final double avgDailyGain; // gram/hari
  final int durationDays;
  final List<WeeklyFCR> weeklyFCR;

  const PeriodSnapshot({
    required this.totalFeedKg,
    required this.finalPopulation,
    required this.totalMortality,
    required this.finalBiomassKg,
    required this.finalAvgWeightGram,
    required this.finalFCR,
    required this.avgDailyGain,
    required this.durationDays,
    required this.weeklyFCR,
  });
}

/// Core logic: menghitung seluruh metrik performa dari recordings harian.
///
/// Gunakan ini saat close period (bukan saat render UI).
/// Output-nya dipakai untuk mengisi [PeriodSummary] di Firestore.
class SummaryCalculator {
  final CalculateFCR _calculateFCR;

  SummaryCalculator({CalculateFCR? calculateFCR})
      : _calculateFCR = calculateFCR ?? CalculateFCR();

  PeriodSnapshot execute(PeriodData period, List<RecordingData> recordings) {
    final initialPopulation = period.initialCapacity;
    final endDate = period.endDate ?? DateTime.now();
    final durationDays =
        endDate.difference(period.startDate).inDays.clamp(1, 9999);

    if (recordings.isEmpty) {
      return PeriodSnapshot(
        totalFeedKg: 0,
        finalPopulation: initialPopulation,
        totalMortality: 0,
        finalBiomassKg: 0,
        finalAvgWeightGram: 0,
        finalFCR: 0,
        avgDailyGain: 0,
        durationDays: durationDays,
        weeklyFCR: [],
      );
    }

    final sorted = List<RecordingData>.from(recordings)
      ..sort((a, b) => a.day.compareTo(b.day));

    int totalMortality = 0;
    int totalFeedSacks = 0;
    for (final r in sorted) {
      totalMortality += r.mortality;
      totalFeedSacks += r.feedSack;
    }

    final finalPopulation =
        (initialPopulation - totalMortality).clamp(0, initialPopulation);
    final totalFeedKg = totalFeedSacks * 50.0;
    final finalAvgWeightGram = sorted.last.avgWeightGram;
    final finalBiomassKg = finalPopulation * finalAvgWeightGram / 1000.0;

    // ADG: (berat akhir - berat awal) / durasi, dalam gram/hari
    final initialWeightGram = period.initialWeight * 1000;
    final avgDailyGain = durationDays > 0
        ? (finalAvgWeightGram - initialWeightGram) / durationDays
        : 0.0;

    // FCR mingguan via CalculateFCR (existing logic)
    final fcrData = _calculateFCR.execute(sorted, initialPopulation);

    // Map FCRData → WeeklyFCR
    final weeklyFCR = fcrData
        .map((d) => WeeklyFCR(week: d.mingguKe, fcr: d.fcr))
        .toList();

    final finalFCR = weeklyFCR.isNotEmpty ? weeklyFCR.last.fcr : 0.0;

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
}
