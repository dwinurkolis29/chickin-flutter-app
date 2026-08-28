import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/dashboard/presentation/widgets/dashboard_greeting.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';

class _FakeUser extends Fake implements fb.User {
  @override
  final String displayName;
  @override
  final String email;
  @override
  final String? photoURL;

  _FakeUser({
    required this.displayName,
    required this.email,
  }) : photoURL = null;
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  final fb.User? _currentUser;

  _FakeAuthService({fb.User? user}) : _currentUser = user;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  String? get currentUid => _currentUser?.uid;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  bool get isInitialized => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserController extends ChangeNotifier implements UserController {
  final UserProfile? _userProfile;

  _FakeUserController({UserProfile? profile}) : _userProfile = profile;

  @override
  UserProfile? get userProfile => _userProfile;

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseService extends Fake implements FirebaseService {}

class _TestHomeController extends HomeController {
  final String? _mockPeriodName;

  _TestHomeController({String? activePeriodName})
      : _mockPeriodName = activePeriodName,
        super(firebaseService: _FakeFirebaseService());

  @override
  String? get activePeriodName => _mockPeriodName;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidgetUnderTest({
    UserProfile? userProfile,
    fb.User? firebaseUser,
    String? activePeriodName,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => _FakeAuthService(user: firebaseUser),
        ),
        ChangeNotifierProvider<UserController>(
          create: (_) => _FakeUserController(profile: userProfile),
        ),
        ChangeNotifierProvider<HomeController>(
          create: (_) => _TestHomeController(activePeriodName: activePeriodName),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const Scaffold(
          body: DashboardGreeting(),
        ),
      ),
    );
  }

  group('DashboardGreeting Widget Tests', () {
    testWidgets('menampilkan nama profil dan tanggal hari ini dengan benar', (tester) async {
      const profile = UserProfile(
        name: 'Budi Santoso',
        phone: '08123456789',
        address: 'Kandang 1',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        userProfile: profile,
        activePeriodName: 'Siklus 1',
      ));
      await tester.pumpAndSettle();

      // Nama profil
      expect(find.text('Budi Santoso'), findsOneWidget);
      // Inisial avatar
      expect(find.text('B'), findsOneWidget);
      // Badge periode aktif
      expect(find.text('Siklus 1'), findsOneWidget);
      // Icon kalender
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    });

    testWidgets('menampilkan fallback Peternak jika userProfile dan firebaseUser kosong', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Peternak'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
      expect(find.text('Siklus 1'), findsNothing);
    });

    testWidgets('menampilkan nama dari firebaseUser jika userProfile kosong', (tester) async {
      final user = _FakeUser(displayName: 'Ahmad Fauzi', email: 'ahmad@mail.com');

      await tester.pumpWidget(createWidgetUnderTest(
        firebaseUser: user,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ahmad Fauzi'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });
  });
}
