# Firebase & Firestore Guidelines

## 1. Single Source of Truth

- `FirebaseService` (`lib/core/services/firebase_service.dart`) is the single source of truth for Firestore CRUD operations and collection structures.
- Do not write arbitrary or scattered Firestore calls directly inside Flutter UI widgets.

## 2. Collection Conventions

- Common collections:
  - `users/{uid}`: Profile, metadata, user settings.
  - `users/{uid}/cages/{cageId}`: Master data kandang ayam.
  - `users/{uid}/periods/{periodId}`: Siklus pemeliharaan ayam.
  - `users/{uid}/periods/{periodId}/recordings/{recordingId}`: Catatan harian peternakan (pakan, kematian, bobot).
  - `users/{uid}/reminders/{reminderId}`: Pengingat jadwal pakan/brooding.

## 3. Security Rules & Indexing

- Firestore security rules are maintained in `firestore.rules`.
- Compound queries requiring indexes must be recorded in `firestore.indexes.json`.
- Enforce strict ownership: user data must only be read/written if `request.auth.uid == userId`.

## 4. Testing Firebase

- **Never** hit live/production Firestore during automated tests.
- Always use `mocktail` or inject fake service implementations into controllers when writing unit tests.
