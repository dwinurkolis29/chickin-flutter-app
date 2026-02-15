# =============================================================================
# Makefile untuk Proyek Flutter - Broilerku App
# =============================================================================
# Berdasarkan referensi Makefile React Native, disesuaikan untuk Flutter
# =============================================================================

CFLAGS=-g
export CFLAGS

# =============================================================================
# Deteksi Sistem Operasi
# =============================================================================
ifeq '$(findstring ;,$(PATH))' ';'
    detected_OS := Windows
else
    detected_OS := $(shell uname 2>/dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

ifeq ($(detected_OS),Windows)
    $(eval gradle:=gradlew)
    $(eval open_cmd:=start)
else ifeq ($(detected_OS),Darwin)
    $(eval gradle:=./gradlew)
    $(eval open_cmd:=open)
else
    $(eval gradle:=./gradlew)
    $(eval open_cmd:=xdg-open)
endif

null :=
space := ${null} ${null}
${space} := ${space}

# =============================================================================
# Konfigurasi Aplikasi - SESUAIKAN DENGAN PROYEK ANDA
# =============================================================================
name := Broilerku
org := com.example
identifier := com.example.uts_project

## JKS/KeyStore Configuration
jks_locale := Jakarta
jks_state := DKI Jakarta
jks_country := ID

# =============================================================================
# Konfigurasi Build
# =============================================================================
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
project_folder := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
filename := $(subst ${ },${},${name})

# Android Configuration
android_version := 1.0.0
android_build_number := 1

# iOS Configuration
ios_version := 1.0.0
ios_build_number := 1

# Simulator iOS (opsional, gunakan uuid=xxx)
simulator_ios := ''

# Generated password untuk JKS
ifeq (jks, $(firstword $(MAKECMDGOALS)))
    $(eval pass:=$(shell openssl rand -hex 6))
endif

# UUID simulator
ifneq ($(origin uuid),undefined)
    $(eval simulator_ios:=--device-id=$(uuid))
endif

# =============================================================================
# PHONY Targets
# =============================================================================
.PHONY: help setup doctor clean clean-all pub-get pub-upgrade build-runner \
        run run-release run-profile run-a run-i run-ar run-ir \
        build-apk build-apk-release build-apk-debug build-aab build-ios build-web \
        simulator stop-daemon clean-android clean-ios ip open open-ios \
        jks create-properties keystore-gradle analyze test format \
        firebase-init firebase-config z

# =============================================================================
# Help
# =============================================================================
help: ## Menampilkan bantuan
	@echo ''
	@echo '╔════════════════════════════════════════════════════════════════╗'
	@echo '║          Makefile untuk Proyek Flutter - Broilerku App         ║'
	@echo '╚════════════════════════════════════════════════════════════════╝'
	@echo ''
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ''

# =============================================================================
##@ Setup & Environment
# =============================================================================
setup: pub-get ## Setup proyek (install dependencies)
ifeq ($(detected_OS),Darwin)
	@cd ios && pod install --repo-update
endif
	@echo '✅ Setup selesai!'

doctor: ## Cek environment variables dan Flutter doctor
	@echo ''
	@echo '╔═══════════════════════════════════════════════════════════╗'
	@echo '║                    Environment Info                       ║'
	@echo '╠═══════════════════════════════════════════════════════════╣'
	@echo '  📁 Project Dir    : ${project_folder}'
	@echo '  📱 App Name       : ${name}'
	@echo '  🏷️  Identifier     : ${identifier}'
	@echo '  📄 Filename       : ${filename}'
	@echo '  🖥️  OS Detected    : ${detected_OS}'
ifneq ($(origin uuid),undefined)
	@echo '  📲 Simulator iOS  : ${simulator_ios}'
endif
	@echo '╚═══════════════════════════════════════════════════════════╝'
	@echo ''
	@echo '🔍 Flutter Doctor:'
	@flutter doctor

flutter-version: ## Menampilkan versi Flutter
	@fvm flutter --version

pub-get: ## Install dependencies (flutter pub get)
	@echo '📦 Installing dependencies...'
	@fvm flutter pub get
	@echo '✅ Dependencies installed!'

pub-upgrade: ## Upgrade dependencies (flutter pub upgrade)
	@echo '⬆️  Upgrading dependencies...'
	@fvm flutter pub upgrade
	@echo '✅ Dependencies upgraded!'

pub-outdated: ## Cek dependencies yang outdated
	@fvm flutter pub outdated

build-runner: ## Generate code dengan build_runner (Hive adapters, dll)
	@echo '🔨 Running build_runner...'
	@fvm flutter pub run build_runner build --delete-conflicting-outputs
	@echo '✅ Build runner selesai!'

build-runner-watch: ## Watch mode untuk build_runner
	@fvm flutter pub run build_runner watch --delete-conflicting-outputs

# =============================================================================
##@ Run Aplikasi
# =============================================================================
run: ## Run aplikasi (mode debug)
	@fvm flutter run

run-release: ## Run aplikasi (mode release)
	@fvm flutter run --release

run-profile: ## Run aplikasi (mode profile)
	@fvm flutter run --profile

run-a: ## Run di Android (debug)
	@fvm flutter run -d android

run-i: ## Run di iOS Simulator/Device
ifeq ($(detected_OS),Darwin)
	@fvm flutter run -d ios $(simulator_ios)
else
	@echo '❌ iOS hanya tersedia di macOS'
endif

run-ar: ## Run di Android (release)
	@fvm flutter run -d android --release

run-ir: ## Run di iOS (release)
ifeq ($(detected_OS),Darwin)
	@fvm flutter run -d ios --release $(simulator_ios)
else
	@echo '❌ iOS hanya tersedia di macOS'
endif

run-web: ## Run di Web Browser
	@fvm flutter run -d chrome

run-macos: ## Run di macOS
ifeq ($(detected_OS),Darwin)
	@fvm flutter run -d macos
else
	@echo '❌ macOS hanya tersedia di macOS'
endif

hot-restart: ## Hot restart aplikasi yang sedang berjalan
	@echo 'Tekan "R" di terminal Flutter untuk hot restart'

# =============================================================================
##@ Build Aplikasi
# =============================================================================
build-apk: build-apk-release ## Build APK (alias untuk release)

build-apk-release: clean-android ## Build APK Release
	@echo '🔨 Building APK Release...'
	@fvm flutter build apk --release
	@echo '✅ APK Release berhasil dibuat!'
	@echo '📍 Lokasi: build/app/outputs/flutter-apk/app-release.apk'

build-apk-debug: ## Build APK Debug
	@echo '🔨 Building APK Debug...'
	@fvm flutter build apk --debug
	@echo '✅ APK Debug berhasil dibuat!'
	@echo '📍 Lokasi: build/app/outputs/flutter-apk/app-debug.apk'

build-apk-split: ## Build APK per ABI (lebih kecil)
	@echo '🔨 Building Split APKs...'
	@fvm flutter build apk --split-per-abi --release
	@echo '✅ Split APKs berhasil dibuat!'

build-aab: clean-android ## Build Android App Bundle (untuk Play Store)
	@echo '🔨 Building App Bundle...'
	@fvm flutter build appbundle --release
	@echo '✅ App Bundle berhasil dibuat!'
	@echo '📍 Lokasi: build/app/outputs/bundle/release/app-release.aab'

build-ios: ## Build iOS (archive)
ifeq ($(detected_OS),Darwin)
	@echo '🔨 Building iOS...'
	@cd ios && pod install
	@fvm flutter build ios --release
	@echo '✅ iOS build berhasil!'
else
	@echo '❌ iOS build hanya tersedia di macOS'
endif

build-ipa: ## Build IPA untuk distribusi
ifeq ($(detected_OS),Darwin)
	@echo '🔨 Building IPA...'
	@fvm flutter build ipa --release
	@echo '✅ IPA berhasil dibuat!'
else
	@echo '❌ IPA build hanya tersedia di macOS'
endif

build-web: ## Build Web
	@echo '🔨 Building Web...'
	@fvm flutter build web --release
	@echo '✅ Web build berhasil!'
	@echo '📍 Lokasi: build/web/'

build-macos: ## Build macOS
ifeq ($(detected_OS),Darwin)
	@echo '🔨 Building macOS...'
	@fvm flutter build macos --release
	@echo '✅ macOS build berhasil!'
else
	@echo '❌ macOS build hanya tersedia di macOS'
endif

build-all: build-apk-release build-aab ## Build semua platform Android
	@echo '✅ Semua build Android selesai!'

# =============================================================================
##@ Clean & Maintenance
# =============================================================================
clean: ## Clean build files Flutter
	@echo '🧹 Cleaning Flutter build...'
	@fvm flutter clean
	@echo '✅ Clean selesai!'

clean-all: clean clean-android clean-ios ## Clean semua (Flutter + Android + iOS)
	@echo '✅ Semua clean selesai!'

clean-android: ## Clean Android build
	@echo '🧹 Cleaning Android...'
	@cd android && $(gradle) clean 2>/dev/null || true
	@echo '✅ Android clean selesai!'

clean-ios: ## Clean iOS build
ifeq ($(detected_OS),Darwin)
	@echo '🧹 Cleaning iOS...'
	@cd ios && rm -rf Pods Podfile.lock
	@cd ios && rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
	@echo '✅ iOS clean selesai!'
else
	@echo 'ℹ️  iOS clean hanya tersedia di macOS'
endif

stop-daemon: ## Stop Gradle daemon
	@cd android && $(gradle) --stop 2>/dev/null || true
	@echo '✅ Gradle daemon stopped!'

# =============================================================================
##@ Utility
# =============================================================================
simulator: ## List iOS simulators
ifeq ($(detected_OS),Darwin)
	@xcrun simctl list | grep -E "Booted|Shutdown" | head -20
else
	@echo '❌ Simulators hanya tersedia di macOS'
endif

devices: ## List semua connected devices
	@fvm flutter devices

emulators: ## List Android emulators
	@fvm flutter emulators

launch-emulator: ## Launch Android emulator
	@fvm flutter emulators --launch $(shell flutter emulators 2>/dev/null | grep -m1 'id' | awk '{print $$2}')

ip: ## Dapatkan IP address saat ini
ifeq ($(detected_OS),Darwin)
	@ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $$2}'
else ifeq ($(detected_OS),Linux)
	@hostname -I | awk '{print $$1}'
else
	@echo 'IP detection not supported on this OS'
endif

open: ## Buka folder output APK
ifeq ($(detected_OS),Darwin)
	@open build/app/outputs/flutter-apk/ 2>/dev/null || open build/app/outputs/ 2>/dev/null || echo '📁 Folder belum ada, jalankan build terlebih dahulu'
else ifeq ($(detected_OS),Linux)
	@xdg-open build/app/outputs/flutter-apk/ 2>/dev/null || echo '📁 Folder belum ada'
else
	@start build/app/outputs/flutter-apk/ 2>/dev/null || echo '📁 Folder belum ada'
endif

open-ios: ## Buka Xcode workspace
ifeq ($(detected_OS),Darwin)
	@open ios/Runner.xcworkspace
else
	@echo '❌ Xcode hanya tersedia di macOS'
endif

open-android: ## Buka proyek di Android Studio
	@$(open_cmd) android/

# =============================================================================
##@ Keystore & Signing
# =============================================================================
jks: ## Generate file JKS untuk signing
	@echo '🔐 Generating keystore...'
	@keytool -genkeypair -v \
		-keystore ${filename}.jks \
		-alias ${filename} \
		-keyalg RSA \
		-keysize 2048 \
		-validity 10000 \
		-storepass ${pass} \
		-keypass ${pass} \
		-dname "CN=${name}, OU=Development, O=${name}, L=${jks_locale}, ST=${jks_state}, C=${jks_country}"
	@echo ''
	@mv ${filename}.jks android/app/${filename}.jks
	@echo '✅ Keystore berhasil dibuat!'
	@echo ''
	@echo '🔑 Informasi Keystore:'
	@echo '   File      : android/app/${filename}.jks'
	@echo '   Alias     : ${filename}'
	@echo '   Password  : ${pass}'
	@echo ''
	@$(MAKE) create-properties pass=${pass}
	@$(MAKE) keystore-gradle
	@echo ''
	@echo '⚠️  PENTING: Simpan password di tempat yang aman!'
	@echo '📄 File keystore.properties telah dibuat di android/'

create-properties:
	@echo '# =================================' > android/keystore.properties
	@echo '# Keystore Properties' >> android/keystore.properties
	@echo '# Generated by Makefile' >> android/keystore.properties
	@echo '# =================================' >> android/keystore.properties
	@echo '' >> android/keystore.properties
	@echo '# JANGAN COMMIT FILE INI KE GIT!' >> android/keystore.properties
	@echo '# Tambahkan ke .gitignore' >> android/keystore.properties
	@echo '' >> android/keystore.properties
	@echo 'storeFile=app/${filename}.jks' >> android/keystore.properties
	@echo 'keyAlias=${filename}' >> android/keystore.properties
	@echo 'storePassword=${pass}' >> android/keystore.properties
	@echo 'keyPassword=${pass}' >> android/keystore.properties
	@echo '✅ keystore.properties dibuat di android/'

keystore-gradle:
	@echo '// =========================================' > android/app/keystore.gradle
	@echo '// Keystore Configuration for Release Build' >> android/app/keystore.gradle
	@echo '// Generated by Makefile' >> android/app/keystore.gradle
	@echo '// =========================================' >> android/app/keystore.gradle
	@echo '//' >> android/app/keystore.gradle
	@echo '// Untuk Kotlin DSL (build.gradle.kts):' >> android/app/keystore.gradle
	@echo '//   apply(from = "keystore.gradle")' >> android/app/keystore.gradle
	@echo '//' >> android/app/keystore.gradle
	@echo '// Untuk Groovy DSL (build.gradle):' >> android/app/keystore.gradle
	@echo '//   apply from: "keystore.gradle"' >> android/app/keystore.gradle
	@echo '// =========================================' >> android/app/keystore.gradle
	@echo '' >> android/app/keystore.gradle
	@echo 'def keystorePropertiesFile = rootProject.file("keystore.properties")' >> android/app/keystore.gradle
	@echo 'def keystoreProperties = new Properties()' >> android/app/keystore.gradle
	@echo '' >> android/app/keystore.gradle
	@echo 'if (keystorePropertiesFile.exists()) {' >> android/app/keystore.gradle
	@echo '    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))' >> android/app/keystore.gradle
	@echo '' >> android/app/keystore.gradle
	@echo '    android {' >> android/app/keystore.gradle
	@echo '        signingConfigs {' >> android/app/keystore.gradle
	@echo '            release {' >> android/app/keystore.gradle
	@echo '                keyAlias keystoreProperties["keyAlias"]' >> android/app/keystore.gradle
	@echo '                keyPassword keystoreProperties["keyPassword"]' >> android/app/keystore.gradle
	@echo '                storeFile file(keystoreProperties["storeFile"])' >> android/app/keystore.gradle
	@echo '                storePassword keystoreProperties["storePassword"]' >> android/app/keystore.gradle
	@echo '            }' >> android/app/keystore.gradle
	@echo '        }' >> android/app/keystore.gradle
	@echo '' >> android/app/keystore.gradle
	@echo '        buildTypes {' >> android/app/keystore.gradle
	@echo '            release {' >> android/app/keystore.gradle
	@echo '                signingConfig signingConfigs.release' >> android/app/keystore.gradle
	@echo '            }' >> android/app/keystore.gradle
	@echo '        }' >> android/app/keystore.gradle
	@echo '    }' >> android/app/keystore.gradle
	@echo '}' >> android/app/keystore.gradle
	@echo '✅ keystore.gradle dibuat di android/app/'

# =============================================================================
##@ Code Quality
# =============================================================================
analyze: ## Analisis kode (dart analyze)
	@echo '🔍 Analyzing code...'
	@flutter analyze
	@echo '✅ Analysis selesai!'

format: ## Format kode (dart format)
	@echo '✨ Formatting code...'
	@dart format lib/
	@echo '✅ Formatting selesai!'

format-check: ## Cek format kode tanpa mengubah
	@dart format --set-exit-if-changed lib/

test: ## Jalankan unit tests
	@echo '🧪 Running tests...'
	@flutter test
	@echo '✅ Tests selesai!'

test-coverage: ## Jalankan tests dengan coverage
	@flutter test --coverage
	@echo '📊 Coverage report: coverage/lcov.info'

lint: analyze format-check ## Jalankan linting (analyze + format check)

# =============================================================================
##@ Firebase
# =============================================================================
firebase-init: ## Inisialisasi Firebase (FlutterFire CLI)
	@echo '🔥 Initializing Firebase...'
	@dart pub global activate flutterfire_cli
	@flutterfire configure
	@echo '✅ Firebase initialized!'

firebase-config: ## Re-configure Firebase
	@flutterfire configure

# =============================================================================
##@ Archive & Backup
# =============================================================================
z: ## Zip proyek (exclude build files)
	@echo '📦 Creating archive...'
	@cd .. && zip -r Archive_${filename}_$(shell date +%Y%m%d_%H%M%S).zip ${project_folder}/ \
		-x "*.git/*" \
		-x "*/.idea/*" \
		-x "*/build/*" \
		-x "*/.dart_tool/*" \
		-x "*/ios/Pods/*" \
		-x "*/ios/.symlinks/*" \
		-x "*/.gradle/*" \
		-x "*/android/.gradle/*" \
		-x "*/.DS_Store" \
		-x "*.iml" \
		-x "*.hprof" \
		-x "*.lock" \
		-x "*.log" \
		-x "*/pubspec.lock"
	@echo '✅ Archive created: ../Archive_${filename}_*.zip'

backup: z ## Alias untuk zip

# =============================================================================
##@ Quick Commands
# =============================================================================
fresh: clean pub-get ## Fresh install (clean + pub get)
ifeq ($(detected_OS),Darwin)
	@cd ios && pod install --repo-update
endif
	@echo '✅ Fresh install selesai!'

rebuild: clean build-apk-release ## Rebuild APK (clean + build)

deploy-android: build-aab ## Alias untuk build AAB (Play Store ready)
	@echo '📱 App Bundle siap untuk upload ke Play Store!'

# =============================================================================
# Default target
# =============================================================================
.DEFAULT_GOAL := help
