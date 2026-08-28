import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reporting/domain/usecases/generate_period_report.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'package:recording_app/features/reporting/presentation/pages/period_report_page.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  @override
  Stream<List<PeriodData>> getPeriodsStream([String? uid]) {
    return Stream.value([]);
  }
}

class _MockReportingController extends ReportingController {
  final List<PeriodData> _mockClosedPeriods;
  final PeriodReport? _mockReport;
  final bool _mockLoading;
  final String? _mockError;
  bool exportExcelCalled = false;

  _MockReportingController({
    List<PeriodData>? closedPeriods,
    PeriodReport? report,
    bool isLoading = false,
    String? errorMessage,
  })  : _mockClosedPeriods = closedPeriods ?? [],
        _mockReport = report,
        _mockLoading = isLoading,
        _mockError = errorMessage,
        super(firebaseService: _FakeFirebaseService());

  @override
  List<PeriodData> get closedPeriods => _mockClosedPeriods;

  @override
  PeriodReport? get report => _mockReport;

  @override
  bool get isLoading => _mockLoading;

  @override
  bool get isLoadingRecordings => false;

  @override
  String? get errorMessage => _mockError;

  @override
  String? get selectedPeriodId => _mockClosedPeriods.isNotEmpty ? _mockClosedPeriods.first.id : null;

  @override
  Future<void> exportExcel({required void Function(String) onError}) async {
    exportExcelCalled = true;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createTestWidget(ReportingController controller, {bool isTab = false}) {
    return ChangeNotifierProvider<ReportingController>.value(
      value: controller,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: PeriodReportPage(isTab: isTab),
      ),
    );
  }

  group('PeriodReportPage Widget Tests', () {
    testWidgets('menampilkan empty state jika belum ada periode yang selesai dipanen', (tester) async {
      final ctrl = _MockReportingController(closedPeriods: []);

      await tester.pumpWidget(createTestWidget(ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Periode Panen'), findsOneWidget);
    });

    testWidgets('menampilkan error state saat terjadi kegagalan muat data', (tester) async {
      final ctrl = _MockReportingController(
        closedPeriods: [
          PeriodData(
            id: 'p1',
            name: 'Batch 1',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 2, 5),
            createdAt: DateTime(2026, 1, 1),
            isActive: false,
          ),
        ],
        errorMessage: 'Koneksi jaringan terputus',
      );

      await tester.pumpWidget(createTestWidget(ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat data laporan'), findsOneWidget);
      expect(find.text('Koneksi jaringan terputus'), findsOneWidget);
    });

    testWidgets('menampilkan kesimpulan laporan panen, hero IP, 4 indikator utama, dan saran', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final closedPeriod = PeriodData(
        id: 'p1',
        name: 'Periode Batch Panen 1',
        initialCapacity: 10000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 5),
        createdAt: DateTime(2026, 1, 1),
        isActive: false,
        summary: const PeriodSummary(
          totalFeedKg: 28000,
          finalPopulation: 9700,
          totalMortality: 300,
          finalBiomass: 17460,
          finalFCR: 1.60,
          avgDailyGain: 50.0,
          harvestedChicks: 9700,
          harvestedWeightKg: 17460,
          avgHarvestWeightKg: 1.80,
          ipScore: 311,
          insights: [
            'FCR sangat baik (1.60) — efisiensi pakan optimal',
            'Mortalitas rendah (3.0%) — manajemen kesehatan baik',
          ],
        ),
      );

      final mockReport = PeriodReport(
        period: closedPeriod,
        recordings: const [],
        initialPopulation: 10000,
        totalMortality: 300,
        finalPopulation: 9700,
        mortalityRate: 3.0,
        totalFeedKg: 28000,
        finalAvgWeightGram: 1800,
        totalBiomassKg: 17460,
        weightGainKg: 17060,
        fcr: 1.60,
        avgDailyGainGram: 50.0,
        feedPerBird: 2.89,
        survivalRate: 97.0,
        durationDays: 35,
        harvestedChicks: 9700,
        harvestedWeightKg: 17460,
        avgHarvestWeightKg: 1.80,
        ipScore: 311,
      );

      final ctrl = _MockReportingController(
        closedPeriods: [closedPeriod],
        report: mockReport,
      );

      await tester.pumpWidget(createTestWidget(ctrl));
      await tester.pumpAndSettle();

      // 1. Verifikasi Hero Section & Indeks Performa (IP)
      expect(find.text('Periode Batch Panen 1'), findsOneWidget);
      expect(find.text('Indeks Performa (IP)'), findsOneWidget);
      expect(find.text('311'), findsOneWidget);
      expect(find.text('Baik / Standar'), findsOneWidget);

      // 2. Verifikasi 4 Indikator Utama (tanpa header 'Indikator Utama Panen')
      expect(find.text('Indikator Utama Panen'), findsNothing);
      expect(find.text('FCR Panen'), findsWidgets);
      expect(find.text('Daya Hidup'), findsWidgets);
      expect(find.text('Ayam Dipanen'), findsOneWidget);
      expect(find.text('Rata-rata Bobot'), findsWidgets);
      expect(find.text('9.700 ekor'), findsOneWidget);
      expect(find.text('1.80 kg'), findsWidgets);

      // 3. Verifikasi Kesimpulan & Saran Periode Berikutnya
      expect(find.text('Kesimpulan & Saran Periode Berikutnya'), findsOneWidget);
      expect(find.textContaining('FCR sangat baik (1.60)'), findsOneWidget);

      // 4. Verifikasi Ringkasan Data Produksi
      expect(find.text('Ringkasan Data Produksi'), findsOneWidget);
      expect(find.text('Total Pakan Dikonsumsi'), findsOneWidget);
      expect(find.text('28.000 kg'), findsOneWidget);
      expect(find.text('Total Bobot Daging Panen'), findsOneWidget);
      expect(find.text('17.460 kg'), findsOneWidget);
    });

    testWidgets('tombol quick export Excel memanggil controller export dan CSV tidak tampil', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final closedPeriod = PeriodData(
        id: 'p1',
        name: 'Batch Export Test',
        initialCapacity: 5000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 5),
        createdAt: DateTime(2026, 1, 1),
        isActive: false,
      );

      final mockReport = PeriodReport(
        period: closedPeriod,
        recordings: const [],
        initialPopulation: 5000,
        totalMortality: 150,
        finalPopulation: 4850,
        mortalityRate: 3.0,
        totalFeedKg: 14000,
        finalAvgWeightGram: 1800,
        totalBiomassKg: 8730,
        weightGainKg: 8530,
        fcr: 1.60,
        avgDailyGainGram: 50.0,
        feedPerBird: 2.89,
        survivalRate: 97.0,
        durationDays: 35,
      );

      final ctrl = _MockReportingController(
        closedPeriods: [closedPeriod],
        report: mockReport,
      );

      await tester.pumpWidget(createTestWidget(ctrl));
      await tester.pumpAndSettle();

      // Tap Excel export icon
      final excelBtn = find.byIcon(Icons.table_chart_outlined);
      expect(excelBtn, findsOneWidget);
      await tester.tap(excelBtn);
      await tester.pumpAndSettle();
      expect(ctrl.exportExcelCalled, isTrue);

      // CSV export icon must NOT be present
      final csvBtn = find.byIcon(Icons.description_outlined);
      expect(csvBtn, findsNothing);
    });
  });
}
