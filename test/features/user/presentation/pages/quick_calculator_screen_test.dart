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
      expect(find.text('Hitung HPP'), findsOneWidget);

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

    testWidgets('mendukung input pakan dalam satuan Sak (50 Kg) dan Kg', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Satuan Input Pakan:'), findsOneWidget);
      expect(find.text('Kg'), findsOneWidget);
      expect(find.text('Sak (50 Kg)'), findsOneWidget);

      // Pindah ke satuan Sak (50 Kg)
      await tester.tap(find.text('Sak (50 Kg)'));
      await tester.pumpAndSettle();

      // 1700 kg terkonversi menjadi 34 sak (34 * 50 = 1700 / 1000 = 1.70)
      expect(find.text('Total Pakan (Sak)'), findsOneWidget);
      expect(find.text('1.70'), findsOneWidget);

      // Ubah input sak menjadi 30 sak (30 * 50 = 1500 kg / 1000 = 1.50)
      final sakField = find.widgetWithText(TextFormField, '34');
      await tester.enterText(sakField, '30');
      await tester.pumpAndSettle();

      expect(find.text('1.50'), findsOneWidget);
      expect(find.text('Sangat Efisien'), findsOneWidget);

      // Pindah kembali ke satuan Kg
      await tester.tap(find.text('Kg'));
      await tester.pumpAndSettle();

      expect(find.text('Total Pakan (Kg)'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('1.50'), findsOneWidget);
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

    testWidgets('menghitung simulasi HPP di tab Hitung HPP', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Switch ke tab Hitung HPP
      await tester.tap(find.text('Hitung HPP'));
      await tester.pumpAndSettle();

      expect(find.text('HARGA POKOK PRODUKSI (HPP)'), findsOneWidget);
      // Default: Rp 95.000.000 / 5000 kg = Rp 19.000 / kg
      expect(find.text('Rp 19.000 / kg'), findsOneWidget);
      expect(find.text('Normal / Kompetitif Pasar'), findsOneWidget);
      expect(find.text('Estimasi Margin Untung: +Rp 2.000 / kg'), findsOneWidget);

      // Ubah biaya produksi ke 80000000
      final costField = find.widgetWithText(TextFormField, '95000000');
      await tester.enterText(costField, '80000000');
      await tester.pumpAndSettle();

      // Rp 80.000.000 / 5000 kg = Rp 16.000 / kg
      expect(find.text('Rp 16.000 / kg'), findsOneWidget);
      expect(find.text('Sangat Hemat / Efisiensi Tinggi'), findsOneWidget);
      expect(find.text('Estimasi Margin Untung: +Rp 5.000 / kg'), findsOneWidget);
    });

    testWidgets('dapat membuka tab IP secara langsung dengan initialIndex 1', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const QuickCalculatorScreen(initialIndex: 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('INDEKS PERFORMA (IP / EPEF)'), findsOneWidget);
      expect(find.text('299.2'), findsOneWidget);
    });
  });
}
