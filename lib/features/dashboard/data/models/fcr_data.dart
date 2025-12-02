import 'package:recording_app/features/dashboard/data/models/recording_data.dart';

// Model untuk menyimpan data FCR per minggu
class FCRData {
  final int mingguKe;
  final double totalPakan; // dalam kg
  final int sisaAyam;
  final double beratAyam; // dalam kg
  final double fcr;

  const FCRData({
    required this.mingguKe,
    required this.totalPakan,
    required this.sisaAyam,
    required this.beratAyam,
    required this.fcr,
  });

  // Konfersi ke JSON untuk Firestore
  Map<String, dynamic> toJson() => {
        'minggu_ke': mingguKe,
        'total_pakan': totalPakan,
        'sisa_ayam': sisaAyam,
        'berat_ayam': beratAyam,
        'fcr': fcr,
      };
}

class FCRCalculator {

  // Mengelompokkan data recording per minggu berdasarkan umur ayam (1-7 hari = minggu 1, 8-14 hari = minggu 2, dst)
  static List<FCRData> calculateWeeklyFCR(
      List<RecordingData> recordings, int initialCapacity) {
    if (recordings.isEmpty) return [];

    // Urutkan berdasarkan umur ayam
    recordings.sort((a, b) => a.umur.compareTo(b.umur));

    // Temukan minggu maksimal berdasarkan umur ayam
    final maxAge = recordings.last.umur;
    final maxWeek = (maxAge / 7).ceil();

    List<FCRData> weeklyFCR = [];
    int remainingChickens = initialCapacity;

    // Sebelum perulangan for, tambahkan variabel untuk menyimpan total pakan kumulatif
    double cumulativeFeed = 0;

    for (int week = 1; week <= maxWeek; week++) {
      // Filter data untuk minggu ini (umur 1-7 = minggu 1, 8-14 = minggu 2, dst)
      final weekRecordings = recordings.where((rec) {
        final weekStartAge = ((week - 1) * 7) + 1;
        final weekEndAge = week * 7;
        return rec.umur >= weekStartAge && rec.umur <= weekEndAge;
      }).toList();

      if (weekRecordings.isEmpty) continue;

      // Hitung total pakan (dalam sak) dan ayam mati minggu ini
      double weeklyFeedSack = 0;
      int weeklyDeaths = 0;

      // Dapatkan recording terakhir di minggu ini untuk berat ayam
      RecordingData? lastDayRecording;
      if (weekRecordings.isNotEmpty) {
        weekRecordings.sort((a, b) => a.umur.compareTo(b.umur));
        lastDayRecording = weekRecordings.last;
      }

      for (var rec in weekRecordings) {
        weeklyFeedSack += rec.habisPakan;
        weeklyDeaths += rec.matiAyam;
      }

      // Tambahkan pakan minggu ini ke total kumulatif
      cumulativeFeed += weeklyFeedSack;

      // Update sisa ayam
      remainingChickens -= weeklyDeaths;
      if (remainingChickens < 0) remainingChickens = 0;

      // Hitung FCR
      double fcr = 0;
      double beratAyamKg = 0;

      if (lastDayRecording != null && remainingChickens > 0) {
        // Gunakan berat ayam dari hari terakhir di minggu tersebut
        // Konversi dari gram ke kg dan kalikan dengan jumlah ayam
        beratAyamKg = (lastDayRecording.beratAyam * remainingChickens) / 1000;

        // Konversi pakan dari sak ke kg (1 sak = 50 kg)
        double weeklyFeedKg = weeklyFeedSack * 50;

        // Rumus FCR
        fcr = beratAyamKg > 0 ? weeklyFeedKg / beratAyamKg : 0;
      }

      weeklyFCR.add(FCRData(
        mingguKe: week,
        totalPakan: (cumulativeFeed * 50), // Konversi ke kg
        sisaAyam: remainingChickens,
        fcr: double.parse(fcr.toStringAsFixed(2)),
        beratAyam: double.parse(beratAyamKg.toStringAsFixed(0)),
      ));
    }

    return weeklyFCR;
  }

  // Helper method untuk mendapatkan range umur dalam minggu
  static String getWeekAgeRange(int week) {
    final startAge = (week - 1) * 7;
    final endAge = week * 7 - 1;
    return '$startAge-$endAge hari';
  }
}
