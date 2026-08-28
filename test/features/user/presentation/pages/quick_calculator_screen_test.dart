import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/user/presentation/pages/quick_calculator_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: const QuickCalculatorScreen(),
    );
  }

  group('QuickCalculatorScreen Widget Tests', () {
    testWidgets('menampilkan header, tab bar, dan kalkulator FCR default', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Kalkulator Cepat'), findsOneWidget);
      expect(find.text('Hitung FCR'), findsOneWidget);
      expect(find.text('Hitung IP'), findsOneWidget);
      expect(find.text('Kebutuhan Pakan'), findsOneWidget);

      // Default FCR Tab: 1700 / 1000 = 1.70
      expect(find.text('NILAI FCR SIMULASI'), findsOneWidget);
      expect(find.text('1.70'), findsOneWidget);
      expect(find.text('Efisien (Standar Baik)'), findsOneWidget);
    });

    testWidgets('menghitung simulasi FCR secara real-time saat nilai diubah', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Ubah pakan ke 1500
      final feedField = find.widgetWithText(TextFormField, '1700');
      await tester.enterText(feedField, '1500');
      await tester.pumpAndSettle();

      // 1500 / 1000 = 1.50 -> Sangat Efisien
      expect(find.text('1.50'), findsOneWidget);
      expect(find.text('Sangat Efisien'), findsOneWidget);
    });

    testWidgets('menghitung simulasi IP / EPEF di tab Hitung IP', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Switch ke tab Hitung IP
      await tester.tap(find.text('Hitung IP'));
      await tester.pumpAndSettle();

      expect(find.text('INDEKS PERFORMA (IP / EPEF)'), findsOneWidget);
      // Default: (96 * 1.8 * 100) / (35 * 1.65) = 299.2
      expect(find.text('299.2'), findsOneWidget);
      expect(find.text('Cukup / Perhatian'), findsOneWidget);

      // Ubah Livability ke 98 dan FCR ke 1.55
      final livabilityField = find.widgetWithText(TextFormField, '96');
      await tester.enterText(livabilityField, '98');
      await tester.pumpAndSettle();

      final fcrField = find.widgetWithText(TextFormField, '1.65');
      await tester.enterText(fcrField, '1.55');
      await tester.pumpAndSettle();

      // (98 * 1.8 * 100) / (35 * 1.55) = 325.2 -> Baik / Standar
      expect(find.text('325.2'), findsOneWidget);
      expect(find.text('Baik / Standar'), findsOneWidget);
    });

    testWidgets('menghitung estimasi kebutuhan pakan di tab Kebutuhan Pakan', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Switch ke tab Kebutuhan Pakan
      await tester.tap(find.text('Kebutuhan Pakan'));
      await tester.pumpAndSettle();

      expect(find.text('ESTIMASI KEBUTUHAN PAKAN'), findsOneWidget);
      // Default: 3000 * 1.80 * 1.65 = 8910 kg -> 179 Sak
      expect(find.text('8910 Kg'), findsOneWidget);
      expect(find.text('179 Sak'), findsOneWidget);
    });
  });
}
