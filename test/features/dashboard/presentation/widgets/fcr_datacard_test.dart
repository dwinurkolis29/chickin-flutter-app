import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/fcr_datacard.dart';
import 'package:recording_app/features/recording/data/models/fcr_data.dart';

void main() {
  Widget createWidgetUnderTest(List<FCRData> fcrData) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: FCRDataCard(fcrData: fcrData),
        ),
      ),
    );
  }

  group('FCRDataCard Widget Tests', () {
    testWidgets('menampilkan pesan kosong jika fcrData kosong', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest([]));
      expect(find.text('Belum ada data FCR mingguan untuk ditampilkan.'), findsOneWidget);
    });

    testWidgets('menampilkan kartu FCR mingguan dan dapat di-expand', (tester) async {
      final sampleFCR = [
        FCRData(
          mingguKe: 1,
          fcr: 1.65,
          totalPakan: 500,
          beratAyam: 303,
          sisaAyam: 2980,
        ),
        FCRData(
          mingguKe: 2,
          fcr: 2.01,
          totalPakan: 600,
          beratAyam: 298.8,
          sisaAyam: 2988,
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(sampleFCR));
      await tester.pump();

      // Header Minggu 1 & 2
      expect(find.text('Minggu 1'), findsOneWidget);
      expect(find.text('Umur 1 - 7 Hari'), findsOneWidget);
      expect(find.text('FCR 1,65 • Efisien'), findsOneWidget);

      expect(find.text('Minggu 2'), findsOneWidget);
      expect(find.text('Umur 8 - 14 Hari'), findsOneWidget);
      expect(find.text('FCR 2,01 • Cukup'), findsOneWidget);

      // Tap Minggu 2 untuk expand
      await tester.tap(find.text('Minggu 2'));
      await tester.pumpAndSettle();

      // Memastikan rincian data pakan dan bobot ayam tampil
      expect(find.text('Total Pakan Dikonsumsi'), findsNWidgets(2));
      expect(find.text('Total Bobot Ayam Hidup'), findsNWidgets(2));
      expect(find.text('Sisa Ayam Hidup'), findsNWidgets(2));
      expect(find.text('Rumus: Total Pakan (kg) ÷ Total Bobot (kg) = FCR'), findsNWidgets(2));
    });
  });
}
