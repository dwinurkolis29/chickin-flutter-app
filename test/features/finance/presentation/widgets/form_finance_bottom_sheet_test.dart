import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/finance/data/models/finance_transaction.dart';
import 'package:recording_app/features/finance/presentation/widgets/form_finance_bottom_sheet.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest({required Function(FinanceTransaction) onSave}) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                FormFinanceBottomSheet.show(
                  context: context,
                  periodId: 'period-1',
                  onSave: onSave,
                );
              },
              child: const Text('Buka Form'),
            );
          },
        ),
      ),
    );
  }

  group('FormFinanceBottomSheet Widget Tests', () {
    testWidgets('menampilkan opsi kategori bawaan dan input nominal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(onSave: (_) {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Form'));
      await tester.pumpAndSettle();

      expect(find.text('Catat Transaksi Keuangan'), findsOneWidget);
      expect(find.text('Pengeluaran (Kas Keluar)'), findsOneWidget);
      expect(find.text('Pemasukan (Kas Masuk)'), findsOneWidget);

      // Kategori Pengeluaran
      expect(find.text('Pakan'), findsOneWidget);
      expect(find.text('DOC (Bibit)'), findsOneWidget);
      expect(find.text('OVK (Obat/Vaksin)'), findsOneWidget);
      expect(find.text('+ Kategori Lain'), findsOneWidget);
    });

    testWidgets('dapat memilih kategori manual kustom dan menyimpannya', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FinanceTransaction? savedTx;

      await tester.pumpWidget(
        createWidgetUnderTest(onSave: (tx) => savedTx = tx),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Form'));
      await tester.pumpAndSettle();

      // Tap '+ Kategori Lain'
      await tester.tap(find.text('+ Kategori Lain'));
      await tester.pumpAndSettle();

      // Input field kategori manual muncul
      expect(find.text('Nama Kategori Manual'), findsOneWidget);

      // Isi nama kategori manual
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Contoh: Disinfektan / Gas Pemanas / Sewa Genset',
        ),
        'Sewa Genset',
      );
      await tester.pumpAndSettle();

      // Isi nominal dengan tombol bantu +1 Juta
      await tester.tap(find.text('+1 Juta'));
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.text('Simpan Pengeluaran'));
      await tester.pumpAndSettle();

      expect(savedTx, isNotNull);
      expect(savedTx!.type, 'expense');
      expect(savedTx!.category, 'Sewa Genset');
      expect(savedTx!.amount, 1000000);
    });

    testWidgets(
      'pemasukan menampilkan input penjualan dan live preview harga per kg',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        FinanceTransaction? savedTx;

        await tester.pumpWidget(
          createWidgetUnderTest(onSave: (tx) => savedTx = tx),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Buka Form'));
        await tester.pumpAndSettle();

        // Pindah ke Pemasukan
        await tester.tap(find.text('Pemasukan (Kas Masuk)'));
        await tester.pumpAndSettle();

        expect(find.text('Penjualan Utama'), findsOneWidget);
        expect(find.text('Afkir / Reject'), findsOneWidget);
        expect(find.text('Ayam Dijual (Ekor)'), findsOneWidget);
        expect(find.text('Total Bobot (Kg)'), findsOneWidget);

        // Isi nominal
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contoh: 15000000'),
          '40000000',
        );
        await tester.pumpAndSettle();

        // Isi bobot 2000 kg
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Opsional: 8900'),
          '2000',
        );
        await tester.pumpAndSettle();

        // Live badge preview harga rata-rata muncul (Rp 40jt / 2000kg = Rp 20.000/kg)
        expect(find.text('Harga Jual Rata-rata:'), findsOneWidget);
        expect(find.text('Rp 20.000 / kg'), findsOneWidget);

        // Simpan Pemasukan
        await tester.tap(find.text('Simpan Pemasukan'));
        await tester.pumpAndSettle();

        expect(savedTx, isNotNull);
        expect(savedTx!.type, 'income');
        expect(savedTx!.category, 'main_harvest');
        expect(savedTx!.amount, 40000000);
        expect(savedTx!.weightKg, 2000);
      },
    );
  });
}
