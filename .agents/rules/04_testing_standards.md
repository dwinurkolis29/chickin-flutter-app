# Unit Testing Standards (TESTING_AGENT)

Refer to [TESTING_AGENT.md](file:///Users/nurkolis/IdeaProjects/chickin-flutter-app/TESTING_AGENT.md) as the primary specification.

## 1. Test Pyramid & Priorities

- **70% Unit Test**, **20% Widget Test**, **10% Integration Test**.
- Prioritize unit testing pure business logic, calculations, and models over widget rendering.
- Implementation Priority:
  1. `safe_convert.dart`, all domain models, domain usecases/calculators (`100% coverage`).
  2. Controllers / `ChangeNotifier` (`80% coverage`).
  3. Services (mocked) (`80% coverage`).
  4. Core screen widgets (`50% coverage`).

## 2. Test Structure: AAA Pattern

All unit tests must strictly follow the **Arrange-Act-Assert (AAA)** pattern and be enclosed in `group()` blocks:
```dart
group('CalculateFCR', () {
  test('should return correct FCR value when valid data provided', () {
    // Arrange
    final calculator = CalculateFCR();
    const totalFeedKg = 3200.0;
    const totalWeightKg = 2150.0;

    // Act
    final result = calculator.execute(totalFeed: totalFeedKg, totalWeight: totalWeightKg);

    // Assert
    expect(result, 1.488);
  });
});
```

## 3. Test Cases Coverage Requirements

Every tested function/method must cover:
- Happy path
- Boundary values
- `null` & empty inputs
- Invalid types / missing keys in JSON models
- Edge cases & regressions

## 4. Realistic Mock Data

- Use realistic farming domain data (e.g. 35 days, 1000 birds, 3200 kg feed, 18 mortality, 2.15 kg weight).
- Avoid vague placeholders like `foo`, `bar`, `test_user`, `123`.

## 5. Folder Mirroring

Mirror `lib/` 1:1 inside `test/`:
- `lib/features/recording/domain/calculate_fcr.dart` -> `test/features/recording/domain/calculate_fcr_test.dart`
- `lib/features/cage/data/models/cage_data.dart` -> `test/features/cage/data/models/cage_data_test.dart`
