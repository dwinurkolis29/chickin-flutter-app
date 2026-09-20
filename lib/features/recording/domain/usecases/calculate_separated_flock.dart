import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';

/// Level status proporsi ayam seleksian di kandang
enum SeparatedFlockStatus {
  normal, // <= 3.0%
  warning, // > 3.0% - 5.0%
  danger, // > 5.0%
}

/// Model ringkasan hasil kalkulasi pemisahan populasi reguler vs sekat seleksian
class SeparatedFlockSummary {
  final int totalLiveBirds;
  final int regularCount;
  final int sekatCount;
  final double sekatPercentage;
  final int regularAvgWeightGram;
  final int sekatAvgWeightGram;
  final int weightedAvgWeightGram; // Bobot rata-rata gabungan riil kandang
  final int weightGapGram; // Selisih bobot ayam reguler vs sekat
  final double totalBiomassKg; // Biomassa riil total (kg)
  final SeparatedFlockStatus status;
  final String statusLabel;
  final String recommendation;

  const SeparatedFlockSummary({
    required this.totalLiveBirds,
    required this.regularCount,
    required this.sekatCount,
    required this.sekatPercentage,
    required this.regularAvgWeightGram,
    required this.sekatAvgWeightGram,
    required this.weightedAvgWeightGram,
    required this.weightGapGram,
    required this.totalBiomassKg,
    required this.status,
    required this.statusLabel,
    required this.recommendation,
  });
}

/// Use case murni untuk menghitung proporsi, bobot terbobot (Weighted BW),
/// selisih bobot, dan status kesehatan populasi ayam seleksian (Hospital Pen).
class CalculateSeparatedFlock {
  const CalculateSeparatedFlock();

  SeparatedFlockSummary execute({
    required int totalLiveBirds,
    required int regularAvgWeightGram,
    HospitalPenData? hospitalPen,
  }) {
    final liveTotal = totalLiveBirds > 0 ? totalLiveBirds : 0;
    final sekatCount = (hospitalPen?.count ?? 0).clamp(0, liveTotal);
    final sekatAvgWeight = hospitalPen?.avgWeightGram ?? 0;
    final regularCount = (liveTotal - sekatCount).clamp(0, liveTotal);

    // 1. Persentase Seleksian
    final sekatPct = liveTotal > 0 ? (sekatCount / liveTotal) * 100.0 : 0.0;

    // 2. Selisih Bobot
    final weightGap = (regularAvgWeightGram > 0 && sekatAvgWeight > 0)
        ? (regularAvgWeightGram - sekatAvgWeight)
        : 0;

    // 3. Biomassa Total & Bobot Terbobot (Weighted BW)
    final regularBiomassGrams = regularCount * regularAvgWeightGram;
    final sekatBiomassGrams = sekatCount * sekatAvgWeight;
    final totalBiomassGrams = regularBiomassGrams + sekatBiomassGrams;

    final int weightedAvgWeight;
    if (liveTotal > 0 && totalBiomassGrams > 0) {
      weightedAvgWeight = (totalBiomassGrams / liveTotal).round();
    } else {
      weightedAvgWeight = regularAvgWeightGram;
    }

    final totalBiomassKg = totalBiomassGrams / 1000.0;

    // 4. Evaluasi Status & Rekomendasi
    final SeparatedFlockStatus status;
    final String statusLabel;
    final String recommendation;

    if (sekatCount == 0 || sekatPct <= 3.0) {
      status = SeparatedFlockStatus.normal;
      statusLabel = 'Normal';
      recommendation =
          'Populasi sekat seleksian dalam batas normal (≤ 3%). Lanjutkan perawatan intensif vitamin pada sekat.';
    } else if (sekatPct <= 5.0) {
      status = SeparatedFlockStatus.warning;
      statusLabel = 'Waspada';
      recommendation =
          'Populasi seleksian cukup tinggi (${sekatPct.toStringAsFixed(1)}%). Evaluasi keseragaman pakan, ventilasi, dan kepadatan sekat.';
    } else {
      status = SeparatedFlockStatus.danger;
      statusLabel = 'Tinggi';
      recommendation =
          'Populasi seleksian melebihi batas wajar (${sekatPct.toStringAsFixed(1)}%). Segera cek potensi infeksi, kualitas DOC, atau pertimbangkan afkir dini / jual pasar lokal.';
    }

    return SeparatedFlockSummary(
      totalLiveBirds: liveTotal,
      regularCount: regularCount,
      sekatCount: sekatCount,
      sekatPercentage: sekatPct,
      regularAvgWeightGram: regularAvgWeightGram,
      sekatAvgWeightGram: sekatAvgWeight,
      weightedAvgWeightGram: weightedAvgWeight,
      weightGapGram: weightGap,
      totalBiomassKg: totalBiomassKg,
      status: status,
      statusLabel: statusLabel,
      recommendation: recommendation,
    );
  }
}
