---
name: flutter-release
description: Step-by-step checklist and commands for version bumping, signing, and building Android AAB/APK or Web releases for Chickin.
---

# Flutter Release Build Workflow

Use this skill when preparing, signing, and generating production builds for Google Play Console or Firebase Hosting.

## 1. Version Bumping & SDK Pre-checks

1. **Version Code in `pubspec.yaml`**:
   - Increment the build number: `version: 1.0.0+X`.
2. **Android SDK Target**:
   - Verify `android/app/build.gradle.kts`:
     - `compileSdk = 36` (Android 16)
     - `targetSdk = 36` (Android 16)
     - `minSdk = 23` (Android 6.0)

## 2. Build Commands

### Android App Bundle (Google Play)
```bash
make build-aab
# or
flutter build appbundle --release
```
- Output location: `build/app/outputs/bundle/release/app-release.aab`

### Android APK (Direct Distribution / Testing)
```bash
make build-apk
# or
flutter build apk --release
```
- Output location: `build/app/outputs/flutter-apk/app-release.apk`

### Flutter Web (Firebase Hosting)
```bash
make deploy-web
# or
flutter build web --release
npx firebase-tools deploy --only hosting
```

## 3. Signing Keystore Verification

- Keystore configuration is loaded from `android/keystore.properties`.
- Ensure keystore file exists in `android/app/<filename>.jks` before initiating release builds.
