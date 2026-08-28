import 'package:recording_app/features/reporting/domain/usecases/summary_calculator.dart';

/// Generates human-readable insights dari [PeriodSnapshot].
class InsightGenerator {
  // FCR threshold (referensi standar industri broiler)
  static const double _goodFcrMax = 1.8;
  static const double _badFcrMin = 2.2;

  // Mortality threshold
  static const double _lowMortalityMax = 5.0; // persen
  static const double _highMortalityMin = 10.0; // persen

  List<String> execute(PeriodSnapshot snapshot, int initialPopulation) {
    final List<String> insights = [];

    if (initialPopulation <= 0) return insights;

    // ── Harvest Summary insight ──────────────────────────────────────────────
    if (snapshot.harvestedChicks != null && snapshot.harvestedWeightKg != null) {
      final avgKg = snapshot.avgHarvestWeightKg ?? 0.0;
      insights.add(
        'Panen tercatat: ${snapshot.harvestedChicks} ekor (${snapshot.harvestedWeightKg!.toStringAsFixed(1)} kg) • Rata-rata ${avgKg.toStringAsFixed(2)} kg/ekor',
      );
    }

    // ── IP (Indeks Performa) insight ─────────────────────────────────────────
    if (snapshot.ipScore != null && snapshot.ipScore! > 0) {
      final ip = snapshot.ipScore!;
      if (ip >= 400) {
        insights.add('Indeks Performa Istimewa (IP ${ip.toStringAsFixed(0)}) — efisiensi panen sangat tinggi');
      } else if (ip >= 350) {
        insights.add('Indeks Performa Sangat Baik (IP ${ip.toStringAsFixed(0)}) — performa panen optimal');
      } else if (ip >= 300) {
        insights.add('Indeks Performa Baik (IP ${ip.toStringAsFixed(0)}) — standar broiler tercapai');
      } else {
        insights.add('Indeks Performa Kurang (IP ${ip.toStringAsFixed(0)}) — evaluasi FCR dan durasi panen');
      }
    }

    // ── FCR insight ──────────────────────────────────────────────────────────
    if (snapshot.finalFCR > 0) {
      if (snapshot.finalFCR <= _goodFcrMax) {
        insights.add('FCR sangat baik (${snapshot.finalFCR.toStringAsFixed(2)}) — efisiensi pakan optimal');
      } else if (snapshot.finalFCR >= _badFcrMin) {
        insights.add('FCR tinggi (${snapshot.finalFCR.toStringAsFixed(2)}) — evaluasi manajemen pakan');
      }
    }

    // ── Mortality insight ─────────────────────────────────────────────────────
    final mortalityRate = (snapshot.totalMortality / initialPopulation) * 100;
    if (mortalityRate <= _lowMortalityMax) {
      insights.add('Mortalitas rendah (${mortalityRate.toStringAsFixed(1)}%) — manajemen kesehatan baik');
    } else if (mortalityRate >= _highMortalityMin) {
      insights.add('Mortalitas tinggi (${mortalityRate.toStringAsFixed(1)}%) — perlu evaluasi biosekuriti');
    }

    // ── ADG insight ───────────────────────────────────────────────────────────
    if (snapshot.avgDailyGain > 0) {
      if (snapshot.avgDailyGain >= 50) {
        insights.add('Pertumbuhan harian baik (${snapshot.avgDailyGain.toStringAsFixed(1)} g/hari)');
      } else if (snapshot.avgDailyGain < 30) {
        insights.add('Pertumbuhan harian lambat (${snapshot.avgDailyGain.toStringAsFixed(1)} g/hari) — cek kualitas pakan');
      }
    }

    return insights;
  }
}
