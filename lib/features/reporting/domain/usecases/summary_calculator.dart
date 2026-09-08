import 'package:recording_app/features/period/data/models/harvest_record.dart';
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
  final List<HarvestRecord> harvests;
  final double? weightedHarvestAgeDays;

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
    this.harvests = const [],
    this.weightedHarvestAgeDays,
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
    List<HarvestRecord>? harvests,
  }) {
    final initialPopulation = period.initialCapacity;
    final endDate = period.endDate ?? DateTime.now();
    final calendarDurationDays =
        endDate.difference(period.startDate).inDays.clamp(1, 9999);
    final durationDays = (recordings.isNotEmpty &&
            recordings.map((r) => r.day).reduce((a, b) => a > b ? a : b) > 0)
        ? recordings.map((r) => r.day).reduce((a, b) => a > b ? a : b)
        : calendarDurationDays;

    // Kumpulkan seluruh data panen (parsial sebelumnya + panen akhir saat ini)
    final List<HarvestRecord> allHarvests = List<HarvestRecord>.from(
      harvests ?? period.summary?.harvests ?? const [],
    );

    // Jika ada input panen akhir di dialog tutup panen yang belum ada di allHarvests
    if (harvestedChicks != null &&
        harvestedChicks > 0 &&
        harvestedWeightKg != null &&
        harvestedWeightKg > 0) {
      final hasFinalAlready =
          allHarvests.any((h) => h.type == HarvestType.finalHarvest);
      if (!hasFinalAlready) {
        final avgW = harvestedWeightKg / harvestedChicks;
        allHarvests.add(
          HarvestRecord(
            type: HarvestType.finalHarvest,
            date: endDate,
            day: durationDays,
            chicks: harvestedChicks,
            weightKg: harvestedWeightKg,
            avgWeightKg: avgW,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    if (recordings.isEmpty) {
      final totalHarvestChicks = allHarvests.isNotEmpty
          ? allHarvests.fold(0, (sum, h) => sum + h.chicks)
          : harvestedChicks;
      final totalHarvestKg = allHarvests.isNotEmpty
          ? allHarvests.fold(0.0, (sum, h) => sum + h.weightKg)
          : harvestedWeightKg;

      final finalPop = totalHarvestChicks ?? initialPopulation;
      final finalBio = totalHarvestKg ?? 0.0;
      final avgWeight = (totalHarvestChicks != null &&
              totalHarvestChicks > 0 &&
              totalHarvestKg != null)
          ? totalHarvestKg / totalHarvestChicks
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
        harvestedChicks: totalHarvestChicks,
        harvestedWeightKg: totalHarvestKg,
        avgHarvestWeightKg: avgWeight > 0 ? avgWeight : null,
        ipScore: 0.0,
        harvests: allHarvests,
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

    final totalFeedKg = totalFeedSacks * 50.0;
    final estAvgWeightGram = sorted.last.avgWeightGram;

    // FCR mingguan via CalculateFCR (memperhitungkan panen parsial jika ada)
    final fcrData = _calculateFCR.execute(
      sorted,
      initialPopulation,
      harvests: allHarvests,
    );
    final weeklyFCR =
        fcrData.map((d) => WeeklyFCR(week: d.mingguKe, fcr: d.fcr)).toList();
    final estFCR = weeklyFCR.isNotEmpty ? weeklyFCR.last.fcr : 0.0;

    // Evaluasi data panen riil akumulatif (parsial + akhir)
    final bool hasHarvestData = allHarvests.isNotEmpty ||
        (harvestedChicks != null &&
            harvestedChicks > 0 &&
            harvestedWeightKg != null &&
            harvestedWeightKg > 0);

    final int totalHarvestedChicks = allHarvests.isNotEmpty
        ? allHarvests.fold(0, (sum, h) => sum + h.chicks)
        : (harvestedChicks ?? 0);
    final double totalHarvestedWeightKg = allHarvests.isNotEmpty
        ? allHarvests.fold(0.0, (sum, h) => sum + h.weightKg)
        : (harvestedWeightKg ?? 0.0);

    final int estPopulation =
        (initialPopulation - totalMortality).clamp(0, initialPopulation);
    final double estBiomassKg = estPopulation * estAvgWeightGram / 1000.0;

    final int finalPopulation =
        hasHarvestData ? totalHarvestedChicks : estPopulation;
    final double finalBiomassKg =
        hasHarvestData ? totalHarvestedWeightKg : estBiomassKg;
    final double? avgHarvestWeightKg = hasHarvestData && totalHarvestedChicks > 0
        ? (totalHarvestedWeightKg / totalHarvestedChicks)
        : null;
    final int finalAvgWeightGram = hasHarvestData && avgHarvestWeightKg != null
        ? (avgHarvestWeightKg * 1000).round()
        : estAvgWeightGram;

    // FCR Aktual Panen = Total Feed Kg / Total Harvest Weight Kg
    final double finalFCR = hasHarvestData
        ? (totalHarvestedWeightKg > 0
            ? totalFeedKg / totalHarvestedWeightKg
            : estFCR)
        : estFCR;

    // Umur Panen Tertimbang (Weighted Average Age) jika ada penjarangan
    double weightedHarvestAge = durationDays.toDouble();
    if (allHarvests.isNotEmpty && totalHarvestedChicks > 0) {
      final totalAgeBirdDays = allHarvests.fold<double>(
        0.0,
        (sum, h) => sum + (h.chicks * (h.day > 0 ? h.day : durationDays)),
      );
      weightedHarvestAge = totalAgeBirdDays / totalHarvestedChicks;
    }

    // ADG: (berat akhir - berat awal) / durasi, dalam gram/hari
    final initialWeightGram = period.initialWeight * 1000;
    final effectiveDuration = weightedHarvestAge > 0
        ? weightedHarvestAge
        : durationDays.toDouble();
    final avgDailyGain = effectiveDuration > 0
        ? (finalAvgWeightGram - initialWeightGram) / effectiveDuration
        : 0.0;

    // Indeks Performa (IP) Broiler Standard:
    // IP = (Livability % * BW kg * 100) / (Umur Panen Tertimbang * FCR)
    double? ipScore;
    if (initialPopulation > 0 && finalFCR > 0 && effectiveDuration > 0) {
      final livabilityPct = (finalPopulation / initialPopulation) * 100.0;
      final avgWeightKg = finalAvgWeightGram / 1000.0;
      ipScore = ((livabilityPct * avgWeightKg * 100.0) /
          (effectiveDuration * finalFCR));
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
      harvestedChicks: hasHarvestData ? totalHarvestedChicks : null,
      harvestedWeightKg: hasHarvestData ? totalHarvestedWeightKg : null,
      avgHarvestWeightKg: avgHarvestWeightKg,
      ipScore: ipScore,
      harvests: allHarvests,
      weightedHarvestAgeDays:
          allHarvests.isNotEmpty ? weightedHarvestAge : null,
    );
  }
}
