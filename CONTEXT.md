# CONTEXT.md — Chickin Flutter App
## Dokumen Konteks untuk AI Agent

> **Berikan dokumen ini di awal setiap sesi AI agent.**
> Dokumen ini adalah satu-satunya sumber kebenaran untuk implementasi Chickin Flutter App.
> Jangan membuat asumsi di luar dokumen ini.

---

## 1. IDENTITAS PROYEK

```
Nama app      : Chickin — Aplikasi Manajemen Peternakan Ayam
Package name  : recording_app
Platform      : Flutter — Android + iOS
Tujuan        : Tools pencatatan & monitoring peternakan ayam broiler untuk peternak mandiri
Backend       : Firebase (Firestore + Firebase Auth + Firebase Storage)
Auth          : Firebase Auth (Email/Password)
Notifikasi    : Firebase Cloud Messaging (FCM) + flutter_local_notifications
State mgmt    : Provider (ChangeNotifier + ProxyProvider)
Routing       : Navigator 2.0 (MaterialApp.home + push/pop manual)
HTTP client   : http ^1.2.1 (digunakan minimal, mayoritas data dari Firestore)
Storage lokal : Hive (hive + hive_flutter)
Charts        : fl_chart ^1.0.0
Export        : csv + excel
```

---

## 2. PUBSPEC.YAML

```yaml
name: recording_app
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.7.2

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  hive_generator: ^2.0.0
  flutter_svg: ^2.1.0
  build_runner: ^2.3.3
  firebase_core: ^3.15.0
  firebase_auth: ^5.6.1
  cloud_firestore: ^5.6.10
  fl_chart: ^1.0.0
  intl: ^0.20.2
  easy_date_timeline: ^2.0.9
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  flutter_timezone: ^3.0.1
  provider: ^6.1.5+1
  flutter_dotenv: ^5.2.1
  csv: ^6.0.0
  excel: ^4.0.6
  path_provider: ^2.1.4
  share_plus: ^10.1.4
  http: ^1.2.1
  image_picker: ^1.1.2
  image_cropper: ^8.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.4

flutter:
  uses-material-design: true
  assets:
    - .env
    - images/hen.png
    - assets/logos/logo.png
    - assets/onboarding/
```

---

## 3. STRUKTUR FOLDER LENGKAP

```
lib/
├── main.dart
├── main_app.dart                     ← MultiProvider root + MaterialApp
├── app_checker.dart                  ← entry routing: auth check → onboarding/home
├── firebase_options.dart
│
├── core/
│   ├── auth/
│   │   ├── auth_service.dart         ← ChangeNotifier — login/logout/register + state user
│   │   └── auth_wrapper.dart         ← guard: redirect berdasar auth state
│   ├── components/
│   │   ├── buttons/                  ← reusable button widgets
│   │   ├── dialogs/
│   │   │   ├── base_dialog.dart
│   │   │   ├── confirm_dialog.dart
│   │   │   ├── dialog_helper.dart    ← ENTRY POINT — semua dialog dipanggil lewat ini
│   │   │   ├── error_dialog.dart
│   │   │   ├── period_picker_dialog.dart
│   │   │   └── string_picker_dialog.dart
│   │   ├── forms/                    ← reusable form widgets
│   │   ├── header/                   ← reusable header widgets
│   │   └── snackbars/                ← reusable snackbar widgets
│   ├── models/
│   │   └── safe_convert.dart         ← helper: asString, asInt, asDouble, asBool
│   ├── services/
│   │   ├── firebase_service.dart     ← SINGLE source of truth semua Firestore operations
│   │   ├── notification_service.dart ← FCM + local notification setup
│   │   ├── reminder_local_service.dart ← schedule local notification reminder
│   │   └── storage_service.dart      ← Firebase Storage (upload gambar)
│   ├── theme/
│   │   ├── app_colors.dart           ← semua color token
│   │   ├── app_text_theme.dart       ← TextTheme definitions
│   │   └── app_theme.dart            ← ThemeData light + dark
│   ├── tour/
│   │   ├── tour_controller.dart      ← ChangeNotifier — state guided tour
│   │   ├── tour_step.dart            ← model step tour
│   │   └── widgets/
│   │       ├── tour_aware_wrapper.dart
│   │       ├── tour_entry_dialog.dart
│   │       ├── tour_overlay.dart
│   │       └── tour_tooltip.dart
│   ├── transitions/
│   │   └── slide_fade_transition_builder.dart  ← custom page transition
│   └── utils/
│       └── image_picker_helper.dart
│
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── login.dart
│   │       └── signup.dart
│   │
│   ├── cage/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── cage_data.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── cage_controller.dart
│   │       ├── pages/
│   │       │   ├── cage_profile.dart
│   │       │   └── form_cage.dart
│   │       └── widgets/
│   │           └── cage_info_card.dart
│   │
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── home_controller.dart
│   │       ├── dashboard.dart
│   │       └── widgets/
│   │           ├── datatable.dart
│   │           ├── fcr_datacard.dart
│   │           ├── population_widget.dart
│   │           └── statistics_section.dart
│   │
│   ├── export/
│   │   ├── data/
│   │   │   └── exporters/
│   │   │       ├── csv_exporter.dart
│   │   │       └── excel_exporter.dart
│   │   └── domain/
│   │       └── usecases/
│   │           ├── export_period_csv.dart
│   │           └── export_period_excel.dart
│   │
│   ├── onboarding/
│   │   ├── data/
│   │   │   └── onboarding_data.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── onboarding_page.dart
│   │       └── widgets/
│   │           ├── onboarding_indicator.dart
│   │           └── onboarding_item.dart
│   │
│   ├── period/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── period_data.dart      ← PeriodData + PeriodSummary + WeeklyFCR
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── period_controller.dart
│   │       ├── list_period.dart
│   │       ├── screens/
│   │       │   └── form_period.dart
│   │       └── widgets/
│   │           ├── active_period_card.dart
│   │           ├── create_period_button.dart
│   │           ├── period_card.dart
│   │           ├── period_list_section.dart
│   │           └── top_bar.dart
│   │
│   ├── recording/
│   │   ├── data/
│   │   │   └── models/
│   │   │       ├── fcr_data.dart
│   │   │       └── recording_data.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── calculate_fcr.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── recording_controller.dart
│   │       └── pages/
│   │           ├── detail_recording.dart
│   │           └── form_recording.dart
│   │
│   ├── reminder/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── reminder_data.dart
│   │   └── presentation/
│   │       ├── form_reminder.dart
│   │       ├── reminder.dart
│   │       └── widgets/
│   │           └── reminder_badge_icon.dart
│   │
│   ├── reporting/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── analytics_calculator.dart
│   │   │       ├── build_realtime_report_usecase.dart
│   │   │       ├── build_report_snapshot_usecase.dart
│   │   │       ├── generate_period_report.dart
│   │   │       ├── insight_generator.dart
│   │   │       └── summary_calculator.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── reporting_controller.dart
│   │       ├── pages/
│   │       │   ├── detail_period_report.dart
│   │       │   ├── period_report.dart
│   │       │   └── period_report_page.dart
│   │       └── widgets/
│   │           ├── analytics_card.dart
│   │           ├── expandable_detail_card.dart
│   │           ├── fcr_trend_chart.dart
│   │           ├── insight_card.dart
│   │           ├── key_metrics_grid.dart
│   │           ├── performance_card.dart
│   │           ├── population_card.dart
│   │           ├── recording_table.dart
│   │           ├── report_summary_header.dart
│   │           └── section_card.dart
│   │
│   └── user/
│       ├── data/
│       │   └── models/
│       │       └── user_data.dart         ← UserProfile model
│       └── presentation/
│           ├── controllers/
│           │   └── user_controller.dart
│           └── pages/
│               ├── form_user.dart
│               ├── profile_screen.dart
│               └── user_profile.dart
```

---

## 4. COLOR TOKENS — app_colors.dart

```dart
class AppColors {
  AppColors._();

  // Brand
  static const Color primary        = Color(0xFF09637E);
  static const Color secondary      = Color(0xFF7AB2B2);
  static const Color background     = Color(0xFFEBF4F6);
  static const Color backgroundDark = Color(0xFF0F2027);

  // Semantic — digunakan di atas background terang (surface, white, #EBF4F6)
  static const Color error   = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);
  static const Color info    = Color(0xFF0277BD);
  static const Color success = Color(0xFF2E7D32);

  // Semantic ON PRIMARY — digunakan di atas hero card (#09637E)
  static const Color errorOnPrimary   = Color(0xFFFF8A80);
  static const Color warningOnPrimary = Color(0xFFFFD180);
  static const Color infoOnPrimary    = Color(0xFF80D8FF);
  static const Color successOnPrimary = Color(0xFFCCFF90);
}
```

**Catatan penting:**
- Tidak ada hardcode hex string di widget manapun — selalu pakai token `AppColors.*`.
- Untuk warna surface, card, onBackground, gunakan `Theme.of(context).colorScheme.*` — ini sudah dikonfigurasi di `AppTheme`.
- Dark mode menggunakan `ColorScheme.fromSeed` dengan `brightness: Brightness.dark`.

---

## 5. FIRESTORE DATA STRUCTURE

Semua data per-user berada di bawah path `users/{uid}`.

```
users/{uid}
  profile: {
    name: String
    phone: String
    address: String
    hasCompletedTour: bool
    avatarUrl: String?
  }
  cage: {
    type: String
    capacity: int
    location: String
    imageUrl: String?
  }
  createdAt: Timestamp

users/{uid}/periods/{periodId}
  name: String
  initialCapacity: int
  initialWeight: double          ← default 0.4 kg
  startDate: Timestamp
  endDate: Timestamp?
  isActive: bool
  isDeleted: bool
  createdAt: Timestamp
  summary: {                     ← hanya ada jika periode sudah ditutup
    totalFeedKg: double
    finalPopulation: int
    totalMortality: int
    finalBiomass: double
    finalFCR: double
    avgDailyGain: double
    weeklyFCR: [ { week: int, fcr: double } ]
    insights: [ String ]
  }

users/{uid}/periods/{periodId}/recordings/{recordingId}
  day: int
  avgWeightGram: int
  feedSack: int
  mortality: int
  createdAt: Timestamp

users/{uid}/reminders/{reminderId}
  title: String
  date: String
  time: String
  description: String
  createdAt: String
  updatedAt: String
```

---

## 6. MODEL DATA

### UserProfile — `features/user/data/models/user_data.dart`
```
name, phone, address, hasCompletedTour, avatarUrl?
```

### CageData — `features/cage/data/models/cage_data.dart`
```
type, capacity, location, imageUrl?
```

### PeriodData — `features/period/data/models/period_data.dart`
```
id, name, initialCapacity, initialWeight, startDate, endDate?,
isActive, isDeleted, createdAt, summary?
```

### PeriodSummary — nested di PeriodData
```
totalFeedKg, finalPopulation, totalMortality, finalBiomass,
finalFCR, avgDailyGain, weeklyFCR[], insights[]
```

### RecordingData — `features/recording/data/models/recording_data.dart`
```
id, day, avgWeightGram, feedSack, mortality, createdAt
```

### ReminderData — `features/reminder/data/models/reminder_data.dart`
```
id, title, date, time, description, createdAt, updatedAt
```

---

## 7. FIREBASE SERVICE — `core/services/firebase_service.dart`

Satu-satunya kelas yang boleh mengakses Firestore secara langsung.
Semua controller harus melalui `FirebaseService` — tidak boleh ada `FirebaseFirestore.instance` di luar kelas ini.

### Method tersedia:

**User Profile**
```dart
getUserProfile([String? uid]) → Future<UserProfile>
updateUserProfile(UserProfile, [String? uid]) → Future<void>
createUserDocument(String uid, UserProfile, CageData) → Future<void>
updateTourStatus(bool, [String? uid]) → Future<void>
updateProfileAvatarUrl(String, [String? uid]) → Future<void>
```

**Cage**
```dart
getCage([String? uid]) → Future<CageData>
updateCage(CageData, [String? uid]) → Future<void>
updateCageImageUrl(String, [String? uid]) → Future<void>
```

**Period**
```dart
createPeriod(PeriodData, [String? uid]) → Future<String>  ← returns docId
getActivePeriod([String? uid]) → Future<PeriodData?>
getPeriodsStream([String? uid]) → Stream<List<PeriodData>>
getPeriod(String periodId, [String? uid]) → Future<PeriodData?>
closePeriod(String periodId, PeriodSummary, [String? uid]) → Future<void>
updatePeriod(String periodId, PeriodData, [String? uid]) → Future<void>
deletePeriod(String periodId, [String? uid]) → Future<void>
```

**Recording**
```dart
addRecording(String periodId, RecordingData, [String? uid]) → Future<void>
getRecordingsStream(String periodId, [String? uid]) → Stream<List<RecordingData>>
getRecordingsOnce(String periodId, [String? uid]) → Future<List<RecordingData>>
getWeightStream(String periodId, [String? uid]) → Stream<List<FlSpot>>
deleteRecording(String periodId, String recordingId, [String? uid]) → Future<void>
updateRecording(String periodId, String recordingId, RecordingData, [String? uid]) → Future<void>
```

**Reminder**
```dart
addReminder(ReminderData, [String? uid]) → Future<void>
deleteReminder(String reminderId, [String? uid]) → Future<void>
getReminderStream([String? uid]) → Stream<List<ReminderData>>
```

---

## 8. STATE MANAGEMENT — Provider Pattern

Semua controller adalah `ChangeNotifier`. Didaftarkan di `MainApp` via `MultiProvider`.

### Pola ProxyProvider

Setiap controller mengikuti pola ini — reaktif terhadap perubahan auth:

```dart
ChangeNotifierProxyProvider<AuthService, XxxController>(
  create: (_) => XxxController(firebaseService: FirebaseService()),
  update: (_, auth, controller) {
    controller!.onAuthChanged(auth.currentUid);
    return controller;
  },
),
```

`onAuthChanged(String? uid)` dipanggil otomatis setiap kali auth state berubah.
Controller harus handle kasus `uid == null` (user logout → clear state lokal).

### Controllers yang terdaftar

| Controller | Bergantung ke |
|---|---|
| `AuthService` | — (root, bukan proxy) |
| `UserController` | `AuthService` |
| `CageController` | `AuthService` |
| `HomeController` | `AuthService` |
| `PeriodController` | `AuthService` |
| `RecordingController` | `AuthService` |
| `ReportingController` | `AuthService` |
| `TourController` | `AuthService` |

---

## 9. AUTH FLOW

```
App launch
  → AppChecker
    → AuthWrapper
      → isInitialized = false → LoadingSpinner
      → isLoggedIn = false → LoginPage / OnboardingPage
      → isLoggedIn = true → Dashboard / MainScreen
```

**AuthService** adalah single source of truth untuk state auth.
- Tidak boleh ada `FirebaseAuth.instance` di luar `AuthService` dan `FirebaseService`.
- Logout: `AuthService.signOut()` → `AuthWrapper` otomatis redirect ke login via `context.watch`.
- Setelah logout: semua `ProxyProvider` otomatis fire `onAuthChanged(null)` → controller clear state.

---

## 10. DIALOG SYSTEM — DialogHelper

Entry point semua dialog adalah `DialogHelper` di `core/components/dialogs/dialog_helper.dart`.

```
WAJIB: Semua dialog dipanggil via DialogHelper.
DILARANG: showDialog() atau showModalBottomSheet() dipanggil langsung dari screen.
```

### Method tersedia

| Situasi | Method |
|---|---|
| Tampilkan error | `DialogHelper.showError(context, title, message)` |
| Tampilkan info | `DialogHelper.showInfo(context, title, message)` |
| Konfirmasi aksi | `DialogHelper.showConfirm(context, title, message, ...)` |
| Pilih periode | `DialogHelper.showPeriodPicker(context, periods, ...)` |
| Pilih dari daftar string | `DialogHelper.showStringPicker(context, title, options, ...)` |

### Yang TIDAK perlu dialog

```
Input form biasa      → langsung submit
Filter / sort         → tidak perlu konfirmasi
Pull-to-refresh       → tidak perlu konfirmasi
Navigasi antar screen → tidak perlu konfirmasi
```

---

## 11. FITUR — RINGKASAN

### Auth
- Login email/password via Firebase Auth
- Register akun baru → otomatis buat dokumen user di Firestore
- Firebase Auth state listener reactive via `AuthService`

### Onboarding
- Muncul sekali saat pertama install (sebelum login)
- `hasCompletedTour` disimpan di Firestore di `profile`

### Dashboard
- Ringkasan periode aktif
- Statistik populasi, mortalitas, FCR
- Tabel recording

### Cage (Kandang)
- CRUD data kandang: tipe, kapasitas, lokasi, foto
- Data disimpan sebagai map di `users/{uid}/cage`

### Period (Periode Pemeliharaan)
- Satu user hanya boleh punya satu periode aktif (`isActive: true`)
- Menutup periode → hitung summary otomatis via `SummaryCalculator` / `AnalyticsCalculator`
- Data: initialCapacity, initialWeight, startDate, endDate, summary

### Recording (Pencatatan Harian)
- Input harian: hari ke-N, berat rata-rata (gram), pakan (sak), mortalitas
- Nested di `periods/{periodId}/recordings`
- FCR dihitung otomatis via `CalculateFCR` usecase

### Reporting (Laporan)
- Laporan per periode: summary, analytics, insight, chart FCR trend
- Export ke CSV dan Excel via fitur `export`
- Realtime report vs snapshot report (dua usecase terpisah)

### Reminder
- Reminder lokal dengan notifikasi (flutter_local_notifications)
- Data disimpan di Firestore `users/{uid}/reminders`

### Export
- Export data periode ke CSV dan Excel
- Menggunakan `path_provider` + `share_plus` untuk simpan dan share file

### Tour / Guided Tour
- Guided tour pertama kali masuk app
- State dikelola `TourController`, status disimpan di Firestore

---

## 12. ATURAN BISNIS PENTING

### Period — Satu Aktif Sekaligus
```
Tidak boleh create periode baru jika sudah ada periode aktif (isActive: true).
Untuk buat periode baru, tutup dulu periode yang sedang aktif.
```

### Menutup Periode
```
1. Fetch semua recordings periode tersebut (getRecordingsOnce)
2. Hitung summary via SummaryCalculator / AnalyticsCalculator
3. Panggil closePeriod(periodId, summary) → set isActive: false + endDate
4. Semua controller reload state via onAuthChanged atau notifyListeners
```

### Recording — Tidak Duplikat per Hari
```
Satu hari (day) dalam satu periode hanya boleh ada satu recording.
Validasi dilakukan di form sebelum submit.
```

### Logout Flow
```
1. Konfirmasi via DialogHelper.showConfirm()
2. AuthService.signOut()
3. AuthWrapper otomatis redirect ke login
4. Semua ProxyProvider fire onAuthChanged(null) → clear state
```

---

## 13. ATURAN KODE

```
1.  Semua warna dari AppColors — tidak boleh ada hardcode hex string inline di widget
2.  Warna surface/card/onBackground dari Theme.of(context).colorScheme.*
3.  Semua text style dari Theme.of(context).textTheme.* — tidak boleh ada TextStyle inline
4.  Akses Firestore hanya boleh lewat FirebaseService — tidak ada FirebaseFirestore.instance di luar
5.  Akses Firebase Auth hanya boleh lewat AuthService — tidak ada FirebaseAuth.instance di controller
    (pengecualian: FirebaseService boleh pakai FirebaseAuth untuk _currentUid internal)
6.  Setiap screen wajib punya 3 state: loading, data, error
7.  List screen wajib punya empty state
8.  Semua aksi destructive (hapus, tutup periode) wajib DialogHelper.showConfirm() dulu
9.  Jangan panggil showDialog() atau showModalBottomSheet() langsung dari screen — selalu lewat DialogHelper
10. Controller tidak boleh import package:flutter — hanya ChangeNotifier dari foundation
    (pengecualian: jika butuh BuildContext — hindari, atau gunakan navigator key)
11. safe_convert.dart (asString, asInt, asDouble, asBool) wajib digunakan di semua fromJson
12. Selalu handle kasus json == null di semua factory fromJson — return default object, bukan throw
```

---

## 14. PACKAGE IMPORTS YANG SERING DIGUNAKAN

```dart
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Selalu gunakan token — jangan hardcode
import 'package:recording_app/core/theme/app_colors.dart';

// Dialog — satu import ini cukup
import 'package:recording_app/core/components/dialogs/dialog_helper.dart';

// safe_convert untuk fromJson
import 'package:recording_app/core/models/safe_convert.dart';

// Service utama
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/auth/auth_service.dart';
```

---

## 15. YANG BELUM DIIMPLEMENTASI (TODO)

```
[ ] Shimmer loading state di semua list screen
[ ] Empty state yang konsisten di semua list screen
[ ] Error state yang konsisten di semua screen
[ ] Pull-to-refresh di list screen yang relevan
[ ] Foto kandang via Firebase Storage (upload sudah ada di StorageService)
[ ] Foto profil via Firebase Storage
[ ] Push notification FCM (NotificationService sudah ada, belum diintegrasikan penuh)
[ ] Export ke PDF (saat ini hanya CSV dan Excel)
[ ] Paginasi recording list jika data banyak
[ ] Onboarding tour per-fitur yang lebih lengkap
[ ] Validasi form yang lebih ketat (duplikat hari pada recording)
[ ] Unit test untuk domain/usecases (calculate_fcr, summary_calculator, dll.)
```

---

## 16. INSTRUKSI UNTUK AI AGENT

Saat menerima task implementasi, ikuti aturan ini:

1. **Baca CONTEXT.md ini dulu sepenuhnya** sebelum menulis baris kode apapun.

2. **Selalu gunakan token** — `AppColors.primary`, bukan `Color(0xFF09637E)`. `Theme.of(context).textTheme.bodyMedium`, bukan `TextStyle(fontSize: 14)`.

3. **Ikuti struktur folder** di Section 3. Jangan buat file di luar struktur ini tanpa alasan.

4. **Setiap screen** harus punya minimal: loading state, data state, error state. List screen tambahkan empty state.

5. **Akses data** hanya lewat FirebaseService — jangan buat query Firestore langsung di controller atau widget.

6. **Saat membuat model**, gunakan field yang persis sesuai Firestore structure di Section 5. Wajib pakai `safe_convert.dart` di `fromJson`. Handle `json == null`.

7. **Saat ada aksi destructive** (hapus, tutup periode, logout), selalu konfirmasi dulu via `DialogHelper.showConfirm()`.

8. **Jangan buat feature baru** yang tidak ada di Section 11 atau 15 tanpa konfirmasi.

9. **Controller** selalu mengikuti pola `ProxyProvider` + `onAuthChanged(String? uid)` di Section 8.

10. **Tanya dulu jika tidak yakin** tentang struktur Firestore atau business logic sebelum implementasi.
