import 'package:recording_app/features/recording/data/models/daily_adg_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

/// Use Case murni untuk kalkulasi ADG (Average Daily Gain / Pertambahan Bobot Harian).
class CalculateADG {
  /// Kalkulasi ADG harian dari daftar rekaman harian.
  /// - [recordings]: Daftar data recording.
  /// - [initialWeightKg]: Bobot awal DOC dalam kg (default 0.04 kg = 40 gram).
  List<DailyADGData> executeDaily(
    List<RecordingData> recordings, {
    double initialWeightKg = 0.04,
  }) {
    if (recordings.isEmpty) return [];

    // Filter hanya rekaman yang memiliki data bobot sampling > 0
    final validRecordings = recordings
        .where((r) => r.avgWeightGram > 0)
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    if (validRecordings.isEmpty) return [];

    final docWeightGram = (initialWeightKg > 0 ? initialWeightKg * 1000 : 40.0).round();
    final List<DailyADGData> result = [];

    int prevWeight = docWeightGram;
    int prevDay = 0;

    for (final rec in validRecordings) {
      final currentWeight = rec.avgWeightGram;
      final currentDay = rec.day;

      if (currentDay <= 0) continue;

      // ADG Interval (sejak timbang sebelumnya)
      final dayDiff = currentDay - prevDay;
      double intervalGain = 0.0;
      if (dayDiff > 0) {
        intervalGain = (currentWeight - prevWeight) / dayDiff;
      }

      // ADG Kumulatif (sejak DOC tiba)
      final cumulativeGain = (currentWeight - docWeightGram) / currentDay;

      // Evaluasi status pertumbuhan
      final statusInfo = _evaluateADGStatus(currentDay, intervalGain);

      result.add(
        DailyADGData(
          day: currentDay,
          date: rec.createdAt,
          weightGram: currentWeight,
          previousWeightGram: prevWeight,
          previousDay: prevDay,
          dailyGainGram: intervalGain > 0 ? double.parse(intervalGain.toStringAsFixed(1)) : 0.0,
          cumulativeADGGram: cumulativeGain > 0 ? double.parse(cumulativeGain.toStringAsFixed(1)) : 0.0,
          status: statusInfo.status,
          statusDescription: statusInfo.description,
        ),
      );

      prevWeight = currentWeight;
      prevDay = currentDay;
    }

    return result;
  }

  /// Evaluasi status ADG berdasarkan umur ayam
  ({String status, String description}) _evaluateADGStatus(int day, double adg) {
    if (day <= 7) {
      if (adg >= 20.0) {
        return (
          status: 'Optimal',
          description: 'Pertumbuhan awal sangat bagus, brooding berjalan optimal.',
        );
      } else if (adg >= 14.0) {
        return (
          status: 'Standar',
          description: 'Pertumbuhan normal sesuai target umur 1 minggu.',
        );
      } else {
        return (
          status: 'Lambat',
          description: 'Pertumbuhan awal lambat. Periksa suhu brooding dan pakan.',
        );
      }
    } else if (day <= 14) {
      if (adg >= 35.0) {
        return (
          status: 'Optimal',
          description: 'Laju kenaikan bobot di atas standar target umur 2 minggu.',
        );
      } else if (adg >= 25.0) {
        return (
          status: 'Standar',
          description: 'Pertumbuhan normal sesuai target minggu ke-2.',
        );
      } else {
        return (
          status: 'Lambat',
          description: 'Kenaikan bobot di bawah target. Periksa asupan pakan.',
        );
      }
    } else if (day <= 21) {
      if (adg >= 55.0) {
        return (
          status: 'Optimal',
          description: 'Pertumbuhan pesat, nafsu makan dan penyerapan pakan sangat baik.',
        );
      } else if (adg >= 42.0) {
        return (
          status: 'Standar',
          description: 'Kenaikan bobot stabil sesuai standar target.',
        );
      } else {
        return (
          status: 'Lambat',
          description: 'Pertumbuhan di bawah target. Cek ventilasi & kepadatan kandang.',
        );
      }
    } else {
      // Hari 22+
      if (adg >= 65.0) {
        return (
          status: 'Optimal',
          description: 'Pertumbuhan sangat cepat, siap menuju target panen prima.',
        );
      } else if (adg >= 50.0) {
        return (
          status: 'Standar',
          description: 'Pertumbuhan normal stabil di fase finisher.',
        );
      } else {
        return (
          status: 'Lambat',
          description: 'Pertumbuhan melambat. Evaluasi kualitas pakan & sirkulasi udara.',
        );
      }
    }
  }
}
