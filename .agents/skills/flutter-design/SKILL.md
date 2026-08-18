---
name: flutter-design
description: Design system and UI styling reference for Chickin (BroilerKu) Flutter app — Vivid Blue Material 3 theme, shape constants, FCR semantic status colors, typography (Plus Jakarta Sans), DialogHelper, and reusable components. Use this skill automatically whenever writing, editing, or reviewing ANY Flutter UI code, widget, dialog, or screen.
---

# Chickin (BroilerKu) — Design System

Gunakan panduan ini sebagai standar visual utama saat membuat atau memodifikasi widget/layar di aplikasi Chickin.

## Implementation Rule (WAJIB DIIKUTI)

- **DILARANG KERAS** menuliskan `Color(0xFF...)` atau literal hex baru di dalam file widget/screen manapun.
- **DILARANG KERAS** menggunakan konstanta warna statis Material seperti `Colors.white`, `Colors.black`, `Colors.transparent` secara langsung.
- Selalu gunakan referensi tema: `Theme.of(context).colorScheme.*` atau konstanta dari `lib/core/theme/app_colors.dart`.
- Semua pemanggilan dialog **WAJIB** melalui `DialogHelper` (`lib/core/components/dialogs/dialog_helper.dart`).
- Tetapkan `visualDensity: VisualDensity.standard` agar komponen di Flutter Web tidak gepeng (sudah diset di `AppTheme`).
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
| `AppTheme.pillRadius` | `999.0` | Button, chip, input field, nav indicator |
| `AppTheme.cardRadius` | `24.0` | Card, container utama, dialog |
| `AppTheme.rowRadius` | `16.0` | Sheet row, list tile decoration, inner container |
| `AppTheme.snackbarRadius` | `4.0` | Snackbar saja |

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

### 1. Dialogs
Selalu gunakan `DialogHelper.showConfirmDialog()`, `DialogHelper.showErrorDialog()`, dll. Jangan `showDialog` mentah.

### 2. Cards & Containers
- Radius: `AppTheme.cardRadius` (24dp).
- Color: `colorScheme.surfaceContainer` — **bukan** `Colors.white`.
- Elevation: 1 (sudah di-set di `CardThemeData`).

### 3. Buttons
- **FilledButton**: CTA primer, pill, full-width, min 48dp.
- **OutlinedButton**: CTA sekunder / ghost, pill, full-width.
- **TextButton**: Link / aksi tertier — foreground `primary`.

### 4. Input Fields
- Pill shape, filled `surfaceContainer`. Wajib ada leading icon.

### 5. Status Badge di atas Hero Card (Primary Background)
- Jangan pakai `AppColors.*OnPrimary` — sudah dihapus.
- Gunakan pastel inline: green `#A3E6BE`, amber `#FFD580`, red `#FF9A9A`.
- Lihat contoh di [`report_summary_header.dart`](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/lib/features/reporting/presentation/widgets/report_summary_header.dart).
