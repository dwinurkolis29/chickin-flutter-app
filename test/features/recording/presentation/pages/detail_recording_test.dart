import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/recording/presentation/pages/detail_recording.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {}

void main() {
  Widget createWidgetUnderTest({
    List<RecordingData>? recordings,
    bool readOnly = false,
    RecordingController? controller,
  }) {
    final defaultController = controller ??
        RecordingController(
          firebaseService: _FakeFirebaseService(),
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecordingController>.value(
          value: defaultController,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: DetailRecording(
          recordings: recordings,
          readOnly: readOnly,
        ),
      ),
    );
  }

  group('DetailRecording Widget Tests', () {
    testWidgets('menampilkan AppEmptyState jika list recording kosong', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(recordings: []));
      await tester.pump();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum ada data recording'), findsOneWidget);
    });

    testWidgets('menampilkan daftar kartu recording harian dengan metrik yang jelas', (tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(recordings: sampleRecordings));
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
    });

    testWidgets('dapat memfilter data berdasarkan search umur/hari', (tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(recordings: sampleRecordings));
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

    testWidgets('dapat memfilter data berdasarkan filter chip Minggu', (tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(recordings: sampleRecordings));
      await tester.pump();

      // Pilih chip 'Minggu 1 (H1-7)'
      await tester.tap(find.text('Minggu 1 (H1-7)'));
      await tester.pump();

      expect(find.text('Hari 3'), findsOneWidget);
      expect(find.text('Hari 10'), findsNothing);

      // Pilih chip 'Ada Kematian ⚠️'
      await tester.ensureVisible(find.text('Ada Kematian ⚠️'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada Kematian ⚠️'));
      await tester.pump();

      expect(find.text('Hari 10'), findsOneWidget);
      expect(find.text('Hari 3'), findsNothing);
    });

    testWidgets('dapat membuka bottom sheet edit saat tombol Edit ditekan', (tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(recordings: sampleRecordings));
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

    testWidgets('tidak menampilkan tombol edit saat readOnly true', (tester) async {
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

      await tester.pumpWidget(createWidgetUnderTest(
        recordings: sampleRecordings,
        readOnly: true,
      ));
      await tester.pump();

      expect(find.text('Laporan Recording'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });
  });
}
