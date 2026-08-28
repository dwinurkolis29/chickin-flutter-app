# Architecture & Enterprise Coding Standards

## 1. Feature-First Structure

- Group code by feature under `lib/features/<feature>/`.
- Standard layers within a feature:
  - `data/`: Models, DTOs, data sources (if any).
  - `domain/`: Pure usecases / calculators (e.g. `calculate_fcr.dart`, `summary_calculator.dart`).
  - `presentation/`: Controllers (`ChangeNotifier`), pages/screens, and feature-specific widgets.
- Keep logic inside the feature unless reused by multiple features.
- Avoid shared modules or premature promotion to `core/` unless strictly necessary.

## 2. State Management

- Primary state management library is **`Provider`** (`ChangeNotifier`, `MultiProvider`, `ProxyProvider`).
- Controllers extend `ChangeNotifier` and manage state transformations, loading flags, error handling, and notifications.
- Widgets consume controllers via `context.watch<T>()` / `Consumer<T>` for UI rebuilds, or `context.read<T>()` for callbacks/events.

## 3. Safe Data Conversion

- **Mandatory**: Always use `safe_convert.dart` (`lib/core/models/safe_convert.dart`) for JSON and Firestore document parsing.
- Available helpers: `asString`, `asInt`, `asIntOrNull`, `asDouble`, `asDoubleOrNull`, `asBool`.
- **Never** perform direct forced cast (`map['field'] as int`) or force unwrap (`map['field']!`) on remote/untrusted payloads to prevent runtime crashes.

## 4. UI & Design Guidelines

- **Dialogs & Snackbars**: Always trigger dialogs through `DialogHelper` (`lib/core/components/dialogs/dialog_helper.dart`).
- **Colors**: Rely on `AppColors` (`lib/core/theme/app_colors.dart`) or `Theme.of(context).colorScheme`.
- **Text Styling**: Use `Theme.of(context).textTheme` with explicit semantic colors for Dark Mode support.
- **Web Density**: Maintain `visualDensity: VisualDensity.standard` in ThemeData to prevent flattened buttons on Flutter Web.

## 5. Coding Principles

- Prefer concrete implementations over interfaces by default.
- Do not over-engineer or add speculative scalability.
- Optimize for team readability and ease of maintenance.

## 6. Navigation & Stream State Persistence (Flicker Prevention)

- **IndexedStack for Tabs**: Gunakan `IndexedStack` (atau `AutomaticKeepAliveClientMixin`) pada shell navigasi bawah agar state seluruh tab tetap hidup di memory dan tidak re-create widget tree saat berpindah tab.
- **StreamBuilder Initial Data**: Selalu sediakan `initialData` dari controller cache (misal: `controller.cachedRecordings`) pada `StreamBuilder` untuk menghindari skeleton loading berkedip saat pengguna kembali ke tab tersebut.

## 7. Form Flexibility & Unit Normalization

- **Flexible Input Toggle**: Form input boleh menyediakan opsi fleksibilitas satuan untuk kenyamanan pengguna (misal: Sak vs Kg pada pakan, Gram vs Kg pada bobot), namun payload yang dikirim ke database/service **WAJIB** ternormalisasi ke satuan baku (misal: Sak dan Gram).
- **Sanity Guards**: Terapkan validator domain real-time (misal: `RecordingValidator`) untuk mencegah angka tidak wajar, outlier ekstrim, atau salah ketik (typo).

## 8. Period Lifecycle & Senior Farmer UX Standards

- **Auto-Activation vs Draft**:
  - Jika belum ada periode aktif, pembuatan periode baru **otomatis langsung aktif** (`isActive = true`).
  - Jika sudah ada periode yang sedang aktif berjalan, pembuatan periode baru **otomatis disimpan sebagai Draft** (`isActive = false`), DILARANG melempar exception/error.
- **Single Active Period Constraint**:
  - Hanya 1 periode yang boleh berstatus aktif dalam satu waktu.
  - Untuk mengaktifkan periode draft, peternak wajib menutup panen periode aktif yang sedang berjalan terlebih dahulu.
- **Editable Active & Draft Periods**:
  - Periode Aktif dan Draft **dapat diedit** datanya (Nama Periode, Kapasitas DOC, Tanggal DOC Masuk).
  - Sisa ayam, umur hari, dan FCR terkalkulasi ulang secara dinamis tanpa merusak integritas catatan harian (recording).
  - Periode yang sudah **Selesai Panen** (`endDate != null`) terkunci permanen (*read-only*).
- **Senior Farmer Form Simplicity**:
  - Hindari form yang membebani peternak berusia lanjut dengan format desimal rumit (misal: "Bobot Awal DOC").
  - Otomatis gunakan standar industri (misal: `0.04 kg` / 40 gram) di balik layar.
  - Form pembuatan periode cukup berfokus pada 3 input esensial: **Nama Periode**, **Tanggal DOC Masuk**, dan **Jumlah DOC (Ekor)**.

## 9. Dialog Standards (Pola "Tentang Aplikasi")

- Seluruh dialog di aplikasi (`BaseDialog`, `ConfirmDialog`, `ErrorDialog`, `PeriodPickerDialog`, `StringPickerDialog`, dan dialog form interaktif) **WAJIB** mengikuti standar visual terpadu:
  1. **Header Icon Badge**: Baris judul dengan icon bertema di dalam kontainer berlatar kontras lembut (`cs.secondaryContainer`, `AppColors.error.withValues(alpha: 0.12)`, atau `AppColors.success.withValues(alpha: 0.12)`) dengan sudut membulat (`AppTheme.cardRadius`).
  2. **Judul Tebal**: Teks judul `tt.titleMedium` tebal (`FontWeight.bold`, `cs.onSurface`).
  3. **Tombol Pill**: Tombol aksi berbentuk pill (`AppTheme.pillRadius`) dengan `FilledButton` untuk aksi konfirmasi utama dan `TextButton` untuk batal/tutup.
  4. Seluruh pemanggilan dialog **WAJIB** melalui `DialogHelper`.

## 10. Alur Tutup Panen & Desain Laporan (*Conclusion-First*)

- **Interaksi Tutup Periode Panen**:
  - Saat menutup periode panen, aplikasi menanyakan data panen riil secara interaktif: **Ayam Dipanen (ekor)** dan **Total Bobot Panen (kg)** beserta *live preview* kalkulasi rata-rata bobot panen ($kg/ekor$).
  - Data panen bersifat opsional (jika kosong, kalkulasi laporan memakai estimasi recording harian).
  - Sistem mengkalkulasi derived metrics: **FCR Panen Aktual** dan **Indeks Performa (IP / EPEF)**.
- **Layar Laporan Periode (*Conclusion-First*)**:
  - Tampilan laporan berfokus pada kesimpulan hasil dan bahasa non-teknis yang mudah dimengerti peternak senior.
  - **Hero Card Indeks Performa (IP)**: Angka IP besar dengan badge status (*Istimewa* $\ge 400$, *Sangat Baik* 350–399, *Baik* 300–349, *Perlu Perbaikan* <300) dan kesimpulan kalimat dalam bahasa Indonesia sehari-hari.
  - **4 Kartu Indikator Utama**: FCR, Daya Hidup, Ayam Dipanen, dan Rata-rata Bobot Panen. Label teks wajib menggunakan `Expanded` dan `TextOverflow.ellipsis` agar tidak terjadi *pixel overflow* pada layar sempit.
  - **Kesimpulan & Saran Periode Berikutnya**: Rekomendasi konkret tindakan (pakan, brooding, biosekuriti) untuk siklus selanjutnya.
  - **Ringkasan Data Produksi**: Kartu ringkas total konsumsi pakan (kg & sak), total bobot daging panen, ADG harian, konsumsi pakan per ekor, dan lama durasi siklus.
  - **Export Cepat**: Tombol Export Excel & CSV disematkan langsung di header laporan utama tanpa butuh screen detail terpisah.

## 11. Konsolidasi Layar & Depresiasi Fitur

- **ADG Harian**: Riwayat kenaikan bobot harian (Daily ADG) terintegrasi langsung di dalam screen Pertumbuhan Bobot Ayam (`ChickenWeightScreen`) di bawah kurva bobot; DILARANG membuat screen terpisah untuk ADG.
- **Depresiasi Reminder Manual**: Fitur alarm / reminder manual dihapus dari UI dan penyimpanan lokal; infrastruktur `NotificationService` hanya dipakai untuk notifikasi otomatis masa depan.
- **Penghapusan Detail Report Screen**: Screen `DetailPeriodReport` dihapus karena seluruh kesimpulan dan export data sudah langsung tersedia pada `PeriodReportPage`.
