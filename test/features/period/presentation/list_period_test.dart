import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/period/presentation/list_period.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  @override
  Stream<List<PeriodData>> getPeriodsStream([String? uid]) {
    return Stream.value([]);
  }
}

class _FakeReportingController extends ReportingController {
  _FakeReportingController() : super(firebaseService: _FakeFirebaseService());
}

class _MockPeriodController extends PeriodController {
  final List<PeriodData> _mockPeriods;
  final bool _mockIsLoading;
  final String? _mockError;

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
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest(PeriodController periodController) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PeriodController>.value(value: periodController),
        ChangeNotifierProvider<ReportingController>(
          create: (_) => _FakeReportingController(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const PeriodListScreen(),
      ),
    );
  }

  group('PeriodListScreen Widget Tests', () {
    testWidgets('menampilkan ajakan buat siklus saat tidak ada periode aktif', (tester) async {
      final ctrl = _MockPeriodController(periods: []);

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Periode Pemeliharaan'), findsOneWidget);
      expect(find.text('Belum Ada Siklus Aktif'), findsOneWidget);
      expect(find.text('Mulai Siklus Baru'), findsOneWidget);
      expect(find.text('Buat Periode Baru'), findsOneWidget);
    });

    testWidgets('menampilkan kartu periode aktif dan riwayat periode', (tester) async {
      final activePeriod = PeriodData(
        id: 'p-1',
        name: 'Batch Broiler 1',
        initialCapacity: 5000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: true,
      );

      final closedPeriod = PeriodData(
        id: 'p-2',
        name: 'Batch Broiler Lama',
        initialCapacity: 4500,
        initialWeight: 0.04,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 10),
        createdAt: DateTime(2026, 6, 1),
        isActive: false,
      );

      final ctrl = _MockPeriodController(periods: [activePeriod, closedPeriod]);

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      // Active card
      expect(find.text('PERIODE SEDANG AKTIF'), findsOneWidget);
      expect(find.text('Batch Broiler 1'), findsWidgets);
      expect(find.text('Berjalan'), findsWidgets);
      expect(find.text('Kelola Siklus'), findsOneWidget);
      expect(find.text('Tutup Panen'), findsOneWidget);

      // Section history
      expect(find.text('RIWAYAT SEMUA PERIODE'), findsOneWidget);
      expect(find.text('Semua (2)'), findsOneWidget);
      expect(find.text('Aktif (1)'), findsOneWidget);
      expect(find.text('Selesai Panen (1)'), findsOneWidget);
      expect(find.text('Batch Broiler Lama'), findsOneWidget);
    });

    testWidgets('filter chips menyaring riwayat periode dengan benar', (tester) async {
      final activePeriod = PeriodData(
        id: 'p-1',
        name: 'Batch Broiler 1',
        initialCapacity: 5000,
        initialWeight: 0.04,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
        isActive: true,
      );

      final closedPeriod = PeriodData(
        id: 'p-2',
        name: 'Batch Broiler Selesai',
        initialCapacity: 4500,
        initialWeight: 0.04,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 10),
        createdAt: DateTime(2026, 6, 1),
        isActive: false,
      );

      final ctrl = _MockPeriodController(periods: [activePeriod, closedPeriod]);

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      // Tap filter Selesai Panen (1)
      await tester.tap(find.text('Selesai Panen (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Batch Broiler Selesai'), findsOneWidget);
    });
  });
}
