import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/dashboard/presentation/dashboard.dart';
import 'package:recording_app/features/finance/presentation/controllers/finance_controller.dart';
import 'package:recording_app/features/finance/presentation/pages/finance_list_screen.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/recording/presentation/pages/chicken_weight_screen.dart';
import 'package:recording_app/features/recording/presentation/pages/sekat_seleksian_screen.dart';
import 'package:recording_app/features/reporting/presentation/pages/fcr_monitoring_screen.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/user/presentation/pages/quick_calculator_screen.dart';

import 'package:firebase_auth/firebase_auth.dart' as fb;

class _FakeFirebaseService extends Fake implements FirebaseService {}

class _FakeUser extends Fake implements fb.User {
  @override
  final String displayName;
  @override
  final String email;
  @override
  final String? photoURL;

  _FakeUser({required this.displayName, required this.email}) : photoURL = null;
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  final fb.User? _user;

  _FakeAuthService({fb.User? user})
      : _user = user ?? _FakeUser(displayName: 'Peternak', email: 'test@chickin.id');

  @override
  fb.User? get currentUser => _user;

  @override
  bool get isLoggedIn => true;

  @override
  bool get isInitialized => true;

  @override
  String? get currentUid => 'test-uid';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserController extends ChangeNotifier implements UserController {
  @override
  UserProfile? get userProfile => const UserProfile(name: 'Peternak Broiler');

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHomeController extends HomeController {
  final PeriodData _period;

  _MockHomeController({
    required PeriodData period,
  })  : _period = period,
        super(firebaseService: _FakeFirebaseService());

  @override
  PeriodData? get activePeriod => _period;

  @override
  String? get activePeriodId => _period.id;

  @override
  String? get activePeriodName => _period.name;

  @override
  bool get isLoadingPeriod => false;

  @override
  int get initialPopulation => _period.initialCapacity;

  @override
  Stream<List<RecordingData>>? get recordingsStream =>
      Stream<List<RecordingData>>.value(<RecordingData>[]).asBroadcastStream();

  @override
  Future<void> loadActivePeriod([String? uid]) async {}
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

class _MockFinanceController extends FinanceController {
  _MockFinanceController() : super(firebaseService: _FakeFirebaseService());

  @override
  bool get isLoading => false;

  @override
  void setPeriod(PeriodData? period) {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testPeriod = PeriodData(
    id: 'period-123',
    name: 'Kandang 1 - Siklus 2',
    initialCapacity: 3000,
    startDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    isActive: true,
  );

  Widget createWidgetUnderTest({HomeController? homeController}) {
    final homeCtrl =
        homeController ?? _MockHomeController(period: testPeriod);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => _FakeAuthService()),
        ChangeNotifierProvider<UserController>(
          create: (_) => _FakeUserController(),
        ),
        ChangeNotifierProvider<HomeController>.value(value: homeCtrl),
        ChangeNotifierProvider<RecordingController>.value(
          value: _MockRecordingController(),
        ),
        ChangeNotifierProvider<FinanceController>.value(
          value: _MockFinanceController(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const Scaffold(body: DashboardContent()),
      ),
    );
  }

  group('Dashboard Quick Actions Row Tests', () {
    testWidgets(
      'menampilkan 5 button cepat dalam satu baris yang dapat digeser horizontal (Pencatatan Keuangan, Sekat Seleksian, Monitor FCR, Pertumbuhan Bobot, Kalkulator Cepat)',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Button Pencatatan Keuangan di sisi kiri
        expect(find.text('Pencatatan\nKeuangan'), findsOneWidget);
        expect(find.text('Biaya & panen'), findsOneWidget);
        expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);

        // 4 Action cards di sisi kanan
        expect(find.text('Sekat\nSeleksian'), findsOneWidget);
        expect(find.text('Monitor\nFCR'), findsOneWidget);
        expect(find.text('Pertumbuhan\nBobot'), findsOneWidget);
        expect(find.text('Kalkulator\nCepat'), findsOneWidget);

        // Icon untuk masing-masing aksi cepat
        expect(find.byIcon(Icons.fence_outlined), findsOneWidget);
        expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
        expect(find.byIcon(Icons.show_chart_rounded), findsOneWidget);
        expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
      },
    );

    testWidgets('memungkinkan scroll horizontal (kanan & kiri) pada daftar button cepat', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Cari scroll view horizontal pada quick actions
      final horizontalScrollView = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScrollView, findsOneWidget);

      // Geser ke kiri (drag ke arah kiri)
      await tester.drag(horizontalScrollView, const Offset(-80, 0));
      await tester.pumpAndSettle();

      // Geser balik ke kanan (drag ke arah kanan)
      await tester.drag(horizontalScrollView, const Offset(80, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('navigasi ke FinanceListScreen saat tombol Pencatatan Keuangan ditekan', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pencatatan\nKeuangan'));
      await tester.pumpAndSettle();

      expect(find.byType(FinanceListScreen), findsOneWidget);
    });

    testWidgets('navigasi ke SekatSeleksianScreen saat tombol Sekat Seleksian ditekan', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sekat\nSeleksian'));
      await tester.pumpAndSettle();

      expect(find.byType(SekatSeleksianScreen), findsOneWidget);
    });

    testWidgets('navigasi ke FCRMonitoringScreen saat tombol Monitor FCR ditekan', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monitor\nFCR'));
      await tester.pumpAndSettle();

      expect(find.byType(FCRMonitoringScreen), findsOneWidget);
    });

    testWidgets(
      'navigasi ke ChickenWeightScreen saat tombol Pertumbuhan Bobot ditekan',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pertumbuhan\nBobot'));
        await tester.pumpAndSettle();

        expect(find.byType(ChickenWeightScreen), findsOneWidget);
      },
    );

    testWidgets('navigasi ke QuickCalculatorScreen saat tombol Kalkulator Cepat ditekan', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Scroll horizontal jika perlu untuk memastikan item terlihat
      final horizontalScrollView = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      await tester.drag(horizontalScrollView, const Offset(-100, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kalkulator\nCepat'));
      await tester.pumpAndSettle();

      expect(find.byType(QuickCalculatorScreen), findsOneWidget);
    });
  });
}


