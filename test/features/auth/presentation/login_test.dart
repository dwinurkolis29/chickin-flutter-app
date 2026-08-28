import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/auth/presentation/login.dart';

class _FakeUser extends Fake implements fb.User {
  @override
  final String displayName;
  @override
  final String email;
  @override
  final String uid;

  _FakeUser({
    required this.displayName,
    required this.email,
    required this.uid,
  });
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  fb.User? _currentUser;
  bool signInCalled = false;
  String? lastEmail;
  String? lastPassword;
  bool sendPasswordResetCalled = false;
  String? lastResetEmail;
  bool shouldSucceed = true;
  String? errorMsg;

  _FakeAuthService({fb.User? user}) : _currentUser = user;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  bool get isInitialized => true;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    lastEmail = email;
    lastPassword = password;
    if (shouldSucceed) {
      _currentUser = _FakeUser(displayName: 'Peternak Budi', email: email, uid: 'uid123');
      notifyListeners();
      return AuthResult.success(_currentUser!);
    } else {
      return AuthResult.failure(errorMsg ?? 'Email atau password salah');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sendPasswordResetCalled = true;
    lastResetEmail = email;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createWidgetUnderTest({_FakeAuthService? authService}) {
    final auth = authService ?? _FakeAuthService();
    return ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const Login(),
      ),
    );
  }

  group('Login Widget Tests', () {
    testWidgets('menampilkan header branding, form card, tombol masuk, dan tidak ada tombol Google', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Branding
      expect(find.text('Chickin BroilerKu'), findsOneWidget);
      expect(find.text('Aplikasi Pencatatan & Manajemen Peternakan Broiler'), findsOneWidget);

      // Form Card
      expect(find.text('MASUK KE AKUN'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
      expect(find.text('Masuk Sekarang'), findsOneWidget);

      // Footer
      expect(find.text('Belum punya akun peternak? '), findsOneWidget);
      expect(find.text('Daftar di Sini'), findsOneWidget);

      // Verifikasi tombol Google Sign-In tidak ada
      expect(find.text('Lanjutkan dengan Google'), findsNothing);
      expect(find.text('atau'), findsNothing);
    });

    testWidgets('validasi form login ketika input kosong', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = _FakeAuthService();
      await tester.pumpWidget(createWidgetUnderTest(authService: auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);
      expect(auth.signInCalled, isFalse);
    });

    testWidgets('memproses login dengan kredensial valid', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = _FakeAuthService();
      await tester.pumpWidget(createWidgetUnderTest(authService: auth));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'Alamat Email');
      final passwordField = find.widgetWithText(TextFormField, 'Kata Sandi');

      await tester.enterText(emailField, 'budi@peternak.com');
      await tester.enterText(passwordField, 'rahasia123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(auth.signInCalled, isTrue);
      expect(auth.lastEmail, 'budi@peternak.com');
      expect(auth.lastPassword, 'rahasia123');
    });

    testWidgets('menampilkan dialog Lupa Kata Sandi dan mengirim email reset', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = _FakeAuthService();
      await tester.pumpWidget(createWidgetUnderTest(authService: auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Kirim Tautan'), findsOneWidget);

      final dialogEmailField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(dialogEmailField, 'budi@peternak.com');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Tautan'));
      await tester.pumpAndSettle();

      expect(auth.sendPasswordResetCalled, isTrue);
      expect(auth.lastResetEmail, 'budi@peternak.com');
    });
  });
}
