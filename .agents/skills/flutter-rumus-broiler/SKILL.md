---
name: flutter-rumus-broiler
description: Spesifikasi standar dan implementasi formula KPI pemeliharaan ayam broiler (FCR, IP/EPEF, ADG, BW, FI, Livability, Depletion, Uniformity, CV, HPP, Feed Cost per kg Gain, dll.) untuk arsitektur Flutter/Dart, use case domain, validasi data, dan integrasi AI/mitra peternakan.
---

# Broiler Production KPI & Formula Specification — Flutter/Dart Standard

Gunakan dokumen skill ini sebagai standar acuan matematika, domain logic, validasi data, dan representasi bisnis peternakan broiler di aplikasi Chickin (BroilerKu).

---

## 0. Prinsip Utama Arsitektur KPI

1. **Raw Data First (Jangan Hanya Menyimpan Nilai Akhir)**:
   - Simpan data mentah faktual di Firestore/local database: `feed_given_kg`, `feed_remaining_kg`, `mortality_count`, `culling_count`, `population_initial`, `sample_total_weight_kg`, `sample_count`, `cost`, `harvest_weight_kg`.
   - Hitung derived KPI (`FCR`, `ADG`, `Livability`, `IP`, `HPP`, `Profit`) melalui Domain Use Case secara murni (*pure functions*).
   - Manfaat: Formula dapat disempurnakan tanpa merusak histori, AI agent dapat mengaudit data, dan kalkulasi dapat diverifikasi ulang kapan saja.

2. **Pola 3-Lapisan Arsitektur KPI**:
   ```
   [RAW DATA]           → Pencatatan harian, sampling timbang, panen, biaya operasional
        ↓
   [DERIVED METRICS]    → Kalkulasi BW, ADG, FI, FCR, Depletion, Livability, IP, HPP
        ↓
   [BUSINESS INSIGHTS]  → Evaluasi performa, deteksi anomali pertumbuhan, saran aksi
   ```

3. **Immutabilitas & Zero-Division Safety**:
   - Semua fungsi kalkulator wajib memperlakukan list data sebagai immutable (`List.from(...)`).
   - Setiap operasi pembagian **WAJIB** dipagari guard kondisi penyebut nol (`if (denominator <= 0) return 0.0`).

---

## 1. Tabel Terminologi, Simbol & Satuan Standar

| KPI | Nama Panjang | Satuan | Keterangan |
|---|---|---|---|
| **BW** | Body Weight (Bobot Badan) | `kg/ekor` atau `gram/ekor` | Rata-rata bobot hidup ayam |
| **ADG** | Average Daily Gain | `gram/ekor/hari` | Pertambahan bobot harian rata-rata |
| **FI** | Feed Intake (Konsumsi Pakan) | `kg/ekor`, `gram/ekor/hari` | Pakan yang benar-benar dikonsumsi |
| **FCR** | Feed Conversion Ratio | `kg pakan / kg daging` | Rasio pakan terhadap pertambahan bobot |
| **Livability** | Tingkat Hidup (Daya Hidup) | `%` | Persentase ayam hidup dari populasi awal |
| **Mortality** | Kematian | `%` atau `ekor` | Ayam mati alami |
| **Culling** | Afkir | `%` atau `ekor` | Ayam kerdil/sakit yang disingkirkan |
| **Depletion** | Deplesi (Penyusutan) | `%` | Total mortalitas + culling terhadap populasi awal |
| **IP / PEF / EPEF** | Indeks Performa / Production Efficiency Factor | *Indeks* (tanpa satuan) | Indikator komposit performa pemeliharaan |
| **Uniformity** | Keseragaman | `%` | Persentase populasi di rentang target (±10% BW) |
| **CV BW** | Coefficient of Variation | `%` | Standar deviasi bobot terhadap rata-rata |
| **Feed Cost/kg Gain**| Biaya Pakan per kg Daging | `Rp/kg gain` | Biaya pakan untuk menghasilkan 1 kg bobot |
| **HPP** | Harga Pokok Produksi | `Rp/kg bobot hidup` | Total biaya dibagi total kg panen terjual |
| **Water Intake** | Konsumsi Air Minum | `liter/ekor/hari` | Rata-rata air minum per ayam-hari |
| **Water/Feed Ratio**| Rasio Air terhadap Pakan | `liter / kg pakan` | Proporsi konsumsi air vs pakan |
| **Stocking Density**| Kepadatan Kandang | `kg/m²` atau `ekor/m²` | Beban populasi terhadap luas lantai kandang |

---

## 2. Aturan Kritis: Konversi Makanan & FCR dari Laporan Mitra

> [!IMPORTANT]
> **FCR ADALAH RASIO, BUKAN PERSENTASE!**
> Jika pada laporan mitra/kemitraan tertulis `"Konversi Makanan = 1.705%"`, angka tersebut adalah notasi penulisan mitra untuk **FCR = 1.705** (artinya butuh 1.705 kg pakan untuk 1 kg bobot ayam).
> **DILARANG** mengonversi 1.705% menjadi `0.01705` atau mengalikannya dengan 100 menjadi `170.5%`.

### Rule Normalisasi Data Mitra:
```dart
class ExternalMetricNormalizer {
  /// Menormalkan nilai FCR dari input teks atau laporan mitra
  static double normalizeFCR(dynamic rawValue) {
    if (rawValue == null) return 0.0;
    if (rawValue is num) return rawValue.toDouble();
    
    final cleanStr = rawValue.toString().replaceAll('%', '').trim().replaceAll(',', '.');
    return double.tryParse(cleanStr) ?? 0.0;
  }
}
```

---

## 3. Formula & Implementasi Domain Dart

### 3.1 Body Weight (BW)
Rata-rata bobot hidup per ekor.
- **Formula Populasi Penuh**: $\text{BW (kg)} = \frac{\text{Total Live Weight (kg)}}{\text{Live Bird Count}}$
- **Formula Sampling**: $\text{BW (kg)} = \frac{\text{Sample Total Weight (kg)}}{\text{Sample Count}}$

```dart
double calculateAverageWeight({
  required double totalSampleWeightKg,
  required int sampleCount,
}) {
  if (sampleCount <= 0) return 0.0;
  return totalSampleWeightKg / sampleCount;
}
```

---

### 3.2 Average Daily Gain (ADG)
Rata-rata pertambahan bobot hidup harian dalam gram/ekor/hari.
$$\text{ADG (g/ekor/hari)} = \frac{(\text{BW}_{t2}\text{ (kg)} - \text{BW}_{t1}\text{ (kg)}) \times 1000}{t_2 - t_1}$$

```dart
double calculateADG({
  required double finalWeightKg,
  required double initialWeightKg,
  required int durationDays,
}) {
  if (durationDays <= 0) return 0.0;
  return ((finalWeightKg - initialWeightKg) * 1000.0) / durationDays;
}
```

---

### 3.3 Feed Intake (FI) & Bird-Days
Konsumsi pakan riil = pakan diberikan $-$ sisa pakan.

$$\text{Feed Consumed (kg)} = \text{Feed Given (kg)} - \text{Feed Remaining (kg)}$$
$$\text{FI per Bird (kg/ekor)} = \frac{\text{Feed Consumed (kg)}}{\text{Relevant Population}}$$
$$\text{FI per Bird-Day (g/ekor/hari)} = \frac{\text{Feed Consumed (kg)} \times 1000}{\text{Bird-Days}}$$

```dart
double calculateFeedConsumed({
  required double feedGivenKg,
  required double feedRemainingKg,
}) {
  return (feedGivenKg - feedRemainingKg).clamp(0.0, double.infinity);
}

double calculateFeedIntakePerBirdDay({
  required double totalFeedConsumedKg,
  required int birdDays,
}) {
  if (birdDays <= 0) return 0.0;
  return (totalFeedConsumedKg * 1000.0) / birdDays;
}
```

---

### 3.4 Feed Conversion Ratio (FCR)
$$\text{FCR} = \frac{\text{Total Feed Consumed (kg)}}{\text{Total Weight Gain (kg)}} \quad \text{atau} \quad \text{FCR} = \frac{\text{Total Feed Consumed (kg)}}{\text{Final Biomass (kg)}}$$
Di mana $\text{Final Biomass} = \text{Sisa Ayam Hidup} \times \text{Bobot Rata-rata (kg)}$.

```dart
double calculateFCR({
  required double totalFeedConsumedKg,
  required double totalBiomassKg,
}) {
  if (totalBiomassKg <= 0.0) return 0.0;
  return totalFeedConsumedKg / totalBiomassKg;
}
```

#### FCR Evaluation Threshold:
* $\text{FCR} \le 1.80 \to$ **Efisien** (`AppColors.fcrGoodBg`, `AppColors.fcrGoodText`)
* $1.80 < \text{FCR} \le 2.20 \to$ **Cukup / Peringatan** (`AppColors.fcrWarnBg`, `AppColors.fcrWarnText`)
* $\text{FCR} > 2.20 \to$ **Boros** (`AppColors.fcrBadBg`, `AppColors.fcrBadText`)

---

### 3.5 Livability & Depletion
$$\text{Depletion (\%)} = \frac{\text{Mortality Count} + \text{Culling Count}}{\text{Initial Population}} \times 100$$
$$\text{Livability (\%)} = \frac{\text{Live Bird Count}}{\text{Initial Population}} \times 100 = 100 - \text{Depletion (\% Faust)}$$

```dart
double calculateLivability({
  required int liveBirdCount,
  required int initialPopulation,
}) {
  if (initialPopulation <= 0) return 0.0;
  return ((liveBirdCount / initialPopulation) * 100.0).clamp(0.0, 100.0);
}

double calculateDepletion({
  required int mortalityCount,
  required int cullingCount,
  required int initialPopulation,
}) {
  if (initialPopulation <= 0) return 0.0;
  return (((mortalityCount + cullingCount) / initialPopulation) * 100.0).clamp(0.0, 100.0);
}
```

---

### 3.6 Indeks Performa (IP / PEF / EPEF)
Indikator efisiensi produksi gabungan standar industri broiler internasional (Aviagen / Cobb standard).

$$\text{IP} = \frac{\text{Livability (\%)} \times \text{BW (kg)} \times 100}{\text{Umur Panen (Hari)} \times \text{FCR}}$$

> [!NOTE]
> Karena `Livability` dimasukkan dalam skala persentase (misal `96.0` untuk 96%), formula ini mengalikan lagi dengan 100 sesuai standar rumus PEF komersial.

```dart
double calculateIP({
  required double livabilityPct,
  required double averageWeightKg,
  required int ageDays,
  required double fcr,
}) {
  if (ageDays <= 0 || fcr <= 0.0) return 0.0;
  final denominator = ageDays * fcr;
  if (denominator <= 0.0) return 0.0;
  return (livabilityPct * averageWeightKg * 100.0) / denominator;
}
```

#### Klasifikasi Standar IP:
* $\text{IP} \ge 400 \to$ **Istimewa / Excellent**
* $350 \le \text{IP} < 400 \to$ **Sangat Baik / Good**
* $300 \le \text{IP} < 350 \to$ **Sedang / Average**
* $\text{IP} < 300 \to$ **Kurang / Poor (Perlu Evaluasi Total)**

---

### 3.7 Uniformity & CV Body Weight (Keseragaman Bobot)
Keseragaman flock dinilai berdasarkan persentase sampel dalam rentang target $\pm 10\%$ dari bobot rata-rata ($\text{BW}_{avg}$):
$$\text{Lower Limit} = \text{BW}_{avg} \times 0.90, \quad \text{Upper Limit} = \text{BW}_{avg} \times 1.10$$
$$\text{Uniformity (\%)} = \frac{\text{Jumlah Sampel di Antara Lower \& Upper}}{\text{Total Sampel}} \times 100$$

$$\text{CV (\%)} = \frac{\text{Standar Deviasi Bobot}}{\text{Rata-rata Bobot}} \times 100$$

```dart
class UniformityResult {
  final double uniformityPct;
  final double cvPct;
  final double meanWeightKg;

  const UniformityResult({
    required this.uniformityPct,
    required this.cvPct,
    required this.meanWeightKg,
  });
}

UniformityResult calculateUniformity(List<double> sampleWeightsKg) {
  if (sampleWeightsKg.isEmpty) {
    return const UniformityResult(uniformityPct: 0, cvPct: 0, meanWeightKg: 0);
  }

  final mean = sampleWeightsKg.reduce((a, b) => a + b) / sampleWeightsKg.length;
  if (mean <= 0) {
    return const UniformityResult(uniformityPct: 0, cvPct: 0, meanWeightKg: 0);
  }

  final lower = mean * 0.90;
  final upper = mean * 1.10;
  final inRangeCount = sampleWeightsKg.where((w) => w >= lower && w <= upper).length;
  final uniformityPct = (inRangeCount / sampleWeightsKg.length) * 100.0;

  // Standard Deviation
  final sumSquaredDiff = sampleWeightsKg.fold<double>(
    0.0,
    (prev, w) => prev + (w - mean) * (w - mean),
  );
  final stdDev = sampleWeightsKg.length > 1
      ? Math.sqrt(sumSquaredDiff / (sampleWeightsKg.length - 1))
      : 0.0;
  final cvPct = (stdDev / mean) * 100.0;

  return UniformityResult(
    uniformityPct: uniformityPct,
    cvPct: cvPct,
    meanWeightKg: mean,
  );
}
```

---

### 3.8 Formula Analisis Ekonomi & Finansial

1. **Feed Cost per kg Gain**:
   $$\text{Feed Cost per kg Gain} = \text{FCR} \times \text{Harga Pakan per kg}$$

2. **Harga Pokok Produksi (HPP per kg)**:
   $$\text{HPP (Rp/kg)} = \frac{\text{Total Biaya Produksi (DOC + Pakan + OVK + Listrik + Tenaga Kerja + dll)}}{\text{Total Bobot Panen Terjual (kg)}}$$

3. **Revenue & Gross Profit**:
   $$\text{Revenue} = \text{Total Bobot Terjual (kg)} \times \text{Harga Jual per kg}$$
   $$\text{Gross Profit} = \text{Revenue} - \text{Total Biaya Produksi}$$

4. **Break-Even Selling Price (BEP Harga Jual)**:
   $$\text{BEP (Rp/kg)} = \frac{\text{Total Biaya Produksi}}{\text{Total Bobot Panen Terjual (kg)}} \quad (\equiv \text{HPP})$$

5. **Feed Cost Ratio (%)**:
   $$\text{Feed Cost Ratio (\%)} = \frac{\text{Total Biaya Pakan}}{\text{Total Biaya Produksi}} \times 100$$

```dart
class FinancialKPI {
  static double feedCostPerKgGain({
    required double fcr,
    required double feedPricePerKg,
  }) => fcr * feedPricePerKg;

  static double hppPerKg({
    required double totalCost,
    required double totalLiveWeightSoldKg,
  }) {
    if (totalLiveWeightSoldKg <= 0) return 0.0;
    return totalCost / totalLiveWeightSoldKg;
  }

  static double grossProfit({
    required double revenue,
    required double totalCost,
  }) => revenue - totalCost;

  static double feedCostRatio({
    required double totalFeedCost,
    required double totalCost,
  }) {
    if (totalCost <= 0) return 0.0;
    return (totalFeedCost / totalCost) * 100.0;
  }
}
```

---

### 3.9 Lingkungan & Auxiliary

1. **Water-to-Feed Ratio**:
   $$\text{Water / Feed Ratio} = \frac{\text{Total Konsumsi Air (Liter)}}{\text{Total Konsumsi Pakan (kg)}}$$
   *Normal Range*: `1.6 – 2.0` pada suhu nyaman ($21-24^\circ\text{C}$). Jika $> 2.5$, waspadai suhu kandang terlalu panas, kebocoran nipple, atau gejala enteritis/diare.

2. **Stocking Density**:
   $$\text{Stocking Density (kg/m²)} = \frac{\text{Total Live Weight (kg)}}{\text{House Floor Area (m²)}}$$
   *Standar Open House*: max $28-32\text{ kg/m²}$ | *Closed House*: max $38-42\text{ kg/m²}$.

---

## 4. Prioritas Implementasi BroilerKu (3 Tiers)

```
┌────────────────────────────────────────────────────────────────────────┐
│ TIER 1 — WAJIB (Core Daily & Period Dashboard)                         │
│ • Initial Population & Sisa Ayam   • Daily Mortality & Culling        │
│ • Feed Given, Remaining & Consumed • Body Weight & ADG                 │
│ • FCR (Harian & Kumulatif Mingguan)• Livability & Depletion            │
│ • Indeks Performa (IP / PEF)                                           │
├────────────────────────────────────────────────────────────────────────┤
│ TIER 2 — SANGAT DISARANKAN (Grafik & Advanced Analytics)               │
│ • Uniformity & CV Body Weight       • Feed Intake per Bird-Day         │
│ • Water Intake & Water-Feed Ratio  • Stocking Density (kg/m²)          │
│ • Daily Mortality Spike Alert                                          │
├────────────────────────────────────────────────────────────────────────┤
│ TIER 3 — ANALISIS BISNIS & EKONOMI (Laporan Akhir Panen)               │
│ • DOC, Feed, OVK, & Operational Cost Breakdown                         │
│ • Feed Cost per kg Gain            • HPP per kg Live Weight            │
│ • Revenue, Gross Profit & BEP Price• Feed Cost Ratio (%)               │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Aturan Validasi & Sanity Check (Validator Layer)

Sebelum melakukan kalkulasi, AI agent / use case **WAJIB** menerapkan validasi batas logis (*boundary checking*):

```dart
class BroilerDataValidator {
  static List<String> validateDailyRecord({
    required int initialPopulation,
    required int currentMortality,
    required int currentCulling,
    required double feedGivenKg,
    required double feedRemainingKg,
    required double? avgWeightKg,
  }) {
    final errors = <String>[];

    if (initialPopulation <= 0) {
      errors.add('Populasi awal harus lebih besar dari 0.');
    }
    if (currentMortality < 0) {
      errors.add('Mortalitas tidak boleh bernilai negatif.');
    }
    if (currentCulling < 0) {
      errors.add('Culling tidak boleh bernilai negatif.');
    }
    if (feedGivenKg < 0) {
      errors.add('Pakan diberikan tidak boleh negatif.');
    }
    if (feedRemainingKg < 0) {
      errors.add('Sisa pakan tidak boleh negatif.');
    }
    if (feedRemainingKg > feedGivenKg) {
      errors.add('Sisa pakan ($feedRemainingKg kg) tidak boleh melebihi pakan diberikan ($feedGivenKg kg).');
    }
    if (avgWeightKg != null && avgWeightKg > 10.0) {
      errors.add('Peringatan: Bobot rata-rata ($avgWeightKg kg) tidak wajar untuk ayam broiler.');
    }

    return errors;
  }
}
```

---

## 6. Contoh Perhitungan End-to-End Terverifikasi

### Data Masukan:
- Populasi Awal: `10.000` ekor
- Total Mortalitas: `300` ekor, Total Culling: `100` ekor
- Umur Panen: `35` hari
- Bobot Rata-rata Panen (BW): `1.80` kg/ekor
- Total Bobot Terjual: `17.280` kg ($9.600 \times 1.80$)
- Total Pakan Dikonsumsi: `29.462,4` kg
- FCR Resmi: `1.705` ($29.462,4 \div 17.280$)
- Harga Pakan: `Rp8.000` / kg, Harga Jual Ayam: `Rp22.000` / kg

### Langkah Kalkulasi:
1. **Sisa Ayam Hidup**: $10.000 - 300 - 100 = 9.600$ ekor
2. **Deplesi**: $\frac{300 + 100}{10.000} \times 100 = 4.0\%$
3. **Livability**: $\frac{9.600}{10.000} \times 100 = 96.0\%$
4. **Feed Cost per kg Gain**: $1.705 \times \text{Rp}8.000 = \text{Rp}13.640\text{ / kg gain}$
5. **Indeks Performa (IP)**:
   $$\text{IP} = \frac{1.80 \times 96.0 \times 100}{35 \times 1.705} = \frac{17.280}{59.675} \approx 289.55$$
6. **Revenue**: $17.280\text{ kg} \times \text{Rp}22.000 = \text{Rp}380.160.000$
