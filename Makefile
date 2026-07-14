# =============================================================================
# Makefile untuk Flutter - Chickin Mobile App
# =============================================================================
# Streamlined version - hanya fungsi yang sering dipakai (Windows & Unix Compatible)
# =============================================================================

# OS Detection
ifeq '$(findstring ;,$(PATH))' ';'
    detected_OS := Windows
else
    detected_OS := $(shell uname 2>/dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

# Gradle & OS specifics
ifeq ($(detected_OS),Windows)
  gradle := gradlew.bat
  open_cmd := explorer
  null_dev := nul
  run_test := flutter test
  run_test_coverage := flutter test --coverage
  # Windows: ambil device ID Android & iOS pertama dari output flutter devices
  android_device = $(shell flutter devices 2>nul | findstr /i "android" | for /f "tokens=3" %i in ('more') do @echo %i & goto :break 2>nul || echo "")
  ios_device     = $(shell flutter devices 2>nul | findstr /i "ios" | for /f "tokens=3" %i in ('more') do @echo %i & goto :break 2>nul || echo "")
else
  gradle := ./gradlew
  null_dev := /dev/null
  run_test := bash scripts/test_report.sh
  run_test_coverage := bash scripts/test_report.sh --full
  # Unix/Mac: ambil device ID (kolom ke-4 setelah '•') dari baris android/ios pertama
  android_device = $(shell flutter devices 2>/dev/null | grep -i 'android' | head -1 | awk -F'•' '{gsub(/^[[:space:]]+|[[:space:]]+$$/, "", $$2); print $$2}')
  ios_device     = $(shell flutter devices 2>/dev/null | grep -i 'ios' | head -1 | awk -F'•' '{gsub(/^[[:space:]]+|[[:space:]]+$$/, "", $$2); print $$2}')
  ifeq ($(detected_OS),Darwin)
    open_cmd := open
  else
    open_cmd := xdg-open
  endif
endif

# Application Info Variables
name := Chickin Mobile App
org := chickin
identifier := com.chickin.mobile

null :=
space := $(null) $(null)
filename ?= $(subst $(space),,$(name))

# Additional for KeyStore
jks_locale := Jakarta
jks_state := DKI Jakarta
jks_country := ID

# Generated password fallback if openssl is not present
ifeq (jks, $(firstword $(MAKECMDGOALS)))
  pass := $(shell openssl rand -hex 6 2>$(null_dev) || echo chickin123)
endif

.PHONY: help setup pub-get pub-upgrade build-runner build-runner-watch \
        run run-release run-a run-i run-ar run-ir run-web run-macos build-apk build-aab build-ios build-web deploy-web \
        clean fresh rebuild analyze format test test-coverage lint devices \
        doctor stop-daemon clean-android ip jks create-properties keystore-gradle-kts open z

# =============================================================================
# Help
# =============================================================================
help: ## Tampilkan bantuan
	@echo ============================================================
	@echo           Makefile Flutter - Chickin Mobile App
	@echo ============================================================
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# =============================================================================
##@ Setup & Dependencies
# =============================================================================
setup: pub-get ## Setup proyek (install dependencies)
	@echo '[SUCCESS] Setup selesai!'

pub-get: ## Install dependencies
	@echo '[INFO] Installing dependencies...'
	@flutter pub get
	@echo '[SUCCESS] Dependencies installed!'

pub-upgrade: ## Upgrade dependencies
	@echo '[INFO] Upgrading dependencies...'
	@flutter pub upgrade
	@echo '[SUCCESS] Dependencies upgraded!'

build-runner: ## Generate code (freezed, json_serializable, dll)
	@echo '[BUILD] Running build_runner...'
	@flutter pub run build_runner build --delete-conflicting-outputs
	@echo '[SUCCESS] Build runner selesai!'

build-runner-watch: ## Watch mode untuk build_runner
	@echo '[WATCH] Watching build_runner...'
	@flutter pub run build_runner watch --delete-conflicting-outputs

# =============================================================================
##@ Run Aplikasi
# =============================================================================
run: ## Run aplikasi (debug)
	@flutter run

run-release: ## Run aplikasi (release)
	@flutter run --release

run-a: ## Run di Android (auto-detect device)
	$(eval _adev := $(android_device))
	@[ -n "$(_adev)" ] || (echo '[ERROR] Tidak ada Android device yang terdeteksi. Pastikan device terhubung dan USB debugging aktif.' && exit 1)
	@echo '[RUN] Menjalankan di Android device: $(_adev)'
	@flutter run -d $(_adev)

run-i: ## Run di iOS (auto-detect device)
	$(eval _idev := $(ios_device))
	@[ -n "$(_idev)" ] || (echo '[ERROR] Tidak ada iOS device yang terdeteksi.' && exit 1)
	@echo '[RUN] Menjalankan di iOS device: $(_idev)'
	@flutter run -d $(_idev)

run-ar: ## Run di Android release (auto-detect device)
	$(eval _adev := $(android_device))
	@[ -n "$(_adev)" ] || (echo '[ERROR] Tidak ada Android device yang terdeteksi. Pastikan device terhubung dan USB debugging aktif.' && exit 1)
	@echo '[RUN] Menjalankan release di Android device: $(_adev)'
	@flutter run -d $(_adev) --release

run-ir: ## Run di iOS release (auto-detect device)
	$(eval _idev := $(ios_device))
	@[ -n "$(_idev)" ] || (echo '[ERROR] Tidak ada iOS device yang terdeteksi.' && exit 1)
	@echo '[RUN] Menjalankan release di iOS device: $(_idev)'
	@flutter run -d $(_idev) --release

run-web: ## Run di Web (Chrome)
	@flutter run -d chrome

run-macos: ## Run di macOS
	@flutter run -d macos

# =============================================================================
##@ Build Aplikasi
# =============================================================================
build-apk: ## Build APK Release
	@echo '[BUILD] Building APK Release...'
	@flutter build apk --release
	@echo '[SUCCESS] APK berhasil dibuat!'
	@echo 'Location: build/app/outputs/flutter-apk/app-release.apk'

build-aab: ## Build App Bundle (Play Store)
	@echo '[BUILD] Building App Bundle...'
	@flutter build appbundle --release
	@echo '[SUCCESS] App Bundle berhasil dibuat!'
	@echo 'Location: build/app/outputs/bundle/release/app-release.aab'

build-ios: ## Build iOS
	@echo '[BUILD] Building iOS...'
	@flutter build ios --release
	@echo '[SUCCESS] iOS build berhasil!'

build-web: ## Build Web Release
	@echo '[BUILD] Building Flutter Web...'
	@flutter build web --release
	@echo '[SUCCESS] Web build berhasil!'

deploy-web: clean pub-get build-runner build-web ## Build dan Deploy ke Firebase Hosting
	@echo '[DEPLOY] Deploying to Firebase Hosting...'
	@npx firebase-tools deploy --only hosting
	@echo '[SUCCESS] Deploy selesai!'

# =============================================================================
##@ Clean & Maintenance
# =============================================================================
clean: ## Clean build files
	@echo '[CLEAN] Cleaning...'
	@flutter clean
	@echo '[SUCCESS] Clean selesai!'

fresh: clean pub-get build-runner ## Fresh install (clean + pub get + build runner)
	@echo '[SUCCESS] Fresh install selesai!'

rebuild: clean build-runner build-apk ## Rebuild APK (clean + build runner + build)

# =============================================================================
##@ Code Quality
# =============================================================================
analyze: ## Analisis kode
	@echo '[ANALYZE] Analyzing code...'
	@flutter analyze
	@echo '[SUCCESS] Analysis selesai!'

format: ## Format kode
	@echo '[FORMAT] Formatting code...'
	@dart format lib/ test/
	@echo '[SUCCESS] Formatting selesai!'

test: ## Jalankan unit tests
	@echo '[TEST] Running unit tests...'
	@$(run_test)
	@echo '[SUCCESS] Tests completed!'

test-coverage: ## Jalankan tests dengan coverage report
	@echo '[TEST] Running tests with coverage...'
	@$(run_test_coverage)
	@echo '[SUCCESS] Coverage report completed!'

lint: format analyze ## Lint (format + analyze)

# =============================================================================
##@ Utility
# =============================================================================
devices: ## List connected devices
	@flutter devices

doctor: ## Check development environment variables
	@echo ============================================================
	@echo           Environment and Config Diagnostics
	@echo ============================================================
	@echo OS              : $(detected_OS)
	@echo App Name        : $(name)
	@echo Package Name    : $(identifier)
	@echo Filename        : $(filename)
	@echo Organization    : $(org)
	@echo Gradle Command  : $(gradle)
	@echo Open Command    : $(open_cmd)
	@echo Android Device  : $(android_device)
	@echo iOS Device      : $(ios_device)
	@echo ============================================================
	@flutter doctor

stop-daemon: ## Stop Gradle daemon to free memory
	@echo '[GRADLE] Stopping Gradle daemon...'
	@cd android && $(gradle) --stop
	@echo '[SUCCESS] Gradle daemon stopped.'

clean-android: ## Clean Android gradle build
	@echo '[CLEAN] Cleaning Android Gradle...'
	@cd android && $(gradle) clean
	@echo '[SUCCESS] Android Gradle clean completed.'

ip: ## Get current local IP address
	@echo '[INFO] Local IP Addresses:'
	@ipconfig | findstr /i "ipv4" 2>nul || ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $$2}'

open: ## Open Android build outputs folder
	@echo '[INFO] Opening build output directory...'
	@$(open_cmd) build/app/outputs/flutter-apk/

z: ## Zip project (backup/archive)
	@echo '[ARCHIVE] Archiving project to ../Archive-$(filename).zip...'
	@tar --exclude=".git" --exclude=".dart_tool" --exclude="build" --exclude=".gradle" --exclude=".idea" --exclude="*.iml" -caf ../Archive-$(filename).zip .
	@echo '[SUCCESS] Archive created: ../Archive-$(filename).zip'

jks: ## Generate Android JKS keystore & properties
	@echo '[KEYSTORE] Generating keystore...'
	@keytool -genkeypair -v -keystore android/app/$(filename).jks -alias $(filename) -keyalg RSA -keysize 2048 -validity 10000 -storepass $(pass) -keypass $(pass) -dname "CN=$(name), OU=Development, O=$(org), L=$(jks_locale), ST=$(jks_state), C=$(jks_country)"
	@echo ----------------------------------------
	@echo '[SUCCESS] Keystore successfully generated: android/app/$(filename).jks'
	@echo Password: $(pass)
	@$(MAKE) --no-print-directory create-properties pass=$(pass)
	@$(MAKE) --no-print-directory keystore-gradle-kts pass=$(pass)

create-properties:
	@echo storeFile=$(filename).jks > android/keystore.properties
	@echo keyAlias=$(filename) >> android/keystore.properties
	@echo storePassword=$(pass) >> android/keystore.properties
	@echo keyPassword=$(pass) >> android/keystore.properties
	@echo [SUCCESS] Created android/keystore.properties

keystore-gradle-kts:
	@echo // Generated keystore.gradle.kts > android/app/keystore.gradle.kts
	@echo // Apply this by adding: apply(from = "keystore.gradle.kts") to the bottom of android/app/build.gradle.kts >> android/app/keystore.gradle.kts
	@echo val keystorePropertiesFile = rootProject.file("keystore.properties") >> android/app/keystore.gradle.kts
	@echo val keystoreProperties = java.util.Properties() >> android/app/keystore.gradle.kts
	@echo if (keystorePropertiesFile.exists()) { >> android/app/keystore.gradle.kts
	@echo     keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile)) >> android/app/keystore.gradle.kts
	@echo } >> android/app/keystore.gradle.kts
	@echo android { >> android/app/keystore.gradle.kts
	@echo     signingConfigs { >> android/app/keystore.gradle.kts
	@echo         create("releaseConfig") { >> android/app/keystore.gradle.kts
	@echo             keyAlias = keystoreProperties["keyAlias"] as? String >> android/app/keystore.gradle.kts
	@echo             keyPassword = keystoreProperties["keyPassword"] as? String >> android/app/keystore.gradle.kts
	@echo             storeFile = keystoreProperties["storeFile"]?.let { file(it) } >> android/app/keystore.gradle.kts
	@echo             storePassword = keystoreProperties["storePassword"] as? String >> android/app/keystore.gradle.kts
	@echo         } >> android/app/keystore.gradle.kts
	@echo     } >> android/app/keystore.gradle.kts
	@echo     buildTypes { >> android/app/keystore.gradle.kts
	@echo         release { >> android/app/keystore.gradle.kts
	@echo             signingConfig = signingConfigs.getByName("releaseConfig") >> android/app/keystore.gradle.kts
	@echo         } >> android/app/keystore.gradle.kts
	@echo     } >> android/app/keystore.gradle.kts
	@echo } >> android/app/keystore.gradle.kts
	@echo [SUCCESS] Created android/app/keystore.gradle.kts

