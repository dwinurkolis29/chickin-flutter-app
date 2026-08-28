---
name: flutter-design
description: Design system and UI styling reference for Chickin (BroilerKu) Flutter app — Vivid Blue Material 3 theme, shape constants, FCR semantic status colors, typography (Plus Jakarta Sans), DialogHelper, and reusable components. Use this skill automatically whenever writing, editing, or reviewing ANY Flutter UI code, widget, dialog, or screen.
---

# Chickin (BroilerKu) — Design System

Gunakan panduan ini sebagai standar visual utama saat membuat atau memodifikasi widget/layar di aplikasi Chickin.

## Implementation Rule (WAJIB DIIKUTI)

- **DILARANG KERAS** menuliskan `Color(0xFF...)` atau literal hex baru di dalam file widget/screen manapun.
- **DILARANG KERAS** menuliskan angka radius hardcoded (seperti `10`, `12`, `15`, `16`, `20`, `25`, `28`, `30`) secara ad-hoc. Selalu gunakan konstanta `AppTheme.*Radius`.
- **DILARANG KERAS** menggunakan konstanta warna statis Material seperti `Colors.white`, `Colors.black`, `Colors.transparent` secara langsung.
- Selalu gunakan referensi tema: `Theme.of(context).colorScheme.*` atau konstanta dari `lib/core/theme/app_colors.dart`.
- Semua pemanggilan dialog **WAJIB** melalui `DialogHelper` (`lib/core/components/dialogs/dialog_helper.dart`).
- Tetapkan `visualDensity: VisualDensity.standard` agar komponen di Flutter Web tidak gepeng (sudah diset di `AppTheme`).
- **DILARANG KERAS** menggunakan icon 3D atau emoji 3D di seluruh aplikasi. Gunakan hanya ikon flat Material 3 yang bersih.
- **Action Button Styling (Tutup Panen / Destructive Actions)**: Gunakan `OutlinedButton.icon` dengan outline border `cs.error.withValues(alpha: 0.6)`, teks tebal, dan background transparan (bukan solid tonal container tebal) agar tampilan tetap bersih dan tidak mendominasi layar.
- **DILARANG** menggunakan `AppTextTheme` — sudah deprecated. Gunakan `AppTypography` atau `Theme.of(context).textTheme`.
- **DILARANG** menggunakan `AppColors.info` — token ini sudah dihapus. Gunakan `AppColors.primary` atau `colorScheme.primary`.
- **DILARANG** menggunakan `AppColors.secondary`, `AppColors.secondaryContainer`, atau token `*OnPrimary` — semua sudah dihapus.

---

## Theme Entry Point ([lib/core/theme/app_theme.dart](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/lib/core/theme/app_theme.dart))

```dart
// di main_app.dart
theme:     AppTheme.build(AppThemeOption.light),
darkTheme: AppTheme.build(AppThemeOption.dark),
```

---

## Shape Constants ([AppTheme](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/lib/core/theme/app_theme.dart))

Gunakan konstanta ini secara konsisten — **jangan hardcode angka radius**.

| Constant | Value | Kapan Dipakai |
|----------|-------|---------------|
| `AppTheme.pillRadius` | `999.0` | Button, chip, input field, nav indicator, badge pill |
| `AppTheme.cardRadius` | `24.0` | Card, container utama, dialog, top corner bottom sheet, InkWell ripple pada card |
| `AppTheme.rowRadius` | `16.0` | Sheet row, list tile decoration, inner container |
| `AppTheme.snackbarRadius` | `4.0` | Snackbar saja |

> **PENTING (InkWell pada Card)**: Semua `InkWell` di dalam atau di atas `Card`/`AppCard` **WAJIB** menyertakan `borderRadius: BorderRadius.circular(AppTheme.cardRadius)` agar efek ripple presisi mengikuti lekukan 24dp kartu.

> **PENTING (Bottom Sheet)**: Sudut atas modal bottom sheet diseragamkan ke `AppTheme.cardRadius` (`24.0dp`).

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
    color: Theme.of(context).colorScheme.surfaceContainer,
  ),
)
```

---

## Color Palette ([lib/core/theme/app_colors.dart](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/lib/core/theme/app_colors.dart))

### Prinsip Utama
**Satu warna dominan** (Vivid Blue) + surface tokens netral. Warna lain hanya untuk status/domain.

### 1. Brand (1 token)
| Token | Hex | Dipakai |
|-------|-----|---------|
| `AppColors.primary` | `#1A47E5` | CTA, icon aktif, badge, progress, tombol |

### 2. Surface Tokens — Light (8 token)
| Token | Hex | Dipakai |
|-------|-----|---------|
| `AppColors.background` | `#EEF2FF` | Scaffold background |
| `AppColors.surface` | `#FFFFFF` | Card / dialog / sheet utama |
| `AppColors.surfaceContainer` | `#F5F7FF` | Default card bg, input fill |
| `AppColors.surfaceContainerHigh` | `#EBF0FF` | Elevated card, bottom sheet |
| `AppColors.onSurface` | `#0A1128` | Teks utama (dark navy) |
| `AppColors.onSurfaceVariant` | `#5A6680` | Label, hint, sub-teks |
| `AppColors.outline` | `#CDD5EE` | Border aktif, input border |
| `AppColors.outlineVariant` | `#E8ECFB` | Divider, border pasif |

> **Di widget**: gunakan `Theme.of(context).colorScheme.surfaceContainer` — bukan `AppColors.*` langsung — agar dark mode otomatis.

### 3. Surface Tokens — Dark (8 token, mirrored)
Dikelola otomatis oleh `AppTheme.build()`. Tidak perlu akses langsung dari widget.

### 4. Semantic Status (3 token)
Gunakan **hanya** di badge, snackbar, teks status. **Jangan** pakai sebagai background lebar.

| Token | Hex | Dipakai |
|-------|-----|---------|
| `AppColors.success` | `#22C55E` | Period aktif, nilai baik |
| `AppColors.warning` | `#F59E0B` | Nilai perlu perhatian |
| `AppColors.error` / `AppColors.formError` | `#EF4444` | Error, form validation |

### 5. FCR Domain Colors (9 token — domain-specific)
| Group | Token | Keterangan |
|-------|-------|-----------|
| Good | `fcrGoodBg`, `fcrGoodText`, `fcrGoodBorder` | FCR ≤ 1.8 |
| Warn | `fcrWarnBg`, `fcrWarnText`, `fcrWarnBorder` | FCR 1.8–2.2 |
| Bad | `fcrBadBg`, `fcrBadText`, `fcrBadBorder` | FCR ≥ 2.2 |

---

## Typography ([lib/core/theme/app_typography.dart](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/lib/core/theme/app_typography.dart))

Font: **Plus Jakarta Sans** (via `google_fonts`).

Gunakan `Theme.of(context).textTheme` — warna sudah resolved dari ColorScheme.

| Style | Size | Weight | Dipakai |
|-------|------|--------|---------|
| `displayLarge` | 32sp | 800 | Angka besar: populasi, FCR value |
| `titleLarge` | 20sp | 600 | Judul layar / AppBar |
| `titleMedium` | 18sp | 600 | Header section / card |
| `bodyMedium` | 14sp | 400 | Konten umum |
| `bodySmall` | 12sp | 400 | Caption, hint |
| `labelLarge` | 14sp | 700 | Tombol, label penting |
| `labelSmall` | 10sp | 500 | Chip, tag |

---

## Component Standards

### 1. Dialogs (Pola Terpadu "Tentang Aplikasi")
- Selalu gunakan `DialogHelper.*` (`showError`, `showInfo`, `showSuccess`, `showConfirm`, `showAbout`, `showPeriodPicker`, `showStringPicker`, `showClosePeriodHarvest`).
- Struktur visual dialog:
  - Header Row: Icon di dalam kontainer membulat (`cs.secondaryContainer`, `AppColors.error.withValues(alpha: 0.12)`, `AppColors.success.withValues(alpha: 0.12)`) + Teks judul tebal `tt.titleMedium`.
  - Body: `tt.bodyMedium` dengan warna `cs.onSurfaceVariant` dan line height 1.4.
  - Action Buttons: Berbentuk pill (`AppTheme.pillRadius`) dengan `FilledButton` untuk aksi konfirmasi dan `TextButton` untuk batal/tutup.

### 2. Cards & Containers
- Radius: `AppTheme.cardRadius` (24dp).
- Color: `colorScheme.surfaceContainer` — **bukan** `Colors.white`.
- Elevation: 1 (sudah di-set di `CardThemeData`).
- **Card Header & Titles**: Judul riwayat/tabel data (misal: "Riwayat Bobot Harian") diletakkan **di dalam** `AppCard`, bukan teks mengambang di luar kartu. Hindari icon dekoratif tambahan di header kartu kecuali diminta.

### 3. Buttons
- **FilledButton**: CTA primer, pill, full-width, min 48dp.
- **OutlinedButton**: CTA sekunder / ghost, pill, full-width.
- **TextButton**: Link / aksi tertier — foreground `primary`.

### 4. Input Fields
- Pill shape, filled `surfaceContainer`. Wajib ada leading icon.

### 5. Status Badge di atas Hero Card (Primary Background)
- Jangan pakai `AppColors.*OnPrimary` — sudah dihapus.
- Gunakan pastel inline: green `#A3E6BE` (Istimewa / Baik), blue `#90CAF9` (Sangat Baik), amber `#FFD580` (Standar), red `#FF9A9A` (Perlu Perbaikan).
- Lihat contoh di [`report_summary_header.dart`](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/lib/features/reporting/presentation/widgets/report_summary_header.dart).

### 6. AppBar & Header Standards
- Gunakan [`AppHeader`](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/lib/core/components/header/app_header.dart) sebagai satu-satunya standar top bar aplikasi.
- Tombol back (`leading`) dan icon actions di AppBar **TIDAK BOLEH** dibungkus container/shadow buatan.
- Gunakan `IconButton` standar dengan icon `size: 24` (`color: colorScheme.onSurface`).
- Efek hover dan splash circular ditangani secara native oleh `IconButton`.

### 7. Charts & Growth Lists
- **Label Sumbu Y**: Selalu tampilkan satuan gram yang jelas dan terformat (misal `1,000 g`), dengan `reservedSize: 56` agar angka tidak terpotong.
- **Urutan Riwayat Harian**: Tampilkan data riwayat penimbangan harian secara **ascending** (Hari 1 / DOC teratas, bertambah ke bawah hingga hari terakhir), disertai badge pertambahan bobot harian (`+X g`).

### 8. Icon Badges & Circular Wrappers
- Semua pembungkus icon pendukung (pada header card, list tile, riwayat recording, info card) **WAJIB** menggunakan bentuk lingkaran:
  ```dart
  Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: BoxShape.circle,
    ),
    child: Icon(..., color: Theme.of(context).colorScheme.primary, size: 20),
  )
  ```
- Hindari penggunaan rounded rectangle yang tidak konsisten untuk icon wrapper.

### 9. Dynamic Chart & Trend Metric Coloring
- Pada grafik perkembangan (misal: Bobot Ayam harian / metrik tren):
  - **Garis & Gradien Dinamis**:
    - **Hijau (`AppColors.success`)** jika terjadi kenaikan dibanding pencatatan sebelumnya (`diff > 0`).
    - **Merah (`AppColors.error`)** jika terjadi penurunan atau tidak ada kenaikan/stagnan (`diff <= 0`).
  - **Delta Pill Badge**:
    - Tampilkan chip delta dengan icon panah: e.g. `▲ +50 g` (Hijau) atau `▼ -10 g` / `▼ 0 g` (Merah).

### 10. Flutter Layout Constraints & IntrinsicHeight Guard
- Di dalam widget `IntrinsicHeight`, **DILARANG** menggunakan `Row(crossAxisAlignment: CrossAxisAlignment.baseline)` bersamaan dengan `Spacer()` atau `Expanded()`, karena akan memicu crash `computeDryBaseline` pada `RenderPositionedBox`. Gunakan `CrossAxisAlignment.center` atau `CrossAxisAlignment.end`.

### 11. Responsive Multi-Column Grid Cards (Anti Pixel Overflow)
- Pada kartu metrik 2-kolom (`GridView.count` / `KeyMetricsGrid`), ruang horizontal sangat terbatas (~150–170px):
  - Selalu bungkus teks label dengan `Expanded` dan `TextOverflow.ellipsis`.
  - Gunakan teks badge ringkas (misal: `Bagus`, `96%`, `1800 g`) alih-alih kalimat panjang.
  - Terapkan `childAspectRatio: 1.38`–`1.4` agar kartu memiliki ruang vertikal yang lega di semua resolusi perangkat.

### 12. Layar Laporan Periode (*Conclusion-First* untuk Peternak Senior)
- Tampilan laporan mengutamakan kesimpulan performa (untung/efisien vs perlu evaluasi), bukan tabel angka teknis yang membingungkan.
- Komponen wajib:
  1. **Hero Indeks Performa (IP / EPEF)** dengan skor besar, predikat warna, dan kalimat evaluasi bahasa Indonesia sehari-hari.
  2. **4 Kartu Indikator Kunci** (FCR Panen, Daya Hidup, Ayam Dipanen, Rata-rata Bobot).
  3. **Kesimpulan & Saran Periode Berikutnya** (Rekomendasi tindakan konkret pakan, brooding, sanitasi).
  4. **Ringkasan Data Produksi** (Total pakan sak/kg, total panen kg, ADG, durasi).
  5. **Export Cepat** (Tombol Excel & CSV langsung di header laporan).

### 13. Form Design & Margin Consistency Standards
- Seluruh form utama (`FormRecording`, `FormCage`, `FormUser`) diseragamkan dengan spesifikasi visual:
  - **Outer Padding**: `const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)` pada `SingleChildScrollView` dengan pembatas lebar `maxWidth: 640`.
  - **Hero Guidance Card**:
    ```dart
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(...),
    )
    ```
  - **Section Header Style**:
    ```dart
    Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        'SECTION_NAME',
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    )
    ```
  - **Field Spacing**: `const SizedBox(height: 14)` antar field dalam satu section, `const SizedBox(height: 20)` antar section.
  - **Single Label Invariant**: Cukup isi `labelText` pada `AppTextFormField`, jangan pasang `Text(...)` manual di atasnya.

### 14. Profil Saya vs Profil Kandang Visual Hierarchy
- **Profil Saya**: Avatar Bulat 92dp (`CircleAvatar` + Edit Icon) + Hero Nama & Status + List Kontak & Domisili + Full-Width Pill CTA (50dp).
- **Profil Kandang**: Banner Landscape 190dp (`BorderRadius.circular(AppTheme.cardRadius)` + Overlay Ganti Foto) + Hero Card Kapasitas Tampung DOC (`headlineMedium` 32sp) + Spesifikasi Bangunan/Lokasi + Full-Width Pill CTA (50dp).
