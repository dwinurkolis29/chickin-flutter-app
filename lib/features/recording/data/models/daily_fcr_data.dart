/// Model data untuk kalkulasi FCR harian peternakan
class DailyFCRData {
  final int day; // Hari ke- (umur ayam)
  final DateTime date; // Tanggal recording
  final double dailyFeedKg; // Pakan terkonsumsi hari ini (kg)
  final double cumulativeFeedKg; // Total pakan kumulatif hingga hari ini (kg)
  final int dailyMortality; // Kematian hari ini (ekor)
  final int cumulativeMortality; // Total kematian kumulatif hingga hari ini (ekor)
  final int sisaAyam; // Populasi sisa ayam hidup (ekor)
  final int avgWeightGram; // Bobot rata-rata sampling (gram)
  final double totalBiomassKg; // Total bobot biomassa ayam hidup (kg)
  final double fcr; // FCR kumulatif hingga hari ini

  const DailyFCRData({
    required this.day,
    required this.date,
    required this.dailyFeedKg,
    required this.cumulativeFeedKg,
    required this.dailyMortality,
    required this.cumulativeMortality,
    required this.sisaAyam,
    required this.avgWeightGram,
    required this.totalBiomassKg,
    required this.fcr,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'date': date.toIso8601String(),
        'daily_feed_kg': dailyFeedKg,
        'cumulative_feed_kg': cumulativeFeedKg,
        'daily_mortality': dailyMortality,
        'cumulative_mortality': cumulativeMortality,
        'sisa_ayam': sisaAyam,
        'avg_weight_gram': avgWeightGram,
        'total_biomass_kg': totalBiomassKg,
        'fcr': fcr,
      };
}
