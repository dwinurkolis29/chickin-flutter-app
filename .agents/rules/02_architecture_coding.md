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
  - Ketika masih ada periode yang aktif, tombol **'Aktifkan Periode Ini Sekarang'** pada form/detail draft periode **WAJIB disembunyikan** dari UI dan digantikan dengan banner status edukatif berikon gembok (`Icons.lock_outline_rounded`).
- **Editable Active & Draft Periods**:
  - Periode Aktif dan Draft **dapat diedit** datanya (Nama Periode, Kapasitas DOC, Tanggal DOC Masuk).
  - Sisa ayam, umur hari, dan FCR terkalkulasi ulang secara dinamis tanpa merusak integritas catatan harian (recording).
  - Periode yang sudah **Selesai Panen** (`endDate != null`) terkunci permanen (*read-only*).
- **Senior Farmer Form Simplicity**:
  - Hindari form yang membebani peternak berusia lanjut dengan format desimal rumit (misal: "Bobot Awal DOC").
  - Otomatis gunakan standar industri (misal: `0.04 kg` / 40 gram) di balik layar.
  - Form pembuatan periode cukup berfokus pada 3 input esensial: **Nama Periode**, **Tanggal DOC Masuk**, dan **Jumlah DOC (Ekor)**.

## 9. Dialog & Form Bottom Sheet Standards

- **Dialog Informasi vs Form Bottom Sheet**:
  - **BaseDialog / ConfirmDialog**: Digunakan **hanya** untuk konfirmasi singkat, alert peringatan, atau pesan informasi (tanpa input teks panjang).
  - **AppFormBottomSheet (`lib/core/components/dialogs/app_form_bottom_sheet.dart`)**: **WAJIB** digunakan untuk semua form interaktif pop-up (seperti Tutup Panen, Edit Recording, Ubah Kata Sandi, dan Konfirmasi Kata Sandi Hapus Akun).
  - **DILARANG** menggunakan dialog melayang di tengah layar (`showDialog` / `BaseDialog`) untuk form input karena rentan terpotong oleh keyboard virtual dan sulit dijangkau jempol satu tangan.
- **Image Source Picker Modal**: Pemilihan gambar dari Galeri atau Kamera wajib memanggil `DialogHelper.showImageSourcePicker()` (`lib/core/components/dialogs/image_source_picker_bottom_sheet.dart`).
- **Standar Visual Dialog & Sheet**:
  1. **Header Icon Badge**: Baris judul dengan icon bertema di dalam kontainer bulat (`cs.secondaryContainer`, `AppColors.error.withValues(alpha: 0.12)`, atau `AppColors.success.withValues(alpha: 0.12)`).
  2. **Judul Tebal**: Teks judul `tt.titleMedium` tebal (`FontWeight.bold`, `cs.onSurface`).
  3. **Tombol Pill**: Tombol aksi berbentuk pill (`AppTheme.pillRadius`) dengan `FilledButton` untuk aksi konfirmasi utama dan `TextButton` untuk batal/tutup.
  4. Seluruh pemanggilan dialog **WAJIB** melalui `DialogHelper` atau `AppFormBottomSheet.show()`.
- **Transparansi Status Fitur (Tahap Pengembangan)**:
  - Jika suatu fitur backend/integrasi email masih dalam tahap pengembangan (misal: verifikasi email atau kirim link reset password via email), aplikasi **WAJIB** secara transparan menampilkan label `(Tahap Pengembangan)` dan memberikan dialog edukasi yang ramah (`DialogHelper.showInfo`), sambil tetap menyediakan alternatif langsung yang sudah berfungsi (seperti Ubah Kata Sandi Langsung).

## 10. Alur Tutup Panen & Desain Laporan (*Conclusion-First*)

- **Interaksi Tutup Periode Panen**:
  - Saat menutup periode panen, aplikasi menanyakan data panen riil secara interaktif: **Ayam Dipanen (ekor)** dan **Total Bobot Panen (kg)** beserta *live preview* kalkulasi rata-rata bobot panen ($kg/ekor$).
  - Data panen bersifat opsional (jika kosong, kalkulasi laporan memakai estimasi recording harian).
  - Sistem mengkalkulasi derived metrics: **FCR Panen Aktual** dan **Indeks Performa (IP / EPEF)**.
- **Layar Laporan Periode (*Conclusion-First*)**:
  - Tampilan laporan berfokus pada kesimpulan hasil dan bahasa non-teknis yang mudah dimengerti peternak senior.
  - **Hero Card Indeks Performa (IP)**: Angka IP besar dengan badge status (*Istimewa* $\ge 400$, *Sangat Baik* 350–399, *Baik* 300–349, *Perlu Perbaikan* <300) dan kesimpulan kalimat dalam bahasa Indonesia sehari-hari.
  - **Kalkulasi IP Riil**: Perhitungan Indeks Performa (IP / PEF) wajib dihitung secara dinamis dari umur panen riil (`sorted.last.day`) dan metrik panen/recording aktual, DILARANG menggunakan angka fallback tiruan (hardcoded).
  - **4 Kartu Indikator Utama**: FCR, Daya Hidup, Ayam Dipanen, dan Rata-rata Bobot Panen. Label teks wajib menggunakan `Expanded` dan `TextOverflow.ellipsis` agar tidak terjadi *pixel overflow* pada layar sempit.
  - **Kesimpulan & Saran Periode Berikutnya**: Rekomendasi konkret tindakan (pakan, brooding, biosekuriti) untuk siklus selanjutnya.
  - **Ringkasan Data Produksi**: Kartu ringkas total konsumsi pakan (kg & sak), total bobot daging panen, ADG harian, konsumsi pakan per ekor, dan lama durasi siklus.
  - **Export Cepat**: Tombol Export Excel & CSV disematkan langsung di header laporan utama tanpa butuh screen detail terpisah.

## 11. Konsolidasi Layar & Depresiasi Fitur

- **ADG Harian**: Riwayat kenaikan bobot harian (Daily ADG) terintegrasi langsung di dalam screen Pertumbuhan Bobot Ayam (`ChickenWeightScreen`) di bawah kurva bobot; DILARANG membuat screen terpisah untuk ADG.
- **Depresiasi Reminder Manual**: Fitur alarm / reminder manual dihapus dari UI dan penyimpanan lokal; infrastruktur `NotificationService` hanya dipakai untuk notifikasi otomatis masa depan.
- **Penghapusan Detail Report Screen**: Screen `DetailPeriodReport` dihapus karena seluruh kesimpulan dan export data sudah langsung tersedia pada `PeriodReportPage`.

## 12. Form Architecture & Senior Farmer UX Standards

- **Single Explicit Label (Anti Teks Tumpang Tindih)**:
  - Cukup gunakan satu `labelText` yang jelas dan deskriptif di dalam `AppTextFormField` (misal: `labelText: 'Model / Tipe Konstruksi Kandang'`).
  - **DILARANG** menambahkan `Text(...)` manual tepat di atas `AppTextFormField` yang membuat teks bertumpuk atau redundan dengan floating outline label Material 3.
- **Struktur & Hierarki Form Terpadu**:
  - Seluruh form pengisian/pengeditan di aplikasi (`FormRecording`, `FormCage`, `FormUser`) **WAJIB** mengikuti hierarki 4-tahap yang konsisten:
    1. **Hero Guidance Card**: Banner instruksi ramah lansia di bagian atas (`cs.secondaryContainer (50% alpha)` + border `cs.primary (15% alpha)` + ikon bulat di sisi kiri).
    2. **Uppercase Category Section Headers**: Header sub-bagian berwarna primer dengan spasi huruf rapi (`tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold, letterSpacing: 0.8)`).
    3. **Form Fields**: Field-field input yang sejajar rapi dengan padding luar `EdgeInsets.symmetric(horizontal: 20, vertical: 16)` tanpa pembungkus ekstra yang membuat indent ganda.
    4. **Tombol Aksi Utama (CTA)**: `FilledButton.icon` berbentuk pill full-width (tinggi 50–52dp) di bagian bawah.
- **Konsistensi Margin & Card Zero Margin**:
  - `AppCard` wajib menggunakan `margin: margin ?? EdgeInsets.zero` untuk mencegah margin 4px liar dari default `Card` Flutter.
  - Semua elemen form (Guidance Card, Section Header, Input Field, Preview Card, dan Tombol) harus berbagi batas margin horizontal yang sama persis.

## 13. Profil Peternak vs Profil Fasilitas Kandang

- **Diferensiasi Identitas Visual**:
  - **Profil Saya (`user_profile.dart`)**: Berfokus pada persona peternak, kontak, dan domisili (Avatar bulat besar 92dp + nama peternak + badge aktif + kartu kontak WA/email/alamat + tombol Ubah Profil). Fitur reset password ditiadakan selama masa pengembangan.
  - **Profil Kandang (`cage_profile.dart`)**: Berfokus pada aset fisik dan kapasitas fasilitas (Cover foto landscape 190dp tampak kandang + Hero Card Kapasitas Maksimal 32sp bold + kartu spesifikasi konstruksi Closed/Open House & lokasi + tombol Ubah Spesifikasi).
- **Aksesibilitas Peternak Senior**:
  - Font ukuran terbaca, kontras warna tinggi, teks bahasa Indonesia yang jelas dan tidak teknis, serta tombol pill besar (min 48–52dp) sehingga mudah ditekan tanpa perlu mencari icon kecil.
