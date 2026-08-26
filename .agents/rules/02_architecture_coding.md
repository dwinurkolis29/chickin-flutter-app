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
- Available helpers: `asString`, `asInt`, `asDouble`, `asBool`.
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

