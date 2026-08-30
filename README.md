<div align="center">

<img src="assets/logos/logo.png" alt="BroilerKu logo" width="104"/>

# BroilerKu

**Aplikasi Mobile Manajemen Peternakan Ayam Broiler Modern** untuk peternak mandiri — pencatatan harian populasi DOC, mortalitas, konsumsi pakan, penimbangan bobot, kalkulasi FCR & HPP otomatis, analisis Indeks Performa (IP / PEF), hingga laporan akhir panen.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.7.2-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Target SDK](https://img.shields.io/badge/Android%20Target-API%2036-3DDC84?logo=android)](https://developer.android.com)
[![State](https://img.shields.io/badge/State-Provider-5C6BC0)](https://pub.dev/packages/provider)
[![Tests](https://img.shields.io/badge/Tests-425%20Passing-success)](https://github.com)

</div>

---

## Ringkasan Proyek

**BroilerKu** (Package: `com.chickin.mobile`, Internal: `recording_app`) dirancang untuk membantu peternak ayam broiler beralih dari pencatatan manual di buku/kertas ke sistem digital yang terstruktur, akurat, dan mudah digunakan oleh peternak dari berbagai kalangan usia.

### Alur Kerja Utama (Core Workflows):
1. **Autentikasi & Profil**: Registrasi & login aman via Firebase Auth, manajemen profil peternak, dan spesifikasi kandang (*Closed/Open House*).
2. **Manajemen Periode Siklus**: Pembuatan periode DOC masuk otomatis aktif, perlindungan siklus aktif tunggal (*single active period constraint*), dan sistem draft periode.
3. **Pencatatan Harian (Daily Recording)**: Input konsumsi pakan (Sak / Kg), mortalitas harian, dan rata-rata bobot (Gram / Kg) dengan live preview dan validasi anti-typo.
4. **Monitoring & Grafik**: Pantauan populasi riil, kurva pertumbuhan bobot harian (Daily ADG), dan tren FCR mingguan secara visual.
5. **Kalkulator Cepat Broiler**: Alat kalkulasi instan FCR dan Harga Pokok Produksi (HPP) per kg karkas ayam dengan fleksibilitas konversi satuan.
6. **Tutup Periode & Laporan Panen**: Dialog penutupan panen interaktif (Ayam Dipanen & Total Bobot Daging), analisis otomatis **Indeks Performa (IP / PEF)**, kesimpulan saran manajemen, dan ekspor instan ke **Excel (.xlsx)** & **CSV**.
7. **Ensiklopedia Peternak**: Kamus istilah teknis broiler (FCR, IP, ADG, BW, FI, Depletion, Biosekuriti, Brooding, dll.) dengan pencarian interaktif.

---

## Fitur Utama

| Fitur | Deskripsi |
|---|---|
| **Autentikasi Aman** | Pendaftaran peternak, login, logout, dan reset kata sandi terintegrasi Firebase Authentication. |
| **Profil Peternak & Kandang** | Kelola data identitas, kontak WhatsApp, alamat, kapasitas tampung DOC, tipe konstruksi kandang, dan upload foto via galeri/kamera. |
| **Pemilih Foto Modern** | Modal bottom sheet Material 3 interaktif (`ImageSourcePickerBottomSheet`) lengkap dengan crop gambar presisi. |
| **Siklus & Draft Periode** | Manajemen siklus pemeliharaan ayam, proteksi aktivasi draft saat periode aktif berjalan, dan kalkulasi dinamis sisa ayam. |
| **Pencatatan Recording** | Form input harian yang fleksibel (Sak vs Kg, Gram vs Kg) dengan validasi batas wajar (*Domain Sanitization Guard*). |
| **Dashboard Statistik** | Ringkasan cepat populasi hidup, umur ayam, metrik FCR terbaru, dan tabel 7 data pencatatan harian terakhir. |
| **Kalkulator HPP & FCR** | Perhitungan instan FCR dan estimasi Biaya Pokok Produksi (HPP) daging ayam per kilogram untuk proyeksi keuntungan. |
| **Laporan & Indeks Performa (IP)** | Kalkulasi dinamis skor Indeks Performa (IP / PEF) standar industri broiler, 4 kartu indikator utama, saran pakan & brooding. |
| **Ekspor Data Excel & CSV** | Ekspor laporan lengkap periode ke format Excel `.xlsx` dan `.csv` siap dibagikan via WhatsApp atau email. |
| **Ensiklopedia Broiler** | Pusat referensi istilah teknis peternakan broiler dengan kategorisasi dan pencarian cepat. |
| **Tema Aplikasi (M3)** | Dukungan tema Terang (Light), Gelap (Dark), dan mengikuti sistem operasi dengan palet warna **Vivid Blue Material 3**. |

---

## Tech Stack & Arsitektur

- **Framework**: Flutter (Target Android API 36, iOS, Flutter Web, macOS)
- **Bahasa**: Dart SDK `^3.7.2`
- **State Management**: `Provider` (`ChangeNotifier`, `MultiProvider`, `Consumer`)
- **Backend & Database**: Firebase Core, Cloud Firestore, Firebase Authentication, Firebase App Check, Firebase Storage
- **Penyimpanan Lokal & Cache**: Hive, `hive_flutter`
- **Visualisasi & Grafik**: `fl_chart`, `easy_date_timeline`, `flutter_svg`
- **Media & Pengolahan Citra**: `image_picker`, `image_cropper`
- **Ekspor Dokumen**: `excel`, `csv`, `path_provider`, `share_plus`
- **Notifikasi**: `flutter_local_notifications`, `timezone`
- **Pengujian (Testing)**: `flutter_test`, `mocktail` (AAA Pattern, 425+ Automated Tests)

---

## Struktur Folder (Feature-First)

```text
lib/
├── app_checker.dart                  # Root routing dispatcher (Auth state check)
├── firebase_options.dart             # Konfigurasi Firebase per-platform
├── main.dart                         # Inisialisasi Firebase, Hive, & Notifikasi
├── main_app.dart                     # MultiProvider & Root MaterialApp
├── core/
│   ├── auth/                         # AuthService & AuthWrapper guard
│   ├── components/                   # UI Primitives: DialogHelper, AppCard, AppHeader, AppFormBottomSheet
│   │   ├── cards/
│   │   ├── dialogs/                  # ImageSourcePickerBottomSheet, ConfirmDialog, BaseDialog
│   │   ├── empty/                    # AppEmptyState reusable component
│   │   ├── forms/                    # AppTextFormField, FormContainer
│   │   ├── header/                   # AppHeader
│   │   └── loading/                  # ShimmerLoading skeletons (Dashboard, Report, Period, Table)
│   ├── models/                       # safe_convert.dart (wajib untuk parsing data Firestore/JSON)
│   ├── services/                     # FirebaseService (Single Source of Truth), StorageService, NotificationService
│   ├── theme/                        # AppColors (Vivid Blue), AppTheme, AppTypography, ThemeController
│   ├── tour/                         # Onboarding tour controller & guided widgets
│   └── utils/                        # ImagePickerHelper, date formatters
└── features/
    ├── auth/                         # Login, Signup, Forgot Password
    ├── cage/                         # Master data kandang, profil kandang, & form kandang
    ├── dashboard/                    # Beranda, greeting, kartu populasi, status FCR, & tabel riwayat
    ├── export/                       # Exporter CSV & Excel (.xlsx)
    ├── onboarding/                   # Welcome onboarding flow
    ├── period/                       # Manajemen siklus ayam (PeriodData, FormPeriod, ClosePeriodHarvestDialog)
    ├── recording/                    # Pencatatan harian (ChickenData, FormRecording, kurva bobot, riwayat)
    ├── reminder/                     # Pengingat jadwal pakan harian
    ├── reporting/                    # Laporan akhir panen, Indeks Performa (IP), FCR trend, & insight generator
    └── user/                         # Profil peternak, FormUser, QuickCalculator, & Ensiklopedia Broiler
```

---

## Skema Data Firestore

Struktur basis data Cloud Firestore terisolasi per pengguna (`users/{uid}`):

```text
users/{uid}
├── profile: { name, phone, address, hasCompletedTour, avatarUrl? }
├── cage: { type, capacity, location, imageUrl? }
├── createdAt: timestamp
│
├── periods/{periodId}
│   ├── name: string
│   ├── initialCapacity: int
│   ├── initialWeight: double (default 0.04 kg)
│   ├── startDate: timestamp
│   ├── endDate: timestamp?
│   ├── isActive: bool
│   ├── isDeleted: bool
│   ├── createdAt: timestamp
│   └── summary?: {
│         totalFeedKg, finalPopulation, totalMortality, finalBiomass,
│         finalFCR, avgDailyGain, harvestedChicks, harvestedWeightKg,
│         avgHarvestWeightKg, ipScore, insights: []
│       }
│   │
│   └── recordings/{recordingId}
│       ├── day: int
│       ├── avgWeightGram: int
│       ├── feedSack: int
│       ├── mortality: int
│       └── createdAt: timestamp
│
└── reminders/{reminderId}
    ├── title, date, time, description, createdAt, updatedAt
```

---

## Cara Instalasi & Menjalankan

### Persyaratan:
- Flutter SDK (Dart SDK `^3.7.2`)
- Android Studio / Xcode
- Proyek Firebase dengan Authentication & Firestore aktif

### Langkah Setup:

1. **Clone repositori**:
   ```bash
   git clone <repo-url>
   cd chickin-flutter-app
   flutter pub get
   ```

2. **Setup File Environment**:
   Salin template `.env.example` ke `assets/env`:
   ```bash
   cp .env.example assets/env
   ```
   Isi konfigurasi Firebase API Keys dan App Check di dalam `assets/env`.

3. **Menjalankan Aplikasi**:
   ```bash
   # Melalui Flutter CLI
   flutter run

   # Atau menggunakan Makefile
   make run        # Default device
   make run-a      # Android device
   make run-web    # Flutter Web
   ```

---

## Perintah Testing & Build (Makefile)

Aplikasi dilengkapi dengan `Makefile` untuk mempermudah eksekusi pengujian dan pembuatan paket rilis:

```bash
# ── Analisis Kode & Pengujian ──────────────────────
make analyze         # Menjalankan flutter analyze
make test            # Menjalankan seluruh test suite (425+ tests)
make test-coverage   # Menjalankan test coverage report

# ── Pembuatan Rilis Produksi ───────────────────────
make build-apk       # Build Android APK Release
make build-aab       # Build Android App Bundle (.aab untuk Google Play)
make build-ios       # Build iOS Archive Release
make build-web       # Build Flutter Web Production Bundle

# ── Deploy ─────────────────────────────────────────
make deploy-web      # Build dan deploy otomatis ke Firebase Hosting
```

---

## Informasi Rilis

- **Nama Aplikasi**: `BroilerKu`
- **Application ID (Android)**: `com.chickin.mobile`
- **Bundle Identifier (iOS)**: `com.chickin.mobile`
- **Target Android SDK**: `API 36` (Android 16) | `minSdk = 23` (Android 6.0)
- **Versi Saat Ini**: `2.0.0+9`
