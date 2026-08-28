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
  final int? harvestedChicks;
  final double? harvestedWeightKg;
  final double? avgHarvestWeightKg;
  final double? ipScore;

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
    this.harvestedChicks,
    this.harvestedWeightKg,
    this.avgHarvestWeightKg,
    this.ipScore,
  });
}

/// Core logic: menghitung seluruh metrik performa dari recordings harian dan data panen riil.
///
/// Gunakan ini saat close period (bukan saat render UI).
/// Output-nya dipakai untuk mengisi [PeriodSummary] di Firestore.
class SummaryCalculator {
  final CalculateFCR _calculateFCR;

  SummaryCalculator({CalculateFCR? calculateFCR})
      : _calculateFCR = calculateFCR ?? CalculateFCR();

  PeriodSnapshot execute(
    PeriodData period,
    List<RecordingData> recordings, {
    int? harvestedChicks,
    double? harvestedWeightKg,
  }) {
    final initialPopulation = period.initialCapacity;
    final endDate = period.endDate ?? DateTime.now();
    final durationDays =
        endDate.difference(period.startDate).inDays.clamp(1, 9999);

    if (recordings.isEmpty) {
      final finalPop = harvestedChicks ?? initialPopulation;
      final finalBio = harvestedWeightKg ?? 0.0;
      final avgWeight = (harvestedChicks != null && harvestedChicks > 0 && harvestedWeightKg != null)
          ? harvestedWeightKg / harvestedChicks
          : 0.0;

      return PeriodSnapshot(
        totalFeedKg: 0,
        finalPopulation: finalPop,
        totalMortality: 0,
        finalBiomassKg: finalBio,
        finalAvgWeightGram: (avgWeight * 1000).round(),
        finalFCR: 0,
        avgDailyGain: 0,
        durationDays: durationDays,
        weeklyFCR: [],
        harvestedChicks: harvestedChicks,
        harvestedWeightKg: harvestedWeightKg,
        avgHarvestWeightKg: avgWeight > 0 ? avgWeight : null,
        ipScore: 0.0,
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

    final estPopulation =
        (initialPopulation - totalMortality).clamp(0, initialPopulation);
    final totalFeedKg = totalFeedSacks * 50.0;
    final estAvgWeightGram = sorted.last.avgWeightGram;
    final estBiomassKg = estPopulation * estAvgWeightGram / 1000.0;

    // FCR mingguan via CalculateFCR
    final fcrData = _calculateFCR.execute(sorted, initialPopulation);
    final weeklyFCR = fcrData
        .map((d) => WeeklyFCR(week: d.mingguKe, fcr: d.fcr))
        .toList();

    final estFCR = weeklyFCR.isNotEmpty ? weeklyFCR.last.fcr : 0.0;

    // Evaluasi data panen riil jika diinput peternak
    final bool hasHarvestData =
        harvestedChicks != null && harvestedChicks > 0 && harvestedWeightKg != null && harvestedWeightKg > 0;

    final int finalPopulation = hasHarvestData ? harvestedChicks : estPopulation;
    final double finalBiomassKg = hasHarvestData ? harvestedWeightKg : estBiomassKg;
    final double? avgHarvestWeightKg =
        hasHarvestData ? (harvestedWeightKg / harvestedChicks) : null;
    final int finalAvgWeightGram = hasHarvestData
        ? (avgHarvestWeightKg! * 1000).round()
        : estAvgWeightGram;

    // FCR Aktual Panen = Total Feed Kg / Total Harvest Weight Kg
    final double finalFCR = hasHarvestData
        ? (harvestedWeightKg > 0 ? totalFeedKg / harvestedWeightKg : estFCR)
        : estFCR;

    // ADG: (berat akhir - berat awal) / durasi, dalam gram/hari
    final initialWeightGram = period.initialWeight * 1000;
    final avgDailyGain = durationDays > 0
        ? (finalAvgWeightGram - initialWeightGram) / durationDays
        : 0.0;

    // Indeks Performa (IP) Broiler Standard:
    // IP = (Livability % * BW kg * 100) / (Umur Hari * FCR)
    double? ipScore;
    if (initialPopulation > 0 && finalFCR > 0 && durationDays > 0) {
      final livabilityPct = (finalPopulation / initialPopulation) * 100.0;
      final avgWeightKg = finalAvgWeightGram / 1000.0;
      ipScore = ((livabilityPct * avgWeightKg * 100.0) / (durationDays * finalFCR));
    }

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
      harvestedChicks: harvestedChicks,
      harvestedWeightKg: harvestedWeightKg,
      avgHarvestWeightKg: avgHarvestWeightKg,
      ipScore: ipScore,
    );
  }
}
