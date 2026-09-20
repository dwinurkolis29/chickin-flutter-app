import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';

/// Model hasil kalkulasi Feed Intake harian dan kumulatif per ekor.
class DailyFeedIntake {
  final int day;
  final String recordingId;
  final double dailyGrams; // gram/ekor/hari
  final double cumulativeGrams; // gram/ekor kumulatif
  final int liveChicks; // sisa ayam hidup pada hari tersebut
  final double dailyFeedKg; // total pakan hari tersebut (kg)
  final double cumulativeFeedKg; // total pakan kumulatif s/d hari tersebut (kg)
  final bool isDrop; // true jika konsumsi turun > 10% dari hari sebelumnya
  final double dropPercentage; // persentase penurunan konsumsi (0.0 jika tidak drop)

  const DailyFeedIntake({
    required this.day,
    required this.recordingId,
    required this.dailyGrams,
    required this.cumulativeGrams,
    required this.liveChicks,
    required this.dailyFeedKg,
    required this.cumulativeFeedKg,
    this.isDrop = false,
    this.dropPercentage = 0.0,
  });
}

/// Use case untuk menghitung konsumsi pakan per ekor (Feed Intake)
/// baik secara harian maupun kumulatif, serta mendeteksi penurunan nafsu makan (>10%).
class CalculateFeedIntake {
  const CalculateFeedIntake();

  /// Menghitung Feed Intake untuk seluruh riwayat recording.
  /// Mengembalikan [Map] dengan key berupa `recording.day` untuk akses instan O(1).
  Map<int, DailyFeedIntake> execute({
    required List<RecordingData> recordings,
    required int initialCapacity,
    List<HarvestRecord> harvests = const [],
  }) {
    if (recordings.isEmpty || initialCapacity <= 0) {
      return const {};
    }

    // Urutkan recording secara kronologis ascending berdasarkan hari umur
    final sorted = List<RecordingData>.from(recordings)
      ..sort((a, b) => a.day.compareTo(b.day));

    final Map<int, DailyFeedIntake> results = {};
    int cumulativeDeaths = 0;
    double cumulativeFeedSacks = 0.0;
    double previousDayFIGrams = 0.0;

    for (int i = 0; i < sorted.length; i++) {
      final rec = sorted[i];

      // 1. Akumulasi mortalitas & pakan s/d hari ini
      cumulativeDeaths += rec.mortality;
      cumulativeFeedSacks += rec.feedSack;

      // 2. Akumulasi ayam panen parsial s/d hari ini
      final cumulativeHarvested = harvests
          .where((h) => h.day <= rec.day)
          .fold<int>(0, (sum, h) => sum + h.chicks);

      // 3. Sisa populasi ayam hidup hari ini
      final liveChicks = (initialCapacity - cumulativeDeaths - cumulativeHarvested)
          .clamp(0, initialCapacity);

      // 4. Konversi pakan ke kilogram (1 sak = 50 kg)
      final dailyFeedKg = rec.feedSack * 50.0;
      final cumulativeFeedKg = cumulativeFeedSacks * 50.0;

      // 5. Kalkulasi Feed Intake (gram per ekor)
      final dailyGrams = liveChicks > 0 ? (dailyFeedKg * 1000.0) / liveChicks : 0.0;
      final cumulativeGrams =
          liveChicks > 0 ? (cumulativeFeedKg * 1000.0) / liveChicks : 0.0;

      // 6. Deteksi penurunan nafsu makan (drop > 10% dibanding hari sebelumnya)
      bool isDrop = false;
      double dropPct = 0.0;
      if (previousDayFIGrams > 0.0 && dailyGrams < (previousDayFIGrams * 0.9)) {
        isDrop = true;
        dropPct = ((previousDayFIGrams - dailyGrams) / previousDayFIGrams) * 100.0;
      }

      results[rec.day] = DailyFeedIntake(
        day: rec.day,
        recordingId: rec.id,
        dailyGrams: dailyGrams,
        cumulativeGrams: cumulativeGrams,
        liveChicks: liveChicks,
        dailyFeedKg: dailyFeedKg,
        cumulativeFeedKg: cumulativeFeedKg,
        isDrop: isDrop,
        dropPercentage: dropPct,
      );

      // Simpan nilai hari ini sebagai referensi hari berikutnya jika pakan > 0
      if (dailyGrams > 0.0) {
        previousDayFIGrams = dailyGrams;
      }
    }

    return results;
  }
}
