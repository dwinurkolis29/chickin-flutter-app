import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/reporting/presentation/pages/fcr_monitoring_screen.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {}

class _MockHomeController extends HomeController {
  final String? _mockActivePeriodId;
  final String? _mockActivePeriodName;
  final int _mockInitialPopulation;
  final List<RecordingData>? _mockCachedRecordings;
  final Stream<List<RecordingData>>? _mockRecordingsStream;
  final bool _mockIsLoadingPeriod;

  _MockHomeController({
    String? activePeriodId,
    String? activePeriodName,
    int initialPopulation = 1000,
    List<RecordingData>? cachedRecordings,
    Stream<List<RecordingData>>? recordingsStream,
    bool isLoadingPeriod = false,
  })  : _mockActivePeriodId = activePeriodId,
        _mockActivePeriodName = activePeriodName,
        _mockInitialPopulation = initialPopulation,
        _mockCachedRecordings = cachedRecordings,
        _mockRecordingsStream = recordingsStream,
        _mockIsLoadingPeriod = isLoadingPeriod,
        super(firebaseService: _FakeFirebaseService());

  @override
  String? get activePeriodId => _mockActivePeriodId;

  @override
  String? get activePeriodName => _mockActivePeriodName;

  @override
  int get initialPopulation => _mockInitialPopulation;

  @override
  List<RecordingData>? get cachedRecordings => _mockCachedRecordings;

  @override
  Stream<List<RecordingData>>? get recordingsStream =>
      _mockRecordingsStream ??
      (_mockCachedRecordings != null
          ? Stream.value(_mockCachedRecordings)
          : null);

  @override
  bool get isLoadingPeriod => _mockIsLoadingPeriod;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest(HomeController controller) {
    return ChangeNotifierProvider<HomeController>.value(
      value: controller,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const FCRMonitoringScreen(),
      ),
    );
  }

  group('FCRMonitoringScreen Widget Tests', () {
    testWidgets('menampilkan empty state jika belum ada periode aktif', (tester) async {
      final ctrl = _MockHomeController(activePeriodId: null);

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Monitoring FCR'), findsOneWidget);
      expect(find.text('Tidak Ada Periode Aktif'), findsOneWidget);
    });

    testWidgets('menampilkan empty state jika recordings kosong', (tester) async {
      final ctrl = _MockHomeController(
        activePeriodId: 'period-1',
        activePeriodName: 'Flok Broiler 1',
        cachedRecordings: [],
      );

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Data Recording'), findsOneWidget);
    });

    testWidgets('menampilkan hero summary card dan tab harian secara default', (tester) async {
      final recordings = [
        RecordingData(
          day: 1,
          avgWeightGram: 180,
          feedSack: 1,
          mortality: 2,
          createdAt: DateTime(2026, 8, 1),
        ),
        RecordingData(
          day: 2,
          avgWeightGram: 240,
          feedSack: 1,
          mortality: 1,
          createdAt: DateTime(2026, 8, 2),
        ),
      ];

      final ctrl = _MockHomeController(
        activePeriodId: 'period-1',
        activePeriodName: 'Flok Broiler 1',
        initialPopulation: 1000,
        cachedRecordings: recordings,
      );

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      // Header & Periode
      expect(find.text('Monitoring FCR'), findsOneWidget);
      expect(find.text('Flok Broiler 1'), findsOneWidget);
      expect(find.text('Umur 2 Hari • Akumulasi Saat Ini'), findsOneWidget);

      // Hero metrics
      expect(find.text('Nilai FCR Kumulatif'), findsOneWidget);
      expect(find.text('Total Pakan'), findsOneWidget);
      expect(find.text('Total Bobot'), findsOneWidget);
      expect(find.text('Sisa Ayam'), findsOneWidget);

      // Tab switcher
      expect(find.text('1. FCR Harian'), findsOneWidget);
      expect(find.text('2. FCR Mingguan'), findsOneWidget);

      // Daily list content
      await tester.ensureVisible(find.text('Hari ke-2'));
      await tester.pumpAndSettle();
      expect(find.text('Hari ke-2'), findsOneWidget);

      await tester.ensureVisible(find.text('Hari ke-1'));
      await tester.pumpAndSettle();
      expect(find.text('Hari ke-1'), findsOneWidget);
    });

    testWidgets('beralih ke tab mingguan saat tab 2 diklik', (tester) async {
      final recordings = [
        RecordingData(
          day: 7,
          avgWeightGram: 500,
          feedSack: 5,
          mortality: 5,
          createdAt: DateTime(2026, 8, 7),
        ),
      ];

      final ctrl = _MockHomeController(
        activePeriodId: 'period-1',
        activePeriodName: 'Flok Broiler 1',
        initialPopulation: 1000,
        cachedRecordings: recordings,
      );

      await tester.pumpWidget(createWidgetUnderTest(ctrl));
      await tester.pumpAndSettle();

      // Tap tab FCR Mingguan
      await tester.tap(find.text('2. FCR Mingguan'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('RIWAYAT FCR PER MINGGU'));
      await tester.pumpAndSettle();
      expect(find.text('RIWAYAT FCR PER MINGGU'), findsOneWidget);

      await tester.ensureVisible(find.text('Minggu 1'));
      await tester.pumpAndSettle();
      expect(find.text('Minggu 1'), findsOneWidget);
      expect(find.text('Umur 1 - 7 Hari'), findsOneWidget);
    });
  });
}
