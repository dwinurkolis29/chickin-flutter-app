import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  PeriodData? mockActivePeriod;
  List<RecordingData> mockRecordings = [];
  List<FlSpot> mockWeights = [];

  @override
  Future<PeriodData?> getActivePeriod([String? uid]) async => mockActivePeriod;

  @override
  Stream<List<RecordingData>> getRecordingsStream(
    String periodId, [
    String? uid,
  ]) => Stream.value(mockRecordings);

  @override
  Stream<List<FlSpot>> getWeightStream(String periodId, [String? uid]) =>
      Stream.value(mockWeights);
}

void main() {
  Widget createWidgetUnderTest({
    List<RecordingData>? recordings,
    bool readOnly = false,
    RecordingController? controller,
  }) {
    final defaultController =
        controller ??
        RecordingController(firebaseService: _FakeFirebaseService());

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecordingController>.value(
          value: defaultController,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: DetailRecording(recordings: recordings, readOnly: readOnly),
      ),
    );
  }

  group('DetailRecording Widget Tests', () {
    testWidgets('menampilkan AppEmptyState jika list recording kosong', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(recordings: []));
      await tester.pump();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum Ada Data Recording'), findsOneWidget);
    });

    testWidgets(
      'menampilkan daftar kartu recording harian dengan metrik yang jelas',
      (tester) async {
        final sampleRecordings = [
          RecordingData(
            id: 'rec_1',
            day: 1,
            avgWeightGram: 45,
            feedSack: 1,
            mortality: 0,
            createdAt: DateTime(2026, 1, 1),
          ),
          RecordingData(
            id: 'rec_2',
            day: 8,
            avgWeightGram: 220,
            feedSack: 2,
            mortality: 3,
            createdAt: DateTime(2026, 1, 8),
          ),
        ];

        await tester.pumpWidget(
          createWidgetUnderTest(recordings: sampleRecordings),
        );
        await tester.pump();

        // Header AppBar
        expect(find.text('Semua Recording'), findsOneWidget);

        // Search bar & Filter Chips
        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Minggu 1 (H1-7)'), findsOneWidget);
        expect(find.text('Minggu 2 (H8-14)'), findsOneWidget);

        // Kartu Hari 1 & Hari 8
        expect(find.text('Hari 1'), findsOneWidget);
        expect(find.text('Hari 8'), findsOneWidget);
        expect(find.text('Minggu ke-1'), findsOneWidget);
        expect(find.text('Minggu ke-2'), findsOneWidget);

        // Metrik
        expect(find.text('45 g'), findsOneWidget);
        expect(find.text('220 g'), findsOneWidget);
        expect(find.text('1 sak'), findsOneWidget);
        expect(find.text('2 sak'), findsOneWidget);
        expect(find.text('0 ekor'), findsOneWidget);
        expect(find.text('3 ekor'), findsOneWidget);

        // Tombol Edit
        expect(find.text('Edit'), findsNWidgets(2));
      },
    );

    testWidgets('dapat memfilter data berdasarkan search umur/hari', (
      tester,
    ) async {
      final sampleRecordings = [
        RecordingData(
          id: 'rec_1',
          day: 1,
          avgWeightGram: 45,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
        RecordingData(
          id: 'rec_2',
          day: 14,
          avgWeightGram: 450,
          feedSack: 3,
          mortality: 1,
          createdAt: DateTime(2026, 1, 14),
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(recordings: sampleRecordings),
      );
      await tester.pump();

      expect(find.text('Hari 1'), findsOneWidget);
      expect(find.text('Hari 14'), findsOneWidget);

      // Ketik 14 pada Search bar
      await tester.enterText(find.byType(TextField), '14');
      await tester.pump();

      expect(find.text('Hari 14'), findsOneWidget);
      expect(find.text('Hari 1'), findsNothing);
      expect(find.text('Menampilkan 1 dari 2 hari'), findsOneWidget);
    });

    testWidgets('dapat memfilter data berdasarkan filter chip Minggu', (
      tester,
    ) async {
      final sampleRecordings = [
        RecordingData(
          id: 'rec_1',
          day: 3,
          avgWeightGram: 70,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 3),
        ),
        RecordingData(
          id: 'rec_2',
          day: 10,
          avgWeightGram: 290,
          feedSack: 2,
          mortality: 2,
          createdAt: DateTime(2026, 1, 10),
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(recordings: sampleRecordings),
      );
      await tester.pump();

      // Pilih chip 'Minggu 1 (H1-7)'
      await tester.tap(find.text('Minggu 1 (H1-7)'));
      await tester.pump();

      expect(find.text('Hari 3'), findsOneWidget);
      expect(find.text('Hari 10'), findsNothing);

      // Pilih chip 'Ada Kematian'
      await tester.ensureVisible(find.text('Ada Kematian'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada Kematian'));
      await tester.pump();

      expect(find.text('Hari 10'), findsOneWidget);
      expect(find.text('Hari 3'), findsNothing);
    });

    testWidgets('dapat membuka bottom sheet edit saat tombol Edit ditekan', (
      tester,
    ) async {
      final sampleRecordings = [
        RecordingData(
          id: 'rec_1',
          day: 5,
          avgWeightGram: 120,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 5),
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(recordings: sampleRecordings),
      );
      await tester.pump();

      // Tap tombol Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Bottom sheet terbuka
      expect(find.text('Edit Recording'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Umur Ayam (Hari)'), findsOneWidget);
      expect(find.text('Pakan Terpakai (Sak)'), findsOneWidget);
    });

    testWidgets('tidak menampilkan tombol edit saat readOnly true', (
      tester,
    ) async {
      final sampleRecordings = [
        RecordingData(
          id: 'rec_1',
          day: 5,
          avgWeightGram: 120,
          feedSack: 1,
          mortality: 0,
          createdAt: DateTime(2026, 1, 5),
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(recordings: sampleRecordings, readOnly: true),
      );
      await tester.pump();

      expect(find.text('Laporan Recording'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Tambah Recording'), findsNothing);
    });

    testWidgets(
      'menampilkan floating action button Tambah Recording saat readOnly false',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(recordings: [], readOnly: false),
        );
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Tambah Recording'), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'menampilkan sub-card Feed Intake dan peringatan nafsu makan turun saat drop > 10%',
      (tester) async {
        // Pop default 1000 ekor
        // H1: pakan 2 sak (100kg = 100.000g) -> FI = 100 g/ekor/hari, Kumulatif = 100 g/ekor
        // H2: pakan 1.6 sak (80kg = 80.000g) -> FI = 80 g/ekor/hari (Turun 20% > 10%)
        final sampleRecordings = [
          RecordingData(
            id: 'rec_1',
            day: 1,
            avgWeightGram: 45,
            feedSack: 2,
            mortality: 0,
            createdAt: DateTime(2026, 1, 1),
          ),
          RecordingData(
            id: 'rec_2',
            day: 2,
            avgWeightGram: 60,
            feedSack: 1.6,
            mortality: 0,
            createdAt: DateTime(2026, 1, 2),
          ),
        ];

        await tester.pumpWidget(
          createWidgetUnderTest(recordings: sampleRecordings),
        );
        await tester.pump();

        // Label FI tampil pada kedua kartu
        expect(find.text('Konsumsi Pakan (FI)'), findsNWidgets(2));
        expect(find.byIcon(Icons.restaurant_rounded), findsNWidgets(2));

        // Peringatan nafsu makan turun terdeteksi pada hari ke-2 (-20%)
        expect(find.text('Nafsu makan turun (-20%)'), findsOneWidget);
        expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'menampilkan banner sekat seleksian dan strip info pada kartu harian jika sekat aktif',
      (tester) async {
        final sampleRecordings = [
          RecordingData(
            id: 'rec_1',
            day: 28,
            avgWeightGram: 1685,
            feedSack: 45,
            mortality: 5,
            createdAt: DateTime(2026, 1, 28),
          ),
        ];

        final testPeriod = PeriodData(
          id: 'p1',
          name: 'Periode 1',
          initialCapacity: 3000,
          initialWeight: 45,
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          isActive: true,
          summary: const PeriodSummary(
            hospitalPen: HospitalPenData(
              count: 150,
              avgWeightGram: 1206,
              day: 28,
              conditions: ['Kerdil'],
            ),
          ),
        );

        final fakeFirebase = _FakeFirebaseService()
          ..mockActivePeriod = testPeriod
          ..mockRecordings = sampleRecordings;

        final ctrl = RecordingController(firebaseService: fakeFirebase);
        await ctrl.loadActivePeriod();

        await tester.pumpWidget(
          createWidgetUnderTest(
            recordings: sampleRecordings,
            controller: ctrl,
          ),
        );
        await tester.pump();

        // 1. Icon sekat di AppBar
        expect(find.byIcon(Icons.fence_outlined), findsWidgets);

        // 2. Banner Sekat Seleksian di atas list
        expect(find.textContaining('Sekat: 150 ekor (1.206 g)'), findsOneWidget);

        // 3. Strip info sekat di dalam kartu hari ke-28
        expect(find.text('Sekat Seleksian'), findsOneWidget);
        expect(find.textContaining('Rata-rata riil:'), findsOneWidget);
      },
    );
  });
}
