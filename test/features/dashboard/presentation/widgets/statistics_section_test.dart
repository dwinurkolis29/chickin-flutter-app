import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/statistics_section.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/recording/presentation/pages/chicken_weight_screen.dart';
import 'package:recording_app/features/reporting/presentation/pages/fcr_monitoring_screen.dart';

class _FakeFirebaseService extends Fake implements FirebaseService {}

class _MockHomeController extends HomeController {
  _MockHomeController() : super(firebaseService: _FakeFirebaseService());

  @override
  String? get activePeriodId => 'period-1';

  @override
  String? get activePeriodName => 'Batch 1';

  @override
  int get initialPopulation => 5000;
}

class _MockRecordingController extends RecordingController {
  _MockRecordingController() : super(firebaseService: _FakeFirebaseService());

  @override
  bool get isLoadingPeriod => false;

  @override
  Stream<List<RecordingData>> get recordingsStream => Stream.value([]);

  @override
  Future<void> loadActivePeriod([String? uid]) async {}
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeController>.value(
          value: _MockHomeController(),
        ),
        ChangeNotifierProvider<RecordingController>.value(
          value: _MockRecordingController(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: Scaffold(body: child),
      ),
    );
  }

  group('StatisticsSection Widget Tests', () {
    testWidgets('menampilkan nilai Umur Ayam dan FCR dengan benar', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const StatisticsSection(
            fcr: 1.45,
            umur: 21,
            weightStream: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('21'), findsOneWidget);
      expect(find.text('Umur\nAyam'), findsOneWidget);

      expect(find.text('1.45'), findsOneWidget);
      expect(find.text('FCR'), findsOneWidget);
    });

    testWidgets('mengetuk kartu FCR membuka FCRMonitoringScreen', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const StatisticsSection(
            fcr: 1.45,
            umur: 21,
            weightStream: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('FCR'));
      await tester.pumpAndSettle();

      expect(find.byType(FCRMonitoringScreen), findsOneWidget);
    });

    testWidgets('kartu Umur Ayam tidak membuka layar baru saat diketuk (non-navigable)', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const StatisticsSection(
            fcr: 1.45,
            umur: 21,
            weightStream: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Umur\nAyam'));
      await tester.pumpAndSettle();

      expect(find.byType(ChickenWeightScreen), findsNothing);
    });
  });
}
