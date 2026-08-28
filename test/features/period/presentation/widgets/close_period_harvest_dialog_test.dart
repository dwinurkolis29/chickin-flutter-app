import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/widgets/close_period_harvest_dialog.dart';

void main() {
  final testPeriod = PeriodData(
    id: 'p1',
    name: 'Periode Batch 1',
    startDate: DateTime(2026, 7, 1),
    initialCapacity: 10000,
    createdAt: DateTime(2026, 7, 1),
  );

  Widget createTestWidget(void Function(BuildContext) onOpen) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onOpen(context),
              child: const Text('Buka Dialog Panen'),
            ),
          ),
        ),
      ),
    );
  }

  group('ClosePeriodHarvestDialog Tests', () {
    testWidgets('menampilkan dialog tutup panen dengan form interaktif', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context) {
          ClosePeriodHarvestDialog.show(context: context, period: testPeriod);
        }),
      );

      await tester.tap(find.text('Buka Dialog Panen'));
      await tester.pumpAndSettle();

      expect(find.text('Tutup Periode Panen'), findsOneWidget);
      expect(find.textContaining('Apakah periode "Periode Batch 1" sudah selesai dipanen?'), findsOneWidget);
      expect(find.text('Ayam Dipanen (Ekor)'), findsOneWidget);
      expect(find.text('Total Bobot Panen (Kg)'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Tutup & Simpan Panen'), findsOneWidget);
    });

    testWidgets('memasukkan data panen menghitung live preview rata-rata bobot dan mengembalikan result', (tester) async {
      ClosePeriodHarvestResult? result;

      await tester.pumpWidget(
        createTestWidget((context) async {
          result = await ClosePeriodHarvestDialog.show(context: context, period: testPeriod);
        }),
      );

      await tester.tap(find.text('Buka Dialog Panen'));
      await tester.pumpAndSettle();

      // Isi ayam dipanen: 9700
      final chicksField = find.byType(TextFormField).first;
      await tester.enterText(chicksField, '9700');
      await tester.pumpAndSettle();

      // Isi total bobot: 17460
      final weightField = find.byType(TextFormField).last;
      await tester.enterText(weightField, '17460');
      await tester.pumpAndSettle();

      // Live preview rata-rata bobot (17460 / 9700 = 1.80 kg)
      expect(find.textContaining('Rata-rata Bobot Panen: 1.80 kg/ekor'), findsOneWidget);

      // Tap Simpan
      await tester.tap(find.text('Tutup & Simpan Panen'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.harvestedChicks, equals(9700));
      expect(result!.harvestedWeightKg, equals(17460.0));
      expect(find.text('Tutup Periode Panen'), findsNothing);
    });

    testWidgets('menekan tombol Batal mengembalikan null', (tester) async {
      ClosePeriodHarvestResult? result;

      await tester.pumpWidget(
        createTestWidget((context) async {
          result = await ClosePeriodHarvestDialog.show(context: context, period: testPeriod);
        }),
      );

      await tester.tap(find.text('Buka Dialog Panen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
