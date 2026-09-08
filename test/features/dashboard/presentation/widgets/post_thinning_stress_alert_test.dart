import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/post_thinning_stress_alert.dart';
import 'package:recording_app/features/period/data/models/harvest_record.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testHarvest = HarvestRecord(
    id: 'h-1',
    type: HarvestType.partial,
    date: DateTime.now(),
    day: 28,
    chicks: 50,
    weightKg: 700.0,
    createdAt: DateTime.now(),
  );

  Widget createWidgetUnderTest(HarvestRecord harvest) {
    return MaterialApp(
      theme: AppTheme.build(AppThemeOption.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PostThinningStressAlert(lastPartialHarvest: harvest),
          ),
        ),
      ),
    );
  }

  group('PostThinningStressAlert Widget Tests', () {
    testWidgets('bebas dari overflow pada layar standar iPhone (393px)', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(testHarvest));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pemulihan Pasca Penjarangan'), findsOneWidget);
      expect(find.text('Baru saja'), findsOneWidget);
      expect(find.textContaining('Dipanen 50 ekor (700.0 kg)'), findsOneWidget);
    });

    testWidgets('bebas dari overflow pada layar sempit (360px)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(testHarvest));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pemulihan Pasca Penjarangan'), findsOneWidget);
      expect(find.text('Baru saja'), findsOneWidget);
    });

    testWidgets('menampilkan panduan saat banner diklik/expanded', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(testHarvest));
      await tester.pumpAndSettle();

      // Klik untuk expand
      await tester.tap(find.text('Pemulihan Pasca Penjarangan'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PANDUAN MITIGASI RISIKO STRES & BIOSEKURITI:'), findsOneWidget);
      expect(find.text('Anti-Stres & Elektrolit'), findsOneWidget);
      expect(find.text('Pantau Konsumsi Pakan (*Feed Intake*)'), findsOneWidget);
      expect(find.text('Suhu & Ventilasi Kandang'), findsOneWidget);
      expect(find.text('Disinfeksi Pasca Panen'), findsOneWidget);
    });
  });
}
