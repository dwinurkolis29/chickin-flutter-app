import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/core/theme/theme_controller.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/user/presentation/pages/profile_screen.dart';

class _FakeUser extends Fake implements fb.User {
  @override
  final String displayName;
  @override
  final String email;

  _FakeUser({required this.displayName, required this.email});
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  fb.User? _currentUser;
  bool _signOutCalled = false;

  _FakeAuthService({fb.User? user}) : _currentUser = user;

  @override
  fb.User? get currentUser => _currentUser;

  String? get uid => _currentUser?.uid;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  bool get isInitialized => true;

  @override
  Future<void> signOut() async {
    _signOutCalled = true;
    _currentUser = null;
    notifyListeners();
  }

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
  bool get isUploadingAvatar => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> loadUserData() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemeController extends ChangeNotifier implements ThemeController {
  String _currentMode = 'light';

  @override
  ThemeMode get themeMode => _currentMode == 'dark'
      ? ThemeMode.dark
      : _currentMode == 'system'
          ? ThemeMode.system
          : ThemeMode.light;

  @override
  String get currentThemeKey => _currentMode;

  @override
  String get themeModeName => _currentMode == 'dark'
      ? 'Tema Gelap'
      : _currentMode == 'system'
          ? 'Sesuai Sistem'
          : 'Tema Terang';

  @override
  Future<void> setThemeMode(String mode) async {
    final lower = mode.toLowerCase();
    if (lower.contains('gelap') || lower == 'dark') {
      _currentMode = 'dark';
    } else if (lower.contains('sistem') || lower == 'system') {
      _currentMode = 'system';
    } else {
      _currentMode = 'light';
    }
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createWidgetUnderTest({
    _FakeAuthService? authService,
    _FakeUserController? userController,
    _FakeThemeController? themeController,
  }) {
    final fakeAuth = authService ??
        _FakeAuthService(
          user: _FakeUser(
            displayName: 'Budi Peternak',
            email: 'budi@example.com',
          ),
        );
    final fakeUser = userController ??
        _FakeUserController(
          profile: const UserProfile(name: 'Budi Peternak'),
        );
    final fakeTheme = themeController ?? _FakeThemeController();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuth),
        ChangeNotifierProvider<UserController>.value(value: fakeUser),
        ChangeNotifierProvider<ThemeController>.value(value: fakeTheme),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const Scaffold(body: ProfileScreen()),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('menampilkan profil pengguna, badge aktif, dan daftar menu', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Profil header
      expect(find.text('Budi Peternak'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text('BP'), findsOneWidget); // Initials
      expect(find.text('Akun Peternak Aktif'), findsOneWidget);

      // Menu Pengaturan Akun
      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Kelola Akun'), findsOneWidget);

      // Menu Manajemen Peternakan
      expect(find.text('Pertumbuhan Bobot Ayam'), findsOneWidget);
      expect(find.text('Periode Pemeliharaan'), findsOneWidget);
      expect(find.text('Data Kandang'), findsOneWidget);
      expect(find.text('Semua Recording'), findsOneWidget);
      expect(find.text('Monitoring FCR'), findsOneWidget);
      expect(find.text('Laporan Periode Panen'), findsOneWidget);
      expect(find.text('Pengingat & Alarm'), findsNothing);

      // Menu Kamus & Panduan Ternak
      expect(find.text('Kalkulator Cepat'), findsOneWidget);
      expect(find.text('Ensiklopedia Broiler'), findsOneWidget);

      // Menu Informasi Sistem
      expect(find.text('Tentang Aplikasi'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);

      // Menu Keluar
      expect(find.text('Keluar dari Akun'), findsOneWidget);

      // Memastikan 'Hubungi support' tetap tidak ada
      expect(find.text('Hubungi support'), findsNothing);
    });

    testWidgets('menampilkan dialog Tentang Aplikasi saat diklik', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Scroll to & Tap Tentang Aplikasi
      await tester.ensureVisible(find.text('Tentang Aplikasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tentang Aplikasi'));
      await tester.pumpAndSettle();

      expect(find.text('BroilerKu'), findsOneWidget);
      expect(find.text('Versi 1.0.0 • Production Ready'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      // Tutup dialog
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      expect(find.text('Versi 1.0.0 • Production Ready'), findsNothing);
    });

    testWidgets('menampilkan konfirmasi keluar dan memanggil signOut', (tester) async {
      final authService = _FakeAuthService(
        user: _FakeUser(displayName: 'Budi', email: 'budi@test.com'),
      );

      await tester.pumpWidget(createWidgetUnderTest(authService: authService));
      await tester.pump();

      // Scroll to & Tap Keluar dari Akun
      await tester.ensureVisible(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Konfirmasi keluar
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(authService._signOutCalled, isTrue);
    });

    testWidgets('menampilkan menu Tema Aplikasi dan dapat mengubah tema ke Tema Gelap', (tester) async {
      final themeCtrl = _FakeThemeController();

      await tester.pumpWidget(createWidgetUnderTest(themeController: themeCtrl));
      await tester.pump();

      // Ensure menu Tema Aplikasi is visible
      await tester.ensureVisible(find.text('Tema Aplikasi'));
      await tester.pumpAndSettle();

      expect(find.text('PENGATURAN & APLIKASI'), findsOneWidget);
      expect(find.text('Tema Terang'), findsWidgets);

      // Open bottom sheet
      await tester.tap(find.text('Tema Aplikasi'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Tema Aplikasi'), findsOneWidget);
      expect(find.text('Tema Terang'), findsWidgets);
      expect(find.text('Tema Gelap'), findsOneWidget);
      expect(find.text('Sesuai Sistem'), findsOneWidget);

      // Select Tema Gelap
      await tester.tap(find.text('Tema Gelap'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Tema Aplikasi'), findsNothing);
      expect(themeCtrl.currentThemeKey, equals('dark'));
      expect(themeCtrl.themeModeName, equals('Tema Gelap'));
    });
  });
}
