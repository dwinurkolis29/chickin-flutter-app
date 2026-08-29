import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/period/presentation/screens/form_period.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {}

class _MockPeriodController extends PeriodController {
  final List<PeriodData> _mockPeriods;
  final bool _mockIsLoading;
  final String? _mockError;
  PeriodData? lastCreatedPeriod;
  PeriodData? lastUpdatedPeriod;
  String? lastActivatedPeriodId;
  String? lastClosedPeriodId;
  String? lastDeletedPeriodId;

  _MockPeriodController({
    List<PeriodData>? periods,
    bool isLoading = false,
    String? errorMessage,
  })  : _mockPeriods = periods ?? [],
        _mockIsLoading = isLoading,
        _mockError = errorMessage,
        super(firebaseService: _FakeFirebaseService());

  @override
  List<PeriodData> get periods => _mockPeriods;

  @override
  bool get isLoading => _mockIsLoading;

  @override
  String? get errorMessage => _mockError;

  @override
  Future<void> createPeriod(PeriodData period) async {
    lastCreatedPeriod = period;
  }

  @override
  Future<void> updatePeriodDetails(String periodId, PeriodData updatedData) async {
    lastUpdatedPeriod = updatedData;
  }

  @override
  Future<void> activatePeriod(String periodId) async {
    lastActivatedPeriodId = periodId;
  }

  @override
  Future<void> closePeriod(
    String periodId, {
    int? harvestedChicks,
    double? harvestedWeightKg,
  }) async {
    lastClosedPeriodId = periodId;
  }

  @override
  Future<void> deletePeriod(String periodId) async {
    lastDeletedPeriodId = periodId;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest({
    required PeriodController controller,
    PeriodData? period,
  }) {
    return ChangeNotifierProvider<PeriodController>.value(
      value: controller,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: FormPeriod(period: period),
      ),
    );
  }

  group('FormPeriod Widget Tests', () {
    testWidgets('menampilkan form buat periode baru dengan nilai default yang benar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final ctrl = _MockPeriodController();

      await tester.pumpWidget(createWidgetUnderTest(controller: ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Buat Periode Baru'), findsWidgets);
      expect(find.text('INFORMASI SIKLUS DOC'), findsOneWidget);
      expect(find.text('Nama Periode / Siklus'), findsOneWidget);
      expect(find.text('Tanggal DOC Masuk'), findsOneWidget);
      expect(find.text('Jumlah DOC / Populasi Awal (Ekor)'), findsOneWidget);
      expect(find.text('Bobot Awal DOC (Kg)'), findsNothing);
    });

    testWidgets('validasi gagal jika field wajib kosong', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final ctrl = _MockPeriodController();

      await tester.pumpWidget(createWidgetUnderTest(controller: ctrl));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Nama periode wajib diisi'), findsOneWidget);
      expect(find.text('Jumlah DOC wajib diisi'), findsOneWidget);
      expect(ctrl.lastCreatedPeriod, isNull);
    });

    testWidgets('berhasil submit buat periode baru saat diisi dengan benar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final ctrl = _MockPeriodController();

      await tester.pumpWidget(createWidgetUnderTest(controller: ctrl));
      await tester.pumpAndSettle();

      // Isi form: Nama & Kapasitas DOC
      await tester.enterText(find.byType(TextFormField).at(0), 'Batch 1 2026');
      await tester.enterText(find.byType(TextFormField).at(1), '5000');
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(ctrl.lastCreatedPeriod, isNotNull);
      expect(ctrl.lastCreatedPeriod!.name, 'Batch 1 2026');
      expect(ctrl.lastCreatedPeriod!.initialCapacity, 5000);
      expect(ctrl.lastCreatedPeriod!.initialWeight, 0.04);
    });

    testWidgets('menampilkan mode edit dan opsi tutup panen saat periode aktif diedit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activePeriod = PeriodData(
        id: 'period-active',
        name: 'Siklus Aktif 1',
        initialCapacity: 4000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: true,
      );

      final ctrl = _MockPeriodController(periods: [activePeriod]);

      await tester.pumpWidget(createWidgetUnderTest(
        controller: ctrl,
        period: activePeriod,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Periode'), findsOneWidget);
      expect(find.text('Periode Ini Sedang Aktif'), findsOneWidget);
      expect(find.text('Tutup Siklus (Selesai Panen)'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      // Tombol hapus DILARANG muncul pada periode aktif
      expect(find.text('Hapus Periode Draft'), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });

    testWidgets('menampilkan tombol hapus periode draft di bawah simpan dan menampilkan konfirmasi saat ditekan', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draftPeriod = PeriodData(
        id: 'period-draft',
        name: 'Siklus Draft 2',
        initialCapacity: 3000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: false,
      );

      final ctrl = _MockPeriodController(periods: [draftPeriod]);

      await tester.pumpWidget(createWidgetUnderTest(
        controller: ctrl,
        period: draftPeriod,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Periode'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Hapus Periode Draft'), findsOneWidget);

      // Tap Hapus Periode Draft
      await tester.tap(find.text('Hapus Periode Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Periode Draft'), findsWidgets);
      expect(find.textContaining('Apakah Anda yakin ingin menghapus periode draft "Siklus Draft 2"?'), findsOneWidget);
      expect(find.text('Ya, Hapus'), findsOneWidget);
    });

    testWidgets('sembunyikan tombol aktifkan periode jika masih ada periode lain yang aktif', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activePeriod = PeriodData(
        id: 'period-active',
        name: 'Siklus Aktif 1',
        initialCapacity: 4000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: true,
      );

      final draftPeriod = PeriodData(
        id: 'period-draft',
        name: 'Siklus Draft 2',
        initialCapacity: 3000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: false,
      );

      final ctrl = _MockPeriodController(periods: [activePeriod, draftPeriod]);

      await tester.pumpWidget(createWidgetUnderTest(
        controller: ctrl,
        period: draftPeriod,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tidak dapat mengaktifkan periode ini karena masih ada siklus pemeliharaan yang sedang aktif. Selesaikan panen pada periode aktif terlebih dahulu.'), findsOneWidget);
      expect(find.text('Aktifkan Periode Ini Sekarang'), findsNothing);
    });

    testWidgets('tampilkan tombol aktifkan periode jika tidak ada periode lain yang aktif', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draftPeriod = PeriodData(
        id: 'period-draft',
        name: 'Siklus Draft 2',
        initialCapacity: 3000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: false,
      );

      final ctrl = _MockPeriodController(periods: [draftPeriod]);

      await tester.pumpWidget(createWidgetUnderTest(
        controller: ctrl,
        period: draftPeriod,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Periode Ini Sekarang'), findsOneWidget);
    });
  });
}
