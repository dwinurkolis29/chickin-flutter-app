import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/user/presentation/pages/account_management_screen.dart';

class _FakeUser extends Fake implements fb.User {
  @override
  final String email;
  @override
  final String uid;
  @override
  final bool emailVerified;

  _FakeUser({
    required this.email,
    required this.uid,
    this.emailVerified = false,
  });
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  fb.User? _currentUser;
  bool resetEmailSent = false;
  bool verificationSent = false;

  _FakeAuthService({fb.User? user}) : _currentUser = user;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetEmailSent = true;
  }

  @override
  Future<void> sendEmailVerification() async {
    verificationSent = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createWidgetUnderTest({_FakeAuthService? authService}) {
    final fakeAuth = authService ??
        _FakeAuthService(
          user: _FakeUser(
            email: 'peternak.jaya@gmail.com',
            uid: 'uid_test_12345678',
            emailVerified: false,
          ),
        );

    return ChangeNotifierProvider<AuthService>.value(
      value: fakeAuth,
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const AccountManagementScreen(),
      ),
    );
  }

  group('AccountManagementScreen Widget Tests', () {
    testWidgets('menampilkan panduan keamanan, info email, dan opsi reset password', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Kelola Akun'), findsOneWidget);
      expect(find.text('Keamanan & Akses Akun'), findsOneWidget);
      expect(find.text('INFORMASI LOGIN & AKUN'), findsOneWidget);
      expect(find.text('peternak.jaya@gmail.com'), findsOneWidget);
      expect(find.text('Belum Verifikasi'), findsOneWidget);
      expect(find.text('Kirim Tautan Verifikasi Email'), findsOneWidget);

      expect(find.text('KEAMANAN KATA SANDI'), findsOneWidget);
      expect(find.text('Kirim Link Reset Password ke Email'), findsOneWidget);
      expect(find.text('Ubah Kata Sandi Langsung'), findsOneWidget);

      expect(find.text('PENGATURAN KRITIS AKUN'), findsOneWidget);
      expect(find.text('Hapus Akun Peternak Permanen'), findsOneWidget);
    });

    testWidgets('menekan kirim link reset password memicu sendPasswordResetEmail', (tester) async {
      final fakeAuth = _FakeAuthService(
        user: _FakeUser(
          email: 'peternak.jaya@gmail.com',
          uid: 'uid_test_12345678',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(authService: fakeAuth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Link Reset Password ke Email'));
      await tester.pumpAndSettle();

      expect(fakeAuth.resetEmailSent, isTrue);
    });

    testWidgets('menekan kirim verifikasi email memicu sendEmailVerification', (tester) async {
      final fakeAuth = _FakeAuthService(
        user: _FakeUser(
          email: 'peternak.jaya@gmail.com',
          uid: 'uid_test_12345678',
          emailVerified: false,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(authService: fakeAuth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Tautan Verifikasi Email'));
      await tester.pumpAndSettle();

      expect(fakeAuth.verificationSent, isTrue);
    });
  });
}
