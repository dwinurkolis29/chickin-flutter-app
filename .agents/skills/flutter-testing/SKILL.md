---
name: flutter-testing
description: Run and author unit, model, and controller tests for Chickin Flutter App using test_report.sh and mocktail.
---

# Flutter Testing Workflow for Chickin

Follow this workflow whenever creating, updating, or running automated tests in Chickin Flutter App.

## 1. Running Tests

### Standard Test Run
```bash
make test
# or direct script
bash scripts/test_report.sh
```

### Full Coverage Test Run
```bash
make test-coverage
# or direct script with full flag
bash scripts/test_report.sh --full
```

## 2. Test Authoring Checklist

When adding tests for a feature:
1. **Identify Target Layer**:
   - Model (`fromMap`, `toMap`, `copyWith`, `safe_convert` fallback).
   - Domain usecases / calculators (100% pure unit test).
   - Controller (`ChangeNotifier` loading, success, error state transitions with mocked dependencies).
2. **Setup File Location**:
   - Mirror `lib/` structure under `test/` directory.
   - Example: `test/features/period/presentation/controllers/period_controller_test.dart`.
3. **Use Mocktail**:
   - Mock external dependencies (`FirebaseService`, `AuthService`, `NotificationService`).
   - Register fallback values when necessary.
4. **Follow AAA Pattern**:
   - Group by method name.
   - Distinct Arrange, Act, and Assert blocks.
5. **Verify**:
   - Run `bash scripts/test_report.sh` and ensure all tests pass with zero regressions.
