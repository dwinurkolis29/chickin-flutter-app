import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/components/empty/app_empty_state.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/recording/presentation/pages/chicken_weight_screen.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest({
    List<RecordingData>? recordings,
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
        home: ChickenWeightScreen(recordings: recordings),
      ),
    );
  }

  group('ChickenWeightScreen', () {
    testWidgets('menampilkan AppEmptyState jika list recording kosong', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(recordings: []));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum Ada Data Penimbangan'), findsOneWidget);
    });

    testWidgets('menampilkan metrik pertumbuhan dan kurva grafik jika ada data', (tester) async {
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
          day: 7,
          avgWeightGram: 180,
          feedSack: 2,
          mortality: 1,
          createdAt: DateTime(2026, 1, 7),
        ),
        RecordingData(
          id: 'rec_3',
          day: 14,
          avgWeightGram: 450,
          feedSack: 3,
          mortality: 0,
          createdAt: DateTime(2026, 1, 14),
        ),
      ];

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(recordings: sampleRecordings));
      await tester.pumpAndSettle();

      // Memastikan judul AppHeader tampil
      expect(find.text('Pertumbuhan Bobot Ayam'), findsOneWidget);

      // Memastikan kartu metrik ringkasan tampil
      expect(find.text('Bobot Terakhir'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);
      expect(find.text('Hari ke-14 (0.45 Kg)'), findsOneWidget);

      // Memastikan kartu grafik tampil
      expect(find.text('Kurva Pertumbuhan Bobot'), findsOneWidget);
      expect(find.text('Umur 1 s.d. 14 Hari (Satuan Gram)'), findsOneWidget);

      // Memastikan riwayat penimbangan harian tampil
      expect(find.text('RIWAYAT KENAIKAN BOBOT'), findsOneWidget);
      expect(find.text('3 Hari Catatan'), findsOneWidget);
      expect(find.text('HARI 14'), findsOneWidget);
      expect(find.text('HARI 7'), findsOneWidget);
      expect(find.text('HARI 1'), findsOneWidget);
      expect(find.text('Kenaikan Bobot'), findsWidgets);
      expect(find.text('Bobot Timbang'), findsWidgets);
    });
  });
}
