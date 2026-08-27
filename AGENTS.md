# Chickin (BroilerKu)

Aplikasi Mobile Manajemen Peternakan Ayam Broiler untuk peternak mandiri — pencatatan harian populasi DOC, mortalitas, konsumsi pakan, penimbangan bobot, kalkulasi FCR, reminder jadwal pakan, hingga laporan akhir periode panen.

## Tech Stack

- **Framework**: Flutter (Target Android API 36, iOS, Flutter Web)
- **State Management**: `provider` (`ChangeNotifier`, `MultiProvider`, `ProxyProvider`)
- **Backend & Auth**: Firebase (`firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_app_check`)
- **Local Storage**: Hive (`hive`, `hive_flutter`, `hive_generator`)
- **Notifications**: `flutter_local_notifications` + Firebase Cloud Messaging (FCM)
- **Charts & Visuals**: `fl_chart`, `flutter_svg`, `easy_date_timeline`
- **Exporting**: `csv`, `excel`, `path_provider`, `share_plus`
- **Testing**: `flutter_test`, `mocktail` (Unit Test AAA pattern & Test Pyramid)
- **Build Tooling**: `Makefile` (run, test-coverage, build-aab, build-apk, deploy-web)

---

## Architecture & Folder Structure

Arsitektur menggunakan pendekatan **Feature-First**:

```
lib/
├── core/
│   ├── auth/            # AuthService (ChangeNotifier), AuthWrapper guard
│   ├── components/      # UI primitives: dialog_helper.dart, base_dialog, buttons, forms
│   ├── models/          # safe_convert.dart (wajib untuk data mapping Firestore/JSON)
│   ├── services/        # firebase_service.dart (Single Source of Truth Firestore), notification_service.dart
│   ├── theme/           # app_colors.dart, app_theme.dart, app_text_theme.dart
│   ├── tour/            # Guided onboarding tour controller & widgets
│   └── utils/           # image_picker_helper.dart
├── features/
│   ├── auth/            # Login, Signup
│   ├── cage/            # Master data kandang
│   ├── dashboard/       # Ringkasan populasi, grafik mingguan, quick actions
│   ├── export/          # Export laporan (CSV / Excel)
│   ├── onboarding/      # Welcome flow
│   ├── period/          # Siklus / periode pemeliharaan ayam
│   ├── recording/       # Catatan harian (pakan, mati, bobot, riwayat)
│   ├── reminder/        # Pengingat pakan & brooding harian
│   ├── reporting/       # FCR calculation, ringkasan performa peternakan
│   └── user/            # Profile & pengaturan akun
├── app_checker.dart     # Root routing dispatcher (Auth state check)
├── main_app.dart        # MultiProvider root
└── main.dart
```

---

## Key Coding Rules

1. **State Management**:
   - Gunakan `ChangeNotifier` dan `Provider`.
   - Simpan logic state di dalam folder feature (`features/<name>/presentation/controllers/`) kecuali logic auth/tour yang bersifat global di `core/`.
   - Hindari manipulasi state widget langsung jika logic bisnis bisa ditangani controller.

2. **Data Parsing & Safe Convert**:
   - Semua mapping data dari Firestore (`Map<String, dynamic>`) **WAJIB** menggunakan helper `safe_convert.dart` (`asString`, `asInt`, `asDouble`, `asBool`).
   - Jangan pernah melakukan *force unwrap* (`data['field']!`) atau casting langsung (`data['field'] as int`) yang rentan `TypeError` / `NullCheckError`.

3. **Firebase & Data Flow**:
   - `FirebaseService` adalah pintu utama operasi Firestore.
   - Jangan menulis query Firestore ad-hoc yang berserakan di dalam file UI/Widget.

4. **Dialogs & UI Consistency**:
   - Semua pemanggilan alert/dialog **WAJIB** melalui `DialogHelper` (`lib/core/components/dialogs/dialog_helper.dart`).
   - Gunakan token warna dari `AppColors` atau `Theme.of(context).colorScheme`.

5. **Testing Rules (Sesuai `TESTING_AGENT.md`)**:
   - Terapkan pola **AAA (Arrange, Act, Assert)** dan bungkus test dalam `group()`.
   - **DILARANG KERAS** memanggil Firebase Firestore asli saat unit test. Gunakan `mocktail` untuk mock service/controller.
   - Mirroring path folder: `lib/features/recording/domain/calculate_fcr.dart` -> `test/features/recording/domain/calculate_fcr_test.dart`.
   - Coverage target: Domain Logic 100%, Models 95%, Controller 80%, Project minimal 70%.

6. **Local Notifications**:
   - Selalu gunakan `AndroidScheduleMode.inexactAllowWhileIdle` untuk penjadwalan reminder agar hemat baterai dan patuh pada Google Play Policy.

---

## Detailed Rules & Skills

- Detailed rules reside in `.agents/rules/`:
  - `01_response_style.md`
  - `02_architecture_coding.md`
  - `03_firebase_guidelines.md`
  - `04_testing_standards.md`
- Workflows and skills reside in `.agents/skills/`:
  - `flutter-design/SKILL.md`
  - `flutter-testing/SKILL.md`
  - `flutter-release/SKILL.md`
  - `flutter-rumus-broiler/SKILL.md`
