import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/period/presentation/screens/partial_harvest_history_screen.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {}

class _MockPeriodController extends PeriodController {
  final List<PeriodData> _mockPeriods;
  String? deletedHarvestPeriodId;
  String? deletedHarvestId;

  _MockPeriodController({List<PeriodData>? periods})
    : _mockPeriods = periods ?? [],
      super(firebaseService: _FakeFirebaseService());

  @override
  List<PeriodData> get periods => _mockPeriods;

  @override
  Future<void> deletePartialHarvest(String periodId, String harvestId) async {
    deletedHarvestPeriodId = periodId;
    deletedHarvestId = harvestId;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget buildWidgetUnderTest({
    required PeriodData period,
    required PeriodController controller,
    int? currentLiveChicks,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PeriodController>.value(value: controller),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: PartialHarvestHistoryScreen(
          period: period,
          currentLiveChicks: currentLiveChicks,
        ),
      ),
    );
  }

  group('PartialHarvestHistoryScreen Widget Tests', () {
    testWidgets('menampilkan empty state jika belum ada panen parsial', (
      tester,
    ) async {
      final period = PeriodData(
        id: 'p-1',
        name: 'Batch Uji Empty',
        initialCapacity: 5000,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: true,
      );

      final controller = _MockPeriodController(periods: [period]);

      await tester.pumpWidget(
        buildWidgetUnderTest(period: period, controller: controller),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Panen Parsial'), findsOneWidget);
      expect(find.text('Belum Ada Panen Parsial'), findsOneWidget);
      expect(find.text('Catat Panen Parsial'), findsOneWidget);
    });

    testWidgets('menampilkan hero summary dan daftar kartu riwayat panen', (
      tester,
    ) async {
      final harvest1 = HarvestRecord(
        id: 'h-1',
        type: HarvestType.partial,
        date: DateTime(2026, 8, 25),
        day: 25,
        chicks: 1000,
        weightKg: 1300.0,
        avgWeightKg: 1.3,
        pricePerKg: 20000.0,
        totalRevenue: 26000000.0,
        notes: 'Bakul A',
        createdAt: DateTime(2026, 8, 25),
      );

      final harvest2 = HarvestRecord(
        id: 'h-2',
        type: HarvestType.partial,
        date: DateTime(2026, 8, 28),
        day: 28,
        chicks: 1500,
        weightKg: 2400.0,
        avgWeightKg: 1.6,
        pricePerKg: 21000.0,
        totalRevenue: 50400000.0,
        notes: 'Bakul B',
        createdAt: DateTime(2026, 8, 28),
      );

      final period = PeriodData(
        id: 'p-1',
        name: 'Batch Uji Riwayat',
        initialCapacity: 10000,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: true,
        summary: PeriodSummary(harvests: [harvest1, harvest2]),
      );

      final controller = _MockPeriodController(periods: [period]);

      tester.view.physicalSize = const Size(720, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildWidgetUnderTest(period: period, controller: controller),
      );
      await tester.pumpAndSettle();

      // Verifikasi Hero Summary
      expect(find.text('Total Panen Parsial'), findsOneWidget);
      expect(find.text('2 kali penjarangan dilakukan'), findsOneWidget);
      expect(find.text('2.500 ekor'), findsOneWidget); // 1000 + 1500
      expect(find.text('3.700 kg'), findsOneWidget); // 1300 + 2400

      // Verifikasi Daftar Riwayat
      expect(find.text('DAFTAR PENJARANGAN (2)'), findsOneWidget);
      expect(find.text('Umur 28 Hari'), findsOneWidget);
      expect(find.text('Umur 25 Hari'), findsOneWidget);
      expect(find.text('Bakul A'), findsOneWidget);
      expect(find.text('Bakul B'), findsOneWidget);

      // Verifikasi Tombol Tambah Panen Baru
      expect(find.text('Catat Panen Parsial Baru'), findsOneWidget);
    });

    testWidgets('pada periode selesai/tertutup, tombol aksi hapus disembunyikan', (
      tester,
    ) async {
      final harvest = HarvestRecord(
        id: 'h-1',
        type: HarvestType.partial,
        date: DateTime(2026, 8, 25),
        day: 25,
        chicks: 1000,
        weightKg: 1300.0,
        avgWeightKg: 1.3,
        createdAt: DateTime(2026, 8, 25),
      );

      final closedPeriod = PeriodData(
        id: 'p-closed',
        name: 'Batch Masa Lalu',
        initialCapacity: 5000,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 8, 1),
        isActive: false,
        summary: PeriodSummary(harvests: [harvest]),
      );

      final controller = _MockPeriodController(periods: [closedPeriod]);

      await tester.pumpWidget(
        buildWidgetUnderTest(period: closedPeriod, controller: controller),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terkunci (Selesai)'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.text('Catat Panen Parsial Baru'), findsNothing);
    });

    testWidgets('menekan tombol hapus memicu dialog konfirmasi', (
      tester,
    ) async {
      final harvest = HarvestRecord(
        id: 'h-del',
        type: HarvestType.partial,
        date: DateTime(2026, 8, 25),
        day: 25,
        chicks: 1000,
        weightKg: 1300.0,
        avgWeightKg: 1.3,
        createdAt: DateTime(2026, 8, 25),
      );

      final activePeriod = PeriodData(
        id: 'p-active',
        name: 'Batch Uji Delete',
        initialCapacity: 5000,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: true,
        summary: PeriodSummary(harvests: [harvest]),
      );

      final controller = _MockPeriodController(periods: [activePeriod]);

      await tester.pumpWidget(
        buildWidgetUnderTest(period: activePeriod, controller: controller),
      );
      await tester.pumpAndSettle();

      // Klik tombol delete
      final deleteBtn = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verifikasi dialog konfirmasi muncul
      expect(find.text('Hapus Panen Parsial'), findsOneWidget);
      expect(find.text('Hapus Catatan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Konfirmasi hapus
      await tester.tap(find.text('Hapus Catatan'));
      await tester.pumpAndSettle();

      expect(controller.deletedHarvestPeriodId, 'p-active');
      expect(controller.deletedHarvestId, 'h-del');
    });
  });
}
