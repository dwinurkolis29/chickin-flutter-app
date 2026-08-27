import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/user/presentation/pages/broiler_encyclopedia_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: const BroilerEncyclopediaScreen(),
    );
  }

  group('BroilerEncyclopediaScreen Widget Tests', () {
    testWidgets('menampilkan header, banner, search field, dan kalkulator simulasi', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header & Banner
      expect(find.text('Ensiklopedia Broiler'), findsOneWidget);
      expect(find.text('Kamus & Rumus Peternak'), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsWidgets);

      // Filter chips
      expect(find.text('Semua Istilah'), findsOneWidget);
      expect(find.text('Pakan & FCR'), findsOneWidget);
      expect(find.text('Performa & IP'), findsOneWidget);

      // Kalkulator Simulasi
      expect(find.text('Simulasi Hitung Cepat'), findsOneWidget);
      expect(find.text('1. Hitung FCR'), findsOneWidget);
      expect(find.text('2. Hitung IP (Performa)'), findsOneWidget);
    });

    testWidgets('menghitung simulasi FCR dan IP dengan benar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Default FCR: 1700 / 1000 = 1.70
      expect(find.text('1.70'), findsOneWidget);

      // Ubah input pakan ke 1500
      final pakanField = find.widgetWithText(TextField, '1700');
      await tester.enterText(pakanField, '1500');
      await tester.pump();

      // 1500 / 1000 = 1.50
      expect(find.text('1.50'), findsOneWidget);

      // Switch ke tab Hitung IP
      await tester.tap(find.text('2. Hitung IP (Performa)'));
      await tester.pumpAndSettle();

      expect(find.text('Hasil Indeks Prestasi (IP):'), findsOneWidget);
      expect(find.text('Daya Hidup (%)'), findsOneWidget);
    });

    testWidgets('pencarian istilah menyaring item ensiklopedia', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'HPP');
      await tester.pumpAndSettle();

      expect(find.textContaining('HPP (Harga Pokok Produksi'), findsOneWidget);
      expect(find.textContaining('FCR (Feed Conversion Ratio'), findsNothing);
    });

    testWidgets('filter kategori menyaring item yang sesuai', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Performa & IP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('IP / EPEF'), findsOneWidget);
      expect(find.textContaining('Mortalitas'), findsNothing);
    });

    testWidgets('expand/collapse kartu menampilkan rumus dan contoh', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // FCR sudah default expanded
      expect(find.text('Rumus Sederhana:'), findsWidgets);
      expect(find.text('FCR = Total Pakan Dikonsumsi (kg) ÷ Total Bobot Ayam (kg)'), findsOneWidget);
      expect(find.text('Contoh Nyata:'), findsWidgets);
      expect(find.text('Arti Angka & Standar:'), findsWidgets);
    });
  });
}
