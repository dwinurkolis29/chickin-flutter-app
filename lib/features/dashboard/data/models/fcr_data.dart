// Model untuk menyimpan data FCR per minggu
class FCRData {
  final int mingguKe;
  final double totalPakan; // dalam kg (cumulative)
  final int sisaAyam;
  final double beratAyam; // dalam kg (total weight)
  final double fcr;

  const FCRData({
    required this.mingguKe,
    required this.totalPakan,
    required this.sisaAyam,
    required this.beratAyam,
    required this.fcr,
  });

  // Konversi ke JSON untuk Firestore
  Map<String, dynamic> toJson() => {
        'minggu_ke': mingguKe,
        'total_pakan': totalPakan,
        'sisa_ayam': sisaAyam,
        'berat_ayam': beratAyam,
        'fcr': fcr,
      };
}
