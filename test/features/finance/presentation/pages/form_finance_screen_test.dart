import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/forms/app_text_form_field.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/finance/data/models/finance_summary.dart';
import 'package:recording_app/features/finance/data/models/finance_transaction.dart';
import 'package:recording_app/features/finance/domain/usecases/calculate_finance_summary.dart';
import 'package:recording_app/features/finance/presentation/controllers/finance_controller.dart';
import 'package:recording_app/features/finance/presentation/pages/form_finance_screen.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  @override
  Stream<List<FinanceTransaction>> getFinanceTransactionsStream(
    String periodId, [
    String? uid,
  ]) {
    return Stream.value([]);
  }
}

class _MockFinanceController extends FinanceController {
  FinanceTransaction? lastAddedTransaction;
  FinanceTransaction? lastUpdatedTransaction;

  _MockFinanceController()
    : super(
        firebaseService: _FakeFirebaseService(),
        calculateSummary: CalculateFinanceSummary(),
      );

  @override
  Future<void> addTransaction(FinanceTransaction tx) async {
    lastAddedTransaction = tx;
  }

  @override
  Future<void> updateTransaction(FinanceTransaction tx) async {
    lastUpdatedTransaction = tx;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest({
    Function(FinanceTransaction)? onSave,
    FinanceController? controller,
    FinanceTransaction? existingTransaction,
  }) {
    final ctrl = controller ?? _MockFinanceController();
    return MultiProvider(
      providers: [ChangeNotifierProvider<FinanceController>.value(value: ctrl)],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: FormFinanceScreen(
          periodId: 'period-1',
          periodName: 'Batch 1 Test',
          onSave: onSave,
          controller: ctrl,
          existingTransaction: existingTransaction,
        ),
      ),
    );
  }

  group('FormFinanceScreen Widget Tests', () {
    testWidgets('menampilkan elemen form lengkap sesuai desain M3', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header & Title
      expect(find.text('Catat Transaksi (Batch 1 Test)'), findsOneWidget);

      // Hero Guidance Card
      expect(
        find.text(
          'Catat pengeluaran operasional (Pakan, DOC, OVK, dll.) secara akurat untuk kalkulasi HPP riil kandang.',
        ),
        findsOneWidget,
      );

      // Jenis Kas Toggle
      expect(find.text('Pengeluaran (Kas Keluar)'), findsOneWidget);
      expect(find.text('Pemasukan (Kas Masuk)'), findsOneWidget);

      // Kategori Bawaan Pengeluaran
      expect(find.text('Pakan'), findsOneWidget);
      expect(find.text('DOC (Bibit)'), findsOneWidget);
      expect(find.text('OVK (Obat/Vaksin)'), findsOneWidget);
      expect(find.text('Tenaga Kerja'), findsOneWidget);
      expect(find.text('+ Kategori Lain'), findsOneWidget);

      // Quick Add Chips
      expect(find.text('+50 rb'), findsOneWidget);
      expect(find.text('+100 rb'), findsOneWidget);
      expect(find.text('+500 rb'), findsOneWidget);
      expect(find.text('+1 jt'), findsOneWidget);

      // Tanggal & Catatan
      expect(find.text('Tanggal Transaksi'), findsOneWidget);
      expect(find.text('Catatan / Nomor Nota (Opsional)'), findsOneWidget);

      // CTA Button
      expect(find.text('Simpan Transaksi Keuangan'), findsOneWidget);
    });

    testWidgets('dapat beralih ke jenis Pemasukan dan mengubah kategori', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap tab Pemasukan
      await tester.tap(find.text('Pemasukan (Kas Masuk)'));
      await tester.pumpAndSettle();

      // Hero text berubah ke penerimaan
      expect(
        find.text(
          'Catat hasil penjualan ayam panen, afkir, atau sampingan secara transparan untuk memantau laba bersih.',
        ),
        findsOneWidget,
      );

      // Kategori berubah ke Penjualan
      expect(find.text('Penjualan Utama'), findsOneWidget);
      expect(find.text('Afkir / Reject'), findsOneWidget);
      expect(find.text('Pupuk / Kohe'), findsOneWidget);
      expect(find.text('Karung Bekas'), findsOneWidget);

      // Input rincian ayam muncul
      expect(find.text('Jumlah Ekor'), findsOneWidget);
      expect(find.text('Total Bobot (Kg)'), findsOneWidget);
    });

    testWidgets('dapat menambah nominal dengan Quick Add Chips', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Klik chip +100 rb
      await tester.tap(find.text('+100 rb'));
      await tester.pumpAndSettle();

      expect(find.text('100.000'), findsOneWidget);

      // Klik chip +50 rb -> total 150.000
      await tester.tap(find.text('+50 rb'));
      await tester.pumpAndSettle();

      expect(find.text('150.000'), findsOneWidget);
    });

    testWidgets('dapat memilih kategori manual kustom dan mengisinya', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Klik chip '+ Kategori Lain'
      await tester.tap(find.text('+ Kategori Lain'));
      await tester.pumpAndSettle();

      // Field kategori manual muncul
      expect(find.text('Nama Kategori Manual'), findsOneWidget);
      expect(find.text('Pilih Bawaan'), findsOneWidget);

      // Masukkan kategori manual
      await tester.enterText(
        find.widgetWithText(AppTextFormField, 'Nama Kategori Manual'),
        'Sewa Genset',
      );
      await tester.pumpAndSettle();

      expect(find.text('Sewa Genset'), findsOneWidget);
    });

    testWidgets('menghitung live preview harga per kg saat penjualan diisi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Beralih ke Pemasukan
      await tester.tap(find.text('Pemasukan (Kas Masuk)'));
      await tester.pumpAndSettle();

      // Masukkan nominal Rp 50.000.000
      await tester.enterText(
        find.widgetWithText(AppTextFormField, 'Nominal Kas (Rp)'),
        '50000000',
      );
      await tester.pumpAndSettle();

      // Masukkan jumlah 1.250 ekor dan bobot 2.500 kg
      await tester.enterText(
        find.widgetWithText(AppTextFormField, 'Jumlah Ekor'),
        '1250',
      );
      await tester.enterText(
        find.widgetWithText(AppTextFormField, 'Total Bobot (Kg)'),
        '2500',
      );
      await tester.pumpAndSettle();

      // Verifikasi live preview:
      // Harga per kg = 50.000.000 / 2.500 = Rp 20.000/kg
      // Rata-rata bobot = 2.500 / 1.250 = 2.00 kg/ekor
      expect(find.text('Rp 20.000/kg'), findsOneWidget);
      expect(find.text('2.00 kg/ekor'), findsOneWidget);
    });

    testWidgets('validasi gagal jika nominal transaksi kosong', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Klik tombol submit tanpa mengisi nominal
      await tester.ensureVisible(find.text('Simpan Transaksi Keuangan'));
      await tester.tap(find.text('Simpan Transaksi Keuangan'));
      await tester.pumpAndSettle();

      expect(find.text('Nominal transaksi wajib diisi'), findsOneWidget);
    });

    testWidgets('berhasil submit transaksi dan memanggil controller', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FinanceTransaction? savedTx;
      final mockCtrl = _MockFinanceController();

      await tester.pumpWidget(
        createWidgetUnderTest(
          onSave: (tx) => savedTx = tx,
          controller: mockCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Pilih kategori DOC
      await tester.tap(find.text('DOC (Bibit)'));
      await tester.pumpAndSettle();

      // Isi nominal Rp 15.000.000
      await tester.enterText(
        find.widgetWithText(AppTextFormField, 'Nominal Kas (Rp)'),
        '15000000',
      );
      await tester.pumpAndSettle();

      // Isi catatan
      await tester.enterText(
        find.widgetWithText(
          AppTextFormField,
          'Catatan / Nomor Nota (Opsional)',
        ),
        'Bibit Platinum 50 box',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Simpan Transaksi Keuangan'));
      await tester.tap(find.text('Simpan Transaksi Keuangan'));
      await tester.pumpAndSettle();

      expect(savedTx, isNotNull);
      expect(savedTx!.category, 'doc');
      expect(savedTx!.type, 'expense');
      expect(savedTx!.amount, 15000000);
      expect(savedTx!.notes, 'Bibit Platinum 50 box');
      expect(savedTx!.periodId, 'period-1');
    });

    testWidgets(
      'mendukung mode edit dengan existingTransaction dan memanggil updateTransaction',
      (tester) async {
        final ctrl = _MockFinanceController();
        final existingTx = FinanceTransaction(
          id: 'tx-existing-1',
          periodId: 'period-1',
          type: 'expense',
          category: 'pakan',
          amount: 2500000,
          date: DateTime(2026, 7, 5),
          notes: 'Nota feed no 123',
          createdAt: DateTime(2026, 7, 5),
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            controller: ctrl,
            existingTransaction: existingTx,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Transaksi (Batch 1 Test)'), findsOneWidget);
        expect(find.text('Simpan Perubahan'), findsOneWidget);
        expect(find.text('2.500.000'), findsOneWidget);
        expect(find.text('Nota feed no 123'), findsOneWidget);

        // Submit edit
        await tester.ensureVisible(find.text('Simpan Perubahan'));
        await tester.tap(find.text('Simpan Perubahan'));
        await tester.pumpAndSettle();

        expect(ctrl.lastUpdatedTransaction, isNotNull);
        expect(ctrl.lastUpdatedTransaction!.id, 'tx-existing-1');
        expect(ctrl.lastUpdatedTransaction!.amount, 2500000);
      },
    );
  });
}
