/// Model data untuk kalkulasi ADG (Average Daily Gain) harian
class DailyADGData {
  final int day; // Hari ke- (umur ayam)
  final DateTime date; // Tanggal recording
  final int weightGram; // Bobot rata-rata sampling hari ini (gram)
  final int previousWeightGram; // Bobot sampling sebelumnya (gram)
  final int previousDay; // Hari sampling sebelumnya
  final double dailyGainGram; // ADG interval sejak timbang sebelumnya (gram/ekor/hari)
  final double cumulativeADGGram; // ADG kumulatif sejak DOC masuk (gram/ekor/hari)
  final String status; // 'Optimal' | 'Standar' | 'Lambat'
  final String statusDescription; // Penjelasan singkat status

  const DailyADGData({
    required this.day,
    required this.date,
    required this.weightGram,
    required this.previousWeightGram,
    required this.previousDay,
    required this.dailyGainGram,
    required this.cumulativeADGGram,
    required this.status,
    required this.statusDescription,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'date': date.toIso8601String(),
        'weight_gram': weightGram,
        'previous_weight_gram': previousWeightGram,
        'previous_day': previousDay,
        'daily_gain_gram': dailyGainGram,
        'cumulative_adg_gram': cumulativeADGGram,
        'status': status,
        'status_description': statusDescription,
      };
}
