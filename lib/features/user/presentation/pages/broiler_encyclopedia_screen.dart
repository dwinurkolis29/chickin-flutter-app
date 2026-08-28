import 'package:flutter/material.dart';
import 'package:recording_app/core/components/cards/app_card.dart';
import 'package:recording_app/core/components/header/app_header.dart';
import 'package:recording_app/core/theme/app_colors.dart';
import 'package:recording_app/core/theme/app_theme.dart';

/// Model data untuk setiap entri istilah/rumus di ensiklopedia.
class EncyclopediaItem {
  final String id;
  final String abbreviation;
  final String title;
  final String category; // 'fcr', 'growth', 'mortality', 'performance', 'finance'
  final String quickDefinition;
  final String? formulaText;
  final String? formulaExplanation;
  final String? example;
  final List<EncyclopediaThreshold> thresholds;
  final String? farmerTip;
  final IconData icon;

  const EncyclopediaItem({
    required this.id,
    required this.abbreviation,
    required this.title,
    required this.category,
    required this.quickDefinition,
    this.formulaText,
    this.formulaExplanation,
    this.example,
    this.thresholds = const [],
    this.farmerTip,
    required this.icon,
  });
}

class EncyclopediaThreshold {
  final String label;
  final String valueRange;
  final String meaning;
  final Color color;
  final Color bgColor;

  const EncyclopediaThreshold({
    required this.label,
    required this.valueRange,
    required this.meaning,
    required this.color,
    required this.bgColor,
  });
}

/// Halaman Ensiklopedia Broiler: Kamus istilah, rumus, dan panduan praktis
/// yang didesain ramah dan mudah dipahami untuk peternak mandiri dewasa hingga senior.
class BroilerEncyclopediaScreen extends StatefulWidget {
  const BroilerEncyclopediaScreen({super.key});

  @override
  State<BroilerEncyclopediaScreen> createState() => _BroilerEncyclopediaScreenState();
}

class _BroilerEncyclopediaScreenState extends State<BroilerEncyclopediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final Set<String> _expandedItems = {'fcr', 'ip'}; // Buka FCR & IP secara default

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  static const List<EncyclopediaItem> _items = [
    EncyclopediaItem(
      id: 'fcr',
      abbreviation: 'FCR',
      title: 'FCR (Feed Conversion Ratio / Konversi Pakan)',
      category: 'fcr',
      icon: Icons.scale_rounded,
      quickDefinition: 'Berapa kilogram pakan yang dihabiskan untuk menghasilkan 1 kilogram bobot daging ayam. Makin KECIL angkanya, makin HEMAT pakan dan makin untung peternak.',
      formulaText: 'FCR = Total Pakan Dikonsumsi (kg) ÷ Total Bobot Ayam (kg)',
      formulaExplanation: 'Total pakan dihitung dari pakan yang diberikan dikurangi sisa pakan. Total bobot dihitung dari jumlah ayam hidup dikalikan berat rata-rata timbangan.',
      example: 'Peternak menghabiskan pakan 1.700 kg untuk populasi ayam dengan total berat 1.000 kg.\nFCR = 1.700 ÷ 1.000 = 1,70.',
      thresholds: [
        EncyclopediaThreshold(
          label: 'Efisien (Bagus)',
          valueRange: 'FCR ≤ 1,80',
          meaning: 'Pakan terserap optimal, tidak banyak tercecer, pertumbuhan daging sangat baik.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Cukup (Waspada)',
          valueRange: '1,81 – 2,20',
          meaning: 'Mendekati batas toleransi. Cek tempat pakan apakah tercecer ke sekam atau suhu kandang terlalu dingin.',
          color: AppColors.fcrWarnText,
          bgColor: AppColors.fcrWarnBg,
        ),
        EncyclopediaThreshold(
          label: 'Boros (Rugi)',
          valueRange: 'FCR > 2,20',
          meaning: 'Pakan boros. Segera periksa kesehatan usus ayam, kualitas pakan, dan sirkulasi udara.',
          color: AppColors.fcrBadText,
          bgColor: AppColors.fcrBadBg,
        ),
      ],
      farmerTip: 'PENTING: Jika di laporan kemitraan tertulis "Konversi Makanan 1.705%", itu artinya FCR 1,705 (BUKAN 170% atau 0,017).',
    ),
    EncyclopediaItem(
      id: 'ip',
      abbreviation: 'IP',
      title: 'IP / EPEF (Indeks Prestasi Pemeliharaan)',
      category: 'performance',
      icon: Icons.emoji_events_outlined,
      quickDefinition: 'Nilai rapor keseluruhan keberhasilan satu periode ternak. Menggabungkan 4 faktor: ayam hidup (daya hidup), bobot ayam, umur panen, dan FCR.',
      formulaText: 'IP = (Daya Hidup % × Bobot Rata-rata kg × 100) ÷ (Umur Panen Hari × FCR)',
      formulaExplanation: 'Makin tinggi nilai IP, makin hebat performa kandang Anda. Standar acuan industri saat ini menargetkan IP di atas 350.',
      example: 'Ayam hidup 96%, bobot panen 1,80 kg, umur panen 35 hari, dan FCR 1,70.\nIP = (96 × 1,80 × 100) ÷ (35 × 1,70) = 17.280 ÷ 59,5 = 290,42.',
      thresholds: [
        EncyclopediaThreshold(
          label: 'Istimewa',
          valueRange: 'IP ≥ 400',
          meaning: 'Performa luar biasa, panen cepat dengan bobot maksimal dan FCR sangat rendah.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Sangat Baik',
          valueRange: '350 – 399',
          meaning: 'Manajemen pemeliharaan sangat baik dan menghasilkan keuntungan memuaskan.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Sedang / Cukup',
          valueRange: '300 – 349',
          meaning: 'Performa standar, masih ada potensi peningkatan di efisiensi pakan atau waktu panen.',
          color: AppColors.fcrWarnText,
          bgColor: AppColors.fcrWarnBg,
        ),
        EncyclopediaThreshold(
          label: 'Kurang',
          valueRange: 'IP < 300',
          meaning: 'Perlu evaluasi menyeluruh: cek bibit DOC, sanitasi kandang, mortalitas, dan FCR.',
          color: AppColors.fcrBadText,
          bgColor: AppColors.fcrBadBg,
        ),
      ],
      farmerTip: 'IP tinggi dicapai jika ayam cepat besar (umur muda sudah dipanen), sedikit ayam mati, dan pakan irit.',
    ),
    EncyclopediaItem(
      id: 'bw',
      abbreviation: 'BW',
      title: 'BW (Body Weight / Bobot Badan)',
      category: 'growth',
      icon: Icons.fitness_center_rounded,
      quickDefinition: 'Berat badan rata-rata per ekor ayam yang diperoleh dari hasil timbang sampling atau timbang total.',
      formulaText: 'BW (kg) = Total Timbangan Sampel (kg) ÷ Jumlah Ayam yang Ditimbang (ekor)',
      formulaExplanation: 'Lakukan penimbangan rutin minimal 1 minggu sekali pada 50–100 ekor ayam di berbagai sudut kandang.',
      example: 'Menimbang 100 ekor ayam menghasilkan berat total 150 kg.\nBW = 150 ÷ 100 = 1,50 kg (1.500 gram) per ekor.',
      farmerTip: 'Lakukan penimbangan pada waktu yang sama (misal pagi hari sebelum pakan ditambah) agar hasilnya konsisten.',
    ),
    EncyclopediaItem(
      id: 'adg',
      abbreviation: 'ADG',
      title: 'ADG (Average Daily Gain / Pertambahan Bobot Harian)',
      category: 'growth',
      icon: Icons.trending_up_rounded,
      quickDefinition: 'Berapa gram berat ayam bertambah dalam satu hari. Membantu mengetahui apakah pertumbuhan ayam sedang lancar atau melambat.',
      formulaText: 'ADG (gram/hari) = ((Bobot Akhir kg - Bobot Awal kg) × 1.000) ÷ Jumlah Hari',
      formulaExplanation: 'Menghitung kenaikan berat badan antar periode penimbangan (misal minggu 1 ke minggu 2).',
      example: 'Umur 14 hari bobot 350 gram (0,35 kg), umur 21 hari bobot 700 gram (0,70 kg).\nKenaikan = 350 gram dalam 7 hari.\nADG = 350 ÷ 7 = 50 gram/ekor/hari.',
      thresholds: [
        EncyclopediaThreshold(
          label: 'Pertumbuhan Baik',
          valueRange: 'ADG ≥ 50 g/hari (umur > 14 hari)',
          meaning: 'Ayam tumbuh cepat dan nafsu makan sangat baik.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Pertumbuhan Lambat',
          valueRange: 'ADG < 35 g/hari',
          meaning: 'Pertumbuhan terhambat. Cek kecukupan tempat pakan/minum atau gejala penyakit.',
          color: AppColors.fcrBadText,
          bgColor: AppColors.fcrBadBg,
        ),
      ],
      farmerTip: 'Jika ADG turun mendadak di minggu ke-3 atau ke-4, periksa ventilasi udara (amonia) dan kepadatan kandang.',
    ),
    EncyclopediaItem(
      id: 'fi',
      abbreviation: 'FI',
      title: 'FI (Feed Intake / Konsumsi Pakan)',
      category: 'fcr',
      icon: Icons.inventory_2_outlined,
      quickDefinition: 'Jumlah pakan yang benar-benar dimakan oleh ayam dalam kurun waktu harian atau mingguan.',
      formulaText: 'Pakan Dimakan (kg) = Pakan Diberikan (kg) - Pakan Sisa di Tempat (kg)',
      formulaExplanation: '1 sak pakan standar pabrik setara dengan 50 kg. Hitung pakan habis per ekor per hari untuk melihat nafsu makan.',
      example: 'Diberi pakan 4 sak (200 kg), sore hari sisa 20 kg.\nPakan terkonsumsi = 200 - 20 = 180 kg.',
      farmerTip: 'Jangan biarkan pakan berkerak atau berjamur di dasar tempat pakan karena bisa meracuni saluran cerna ayam.',
    ),
    EncyclopediaItem(
      id: 'mortality',
      abbreviation: 'Mortalitas',
      title: 'Mortalitas (Tingkat Kematian)',
      category: 'mortality',
      icon: Icons.heart_broken_outlined,
      quickDefinition: 'Persentase jumlah ayam yang mati alami selama masa pemeliharaan dibanding populasi awal DOC masuk.',
      formulaText: 'Mortalitas (%) = (Jumlah Ayam Mati ÷ Populasi Awal DOC) × 100%',
      formulaExplanation: 'Catat kematian harian setiap pagi dan sore hari.',
      example: 'Populasi awal 10.000 ekor, total ayam mati selama periode ada 300 ekor.\nMortalitas = (300 ÷ 10.000) × 100% = 3,0%.',
      thresholds: [
        EncyclopediaThreshold(
          label: 'Aman / Bagus',
          valueRange: 'Mortalitas ≤ 4,0%',
          meaning: 'Kesehatan ayam terjaga dengan biosekuriti dan brooding yang baik.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Tinggi (Waspada)',
          valueRange: 'Mortalitas > 5,0%',
          meaning: 'Kematian tinggi. Periksa brooding minggu pertama, kualitas air minum, dan jadwal vaksin.',
          color: AppColors.fcrBadText,
          bgColor: AppColors.fcrBadBg,
        ),
      ],
      farmerTip: 'Kematian di minggu pertama (hari 1–7) targetnya < 1%. Jika lebih, evaluasi suhu brooding dan kualitas DOC.',
    ),
    EncyclopediaItem(
      id: 'culling',
      abbreviation: 'Culling',
      title: 'Culling (Afkir / Seleksi Ayam)',
      category: 'mortality',
      icon: Icons.remove_circle_outline_rounded,
      quickDefinition: 'Pemisahan/pengeluaran ayam yang kerdil, cacat, atau sakit parah dari populasi utama agar tidak membuang pakan dan tidak menular.',
      formulaText: 'Culling (%) = (Jumlah Ayam Afkir ÷ Populasi Awal DOC) × 100%',
      formulaExplanation: 'Membedakan catatan mati alami dan afkir sangat penting untuk audit manajemen kandang.',
      example: 'Dari 10.000 ekor DOC, disisihkan 100 ekor ayam kerdil/cacat.\nCulling = (100 ÷ 10.000) × 100% = 1,0%.',
      farmerTip: 'Segera afkir ayam yang kerdil sedini mungkin (hari 7–14) karena ayam kerdil tetap makan tetapi tidak akan menambah daging.',
    ),
    EncyclopediaItem(
      id: 'livability',
      abbreviation: 'Livability',
      title: 'Livability (Daya Hidup / Tingkat Hidup)',
      category: 'mortality',
      icon: Icons.health_and_safety_outlined,
      quickDefinition: 'Persentase ayam yang bertahan hidup sehat dari awal tebar DOC hingga masa panen tiba.',
      formulaText: 'Daya Hidup (%) = (Sisa Ayam Hidup ÷ Populasi Awal DOC) × 100%',
      formulaExplanation: 'Daya Hidup = 100% dikurangi total deplesi (kematian + afkir).',
      example: 'Populasi awal 10.000 ekor, ayam yang hidup saat panen 9.600 ekor.\nDaya Hidup = (9.600 ÷ 10.000) × 100% = 96,0%.',
      thresholds: [
        EncyclopediaThreshold(
          label: 'Target Ideal',
          valueRange: 'Livability ≥ 95,0%',
          meaning: 'Daya hidup sangat tinggi, populasi panen terjaga maksimal.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Rendah',
          valueRange: 'Livability < 93,0%',
          meaning: 'Banyak populasi hilang, pendapatan panen akan berkurang drastis.',
          color: AppColors.fcrBadText,
          bgColor: AppColors.fcrBadBg,
        ),
      ],
      farmerTip: 'Livability 96% ke atas adalah kunci utama mendapatkan nilai IP di atas 350.',
    ),
    EncyclopediaItem(
      id: 'uniformity',
      abbreviation: 'Uniformity',
      title: 'Keseragaman Bobot (Uniformity & CV)',
      category: 'growth',
      icon: Icons.groups_rounded,
      quickDefinition: 'Seberapa rata ukuran bobot ayam di dalam satu kandang. Ayam yang seragam membuat waktu panen serentak dan harga jual lebih tinggi.',
      formulaText: 'Keseragaman (%) = (Jumlah Ayam Masuk Rentang ±10% Rata-rata ÷ Total Sampel) × 100%',
      formulaExplanation: 'Jika bobot rata-rata 2,0 kg, rentang targetnya adalah 1,80 kg sampai 2,20 kg.',
      example: 'Dari 100 ekor sampel timbangan, ada 85 ekor yang beratnya antara 1,80 kg – 2,20 kg.\nKeseragaman = 85%.',
      thresholds: [
        EncyclopediaThreshold(
          label: 'Sangat Seragam',
          valueRange: 'Uniformity ≥ 85%',
          meaning: 'Ukuran ayam merata, pembeli/bakul sangat menyukai flok ini.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Kurang Seragam',
          valueRange: 'Uniformity < 75%',
          meaning: 'Banyak ayam terlalu besar atau terlalu kecil. Cek jarak sekat dan distribusi tempat pakan.',
          color: AppColors.fcrWarnText,
          bgColor: AppColors.fcrWarnBg,
        ),
      ],
      farmerTip: 'Keseragaman dibentuk sejak brooding umur 1–10 hari melalui pemerataan lampu pemanas dan ketersediaan tempat pakan/minum.',
    ),
    EncyclopediaItem(
      id: 'hpp',
      abbreviation: 'HPP',
      title: 'HPP (Harga Pokok Produksi per kg Daging)',
      category: 'finance',
      icon: Icons.monetization_on_outlined,
      quickDefinition: 'Berapa modal rupiah yang dikeluarkan peternak untuk menghasilkan 1 kilogram daging ayam hidup sampai panen.',
      formulaText: 'HPP (Rp/kg) = Total Seluruh Biaya Produksi (Rp) ÷ Total Bobot Panen Terjual (kg)',
      formulaExplanation: 'Komponen biaya mencakup: Pembelian DOC bibit + Pakan + Obat/Vaksin/Vitamin + Listrik + Gas/Kayu Pemanas + Tenaga Kerja + Sewa/Penyusutan Kandang.',
      example: 'Total seluruh biaya Rp150.000.000 untuk panen total 8.000 kg daging ayam.\nHPP = Rp150.000.000 ÷ 8.000 = Rp18.750 per kg.',
      farmerTip: 'Jika harga pasar ayam hidup di atas HPP (misal Rp21.000/kg vs HPP Rp18.750/kg), maka peternak untung Rp2.250 per kg.',
    ),
    EncyclopediaItem(
      id: 'feedcost',
      abbreviation: 'Feed Cost',
      title: 'Biaya Pakan per kg Pertambahan Bobot',
      category: 'finance',
      icon: Icons.payments_outlined,
      quickDefinition: 'Berapa uang pakan yang dihabiskan untuk menaikkan 1 kg bobot ayam.',
      formulaText: 'Biaya Pakan per kg Daging = Nilai FCR × Harga Pakan per kg (Rp)',
      formulaExplanation: 'Karena pakan menyumbang 65%–75% dari total modal ternak, menurunkan FCR sedikit saja akan menghemat jutaan rupiah.',
      example: 'FCR tercapai 1,65 dengan harga pakan Rp8.500/kg.\nBiaya pakan = 1,65 × Rp8.500 = Rp14.025 per kg daging.',
      farmerTip: 'Turun FCR sebesar 0,05 pada populasi 10.000 ekor bisa menghemat pakan hingga hampir 1 ton (Rp8.000.000+)!',
    ),
    EncyclopediaItem(
      id: 'density',
      abbreviation: 'Kepadatan',
      title: 'Kepadatan Kandang (Stocking Density)',
      category: 'growth',
      icon: Icons.grid_view_rounded,
      quickDefinition: 'Beban berat ayam hidup yang ditampung per meter persegi (m²) luas lantai kandang.',
      formulaText: 'Kepadatan (kg/m²) = Total Berat Ayam Hidup (kg) ÷ Luas Lantai Kandang (m²)',
      formulaExplanation: 'Standar Open House (Kandang Terbuka): 28–32 kg/m² (~14–16 ekor/m²).\nStandar Closed House (Kandang Tertutup): 38–42 kg/m² (~18–21 ekor/m²).',
      example: 'Kandang ukuran 100 m² menampung total bobot ayam 3.000 kg.\nKepadatan = 3.000 ÷ 100 = 30 kg/m² (Sesuai batas aman open house).',
      farmerTip: 'Kandang yang terlalu padat membuat ayam kepanasan, FCR membengkak, dan sirkulasi amonia berbahaya bagi pernapasan ayam.',
    ),
    EncyclopediaItem(
      id: 'waterfeed',
      abbreviation: 'Air : Pakan',
      title: 'Rasio Konsumsi Air terhadap Pakan',
      category: 'fcr',
      icon: Icons.water_drop_outlined,
      quickDefinition: 'Perbandingan banyaknya liter air minum yang diminum ayam dibanding kilogram pakan yang dihabiskan.',
      formulaText: 'Rasio Air : Pakan = Total Air Minum (Liter) ÷ Total Pakan (kg)',
      formulaExplanation: 'Pada kondisi suhu nyaman (21–24°C), ayam broiler normalnya minum 1,6 hingga 2,0 liter air untuk setiap 1 kg pakan.',
      example: 'Ayam makan pakan 100 kg dan minum air 180 liter.\nRasio = 180 ÷ 100 = 1,80 (Kondisi normal).',
      thresholds: [
        EncyclopediaThreshold(
          label: 'Normal',
          valueRange: '1,6 – 2,0 liter/kg pakan',
          meaning: 'Suhu kandang nyaman dan pencernaan ayam bekerja baik.',
          color: AppColors.fcrGoodText,
          bgColor: AppColors.fcrGoodBg,
        ),
        EncyclopediaThreshold(
          label: 'Tinggi (Waspada)',
          valueRange: '> 2,5 liter/kg pakan',
          meaning: 'Ayam kepanasan (heat stress) sehingga banyak minum, atau ada nipple air bocor, atau diare basah.',
          color: AppColors.fcrBadText,
          bgColor: AppColors.fcrBadBg,
        ),
      ],
      farmerTip: 'Jika sekam kandang cepat basah dan becek, segera cek rasio air minum dan pipa nipple.',
    ),
  ];

  List<EncyclopediaItem> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 'all' || item.category == _selectedCategory;
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.abbreviation.toLowerCase().contains(query) ||
          item.quickDefinition.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Ensiklopedia Broiler',
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: CustomScrollView(
              slivers: [
                // ── 1. Banner Sambutan Ramah Peternak ───────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary,
                            cs.primary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.onPrimary.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: cs.onPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kamus & Rumus Peternak',
                                  style: tt.titleMedium?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Penjelasan arti istilah, rumus mudah, dan contoh nyata agar hasil panen broiler makin untung.',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 2. Search Bar Besar & Jelas ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari istilah (contoh: FCR, IP, Bobot, Pakan)...',
                        hintStyle: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: cs.primary,
                          size: 24,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 3. Category Filter Chips ─────────────────────────────────
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Semua Istilah', Icons.all_inclusive_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip('fcr', 'Pakan & FCR', Icons.inventory_2_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip('performance', 'Performa & IP', Icons.emoji_events_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip('growth', 'Bobot & Tumbuh', Icons.show_chart_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip('mortality', 'Kematian & Hidup', Icons.health_and_safety_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip('finance', 'Uang & HPP', Icons.monetization_on_outlined),
                      ],
                    ),
                  ),
                ),

                // ── 4. List Kartu Ensiklopedia ───────────────────────────────
                if (_filteredItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Istilah tidak ditemukan',
                            style: tt.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coba kata kunci lain seperti "FCR", "IP", "Mortalitas", atau "Pakan".',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _filteredItems[index];
                          final isExpanded = _expandedItems.contains(item.id);
                          return _buildEncyclopediaCard(context, item, isExpanded);
                        },
                        childCount: _filteredItems.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String categoryId, String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isSelected = _selectedCategory == categoryId;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = categoryId),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
      ),
      label: Text(label),
      labelStyle: tt.labelMedium?.copyWith(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: cs.surfaceContainer,
      selectedColor: cs.primary,
      checkmarkColor: cs.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        side: BorderSide(
          color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false,
    );
  }

  // ── Encyclopedia Item Card ────────────────────────────────────────────────
  Widget _buildEncyclopediaCard(
    BuildContext context,
    EncyclopediaItem item,
    bool isExpanded,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _toggleExpand(item.id),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Badge Singkatan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      ),
                      child: Column(
                        children: [
                          Icon(item.icon, color: cs.primary, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            item.abbreviation,
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Judul dan Definisi Ringkas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.quickDefinition,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Panah Expand
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurfaceVariant,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              // Detail Expanded
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Rumus
                      if (item.formulaText != null) ...[
                        Text(
                          'Rumus Sederhana:',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.formulaText!,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.formulaExplanation != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.formulaExplanation!,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 2. Contoh Nyata
                      if (item.example != null) ...[
                        Text(
                          'Contoh Nyata:',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                          ),
                          child: Text(
                            item.example!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 3. Standar Acuan & Arti Angka (Thresholds)
                      if (item.thresholds.isNotEmpty) ...[
                        Text(
                          'Arti Angka & Standar:',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final t in item.thresholds) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: t.bgColor,
                              borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: t.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.pillRadius,
                                        ),
                                      ),
                                      child: Text(
                                        t.label,
                                        style: tt.labelSmall?.copyWith(
                                          color: t.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        t.valueRange,
                                        style: tt.labelSmall?.copyWith(
                                          color: t.color,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.meaning,
                                  style: tt.bodySmall?.copyWith(
                                    color: t.color,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],

                      // 4. Tips Peternak
                      if (item.farmerTip != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTheme.rowRadius),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                size: 20,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.farmerTip!,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
