# =============================================================================
# Makefile untuk Flutter - Chickin App
# =============================================================================
# Streamlined version - hanya fungsi yang sering dipakai
# =============================================================================

.PHONY: help setup clean fresh run run-a run-i build-apk build-aab \
        pub-get build-runner analyze format test devices

# =============================================================================
# Help
# =============================================================================
help: ## Tampilkan bantuan
	@echo ''
	@echo '╔════════════════════════════════════════════════════════════╗'
	@echo '║          Makefile Flutter - Chickin App                   ║'
	@echo '╚════════════════════════════════════════════════════════════╝'
	@echo ''
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ''

# =============================================================================
##@ Setup & Dependencies
# =============================================================================
setup: pub-get ## Setup proyek (install dependencies)
	@echo '✅ Setup selesai!'

pub-get: ## Install dependencies
	@echo '📦 Installing dependencies...'
	@fvm flutter pub get
	@echo '✅ Dependencies installed!'

pub-upgrade: ## Upgrade dependencies
	@echo '⬆️  Upgrading dependencies...'
	@fvm flutter pub upgrade
	@echo '✅ Dependencies upgraded!'

build-runner: ## Generate code (freezed, json_serializable, dll)
	@echo '🔨 Running build_runner...'
	@fvm flutter pub run build_runner build --delete-conflicting-outputs
	@echo '✅ Build runner selesai!'

build-runner-watch: ## Watch mode untuk build_runner
	@fvm flutter pub run build_runner watch --delete-conflicting-outputs

# =============================================================================
##@ Run Aplikasi
# =============================================================================
run: ## Run aplikasi (debug)
	@fvm flutter run

run-release: ## Run aplikasi (release)
	@fvm flutter run --release

run-a: ## Run di Android
	@fvm flutter run -d $(shell fvm flutter devices | grep 'android' | cut -d '•' -f 2 | awk '{print $$1}' | head -n 1)

run-i: ## Run di iOS
	@fvm flutter run -d iPhone

run-ar: ## Run di Android (release)
	@fvm flutter run -d $(shell fvm flutter devices | grep 'android' | cut -d '•' -f 2 | awk '{print $$1}' | head -n 1) --release

run-ir: ## Run di iOS (release)
	@fvm flutter run -d iPhone --release

run-web: ## Run di Web (Chrome)
	@fvm flutter run -d chrome

run-macos: ## Run di macOS
	@fvm flutter run -d macos

# =============================================================================
##@ Build Aplikasi
# =============================================================================
build-apk: ## Build APK Release
	@echo '🔨 Building APK Release...'
	@fvm flutter build apk --release
	@echo '✅ APK berhasil dibuat!'
	@echo '📍 Lokasi: build/app/outputs/flutter-apk/app-release.apk'

build-aab: ## Build App Bundle (Play Store)
	@echo '🔨 Building App Bundle...'
	@fvm flutter build appbundle --release
	@echo '✅ App Bundle berhasil dibuat!'
	@echo '📍 Lokasi: build/app/outputs/bundle/release/app-release.aab'

build-ios: ## Build iOS
	@echo '🔨 Building iOS...'
	@fvm flutter build ios --release
	@echo '✅ iOS build berhasil!'

# =============================================================================
##@ Clean & Maintenance
# =============================================================================
clean: ## Clean build files
	@echo '🧹 Cleaning...'
	@fvm flutter clean
	@echo '✅ Clean selesai!'

fresh: clean pub-get ## Fresh install (clean + pub get)
	@echo '✅ Fresh install selesai!'

rebuild: clean build-apk ## Rebuild APK (clean + build)

# =============================================================================
##@ Code Quality
# =============================================================================
analyze: ## Analisis kode
	@echo '🔍 Analyzing code...'
	@fvm flutter analyze
	@echo '✅ Analysis selesai!'

format: ## Format kode
	@echo '✨ Formatting code...'
	@dart format lib/
	@echo '✅ Formatting selesai!'

test: ## Jalankan unit tests
	@echo '🧪 Running tests...'
	@fvm flutter test
	@echo '✅ Tests selesai!'

test-coverage: ## Jalankan tests dengan coverage
	@fvm flutter test --coverage
	@echo '📊 Coverage report: coverage/lcov.info'

lint: analyze format ## Lint (analyze + format)

# =============================================================================
##@ Utility
# =============================================================================
devices: ## List connected devices
	@fvm flutter devices

# =============================================================================
# Default target
# =============================================================================
.DEFAULT_GOAL := help
