import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/period/data/models/hospital_pen_data.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/recording/presentation/pages/sekat_seleksian_screen.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {
  PeriodData? mockActivePeriod;
  List<RecordingData> mockRecordings = [];

  @override
  Future<PeriodData?> getActivePeriod([String? uid]) async => mockActivePeriod;

  @override
  Stream<List<RecordingData>> getRecordingsStream(
    String periodId, [
    String? uid,
  ]) => Stream.value(mockRecordings);

  @override
  Future<void> updateHospitalPen(
    String periodId,
    HospitalPenData? hospitalPen, [
    String? uid,
  ]) async {}
}

void main() {
  late _FakeFirebaseService fakeFirebaseService;
  late RecordingController controller;

  setUp(() {
    fakeFirebaseService = _FakeFirebaseService();
    controller = RecordingController(firebaseService: fakeFirebaseService);
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecordingController>.value(value: controller),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const SekatSeleksianScreen(),
      ),
    );
  }

  group('SekatSeleksianScreen Widget Tests', () {
    testWidgets('renders all form inputs and guidance card', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Header AppBar
      expect(find.text('Sekat Seleksian'), findsOneWidget);

      // Hero Guidance Card
      expect(find.text('Sub-Populasi Ayam Sekat'), findsOneWidget);
      expect(
        find.textContaining('tetap tergolong ayam hidup (Live Chicks)'),
        findsOneWidget,
      );

      // Form inputs
      expect(find.text('Hari ke- (Umur Ayam)'), findsOneWidget);
      expect(find.text('Jumlah Ayam di Sekat'), findsOneWidget);
      expect(find.text('Bobot Rata-rata Sekat'), findsOneWidget);
      expect(find.text('Gram'), findsOneWidget);
      expect(find.text('Kg'), findsOneWidget);
      expect(find.text('Kondisi / Alasan Pemisahan'), findsOneWidget);
      expect(find.text('Kerdil'), findsOneWidget);
      expect(find.text('Pincang / Kaki Lemah'), findsOneWidget);
      expect(find.text('Catatan Khusus (Opsional)'), findsOneWidget);

      // Save button
      expect(find.text('Simpan Status Sekat'), findsOneWidget);
    });

    testWidgets('displays live analysis card when count > 0', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Input count and weight
      final countField = find.widgetWithText(TextFormField, 'Jumlah Ayam di Sekat');
      final weightField = find.widgetWithText(TextFormField, 'Bobot Rata-rata Sekat');

      await tester.enterText(countField, '50');
      await tester.enterText(weightField, '1200');
      await tester.pump();

      // Analisis Sub-Populasi should now be rendered
      expect(find.text('Analisis Sub-Populasi'), findsOneWidget);
      expect(find.text('Proporsi Sekat'), findsOneWidget);
      expect(find.text('Gap Bobot'), findsOneWidget);
      expect(find.text('Rata-rata Riil'), findsOneWidget);
      expect(find.text('Biomassa Sekat'), findsOneWidget);
    });

    testWidgets('unit toggle converts value between Gram and Kg', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final weightField = find.widgetWithText(TextFormField, 'Bobot Rata-rata Sekat');
      await tester.enterText(weightField, '1500');
      await tester.pump();

      // Tap 'Kg' button
      await tester.tap(find.text('Kg'));
      await tester.pump();

      // Should now show 1.50 kg
      expect(find.text('1.50'), findsOneWidget);

      // Tap 'Gram' button
      await tester.tap(find.text('Gram'));
      await tester.pump();

      // Should now show 1500 g
      expect(find.text('1500'), findsOneWidget);
    });
  });
}
