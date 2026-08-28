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

  _FakeUser({
    required this.email,
    required this.uid,
  });
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  fb.User? _currentUser;

  _FakeAuthService({fb.User? user}) : _currentUser = user;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

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
    testWidgets('menampilkan panduan keamanan, info email, dan status tahap pengembangan', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Kelola Akun'), findsOneWidget);
      expect(find.text('Keamanan & Akses Akun'), findsOneWidget);
      expect(find.text('INFORMASI LOGIN & AKUN'), findsOneWidget);
      expect(find.text('peternak.jaya@gmail.com'), findsOneWidget);
      expect(find.text('Akun Aktif'), findsOneWidget);
      expect(find.text('Verifikasi Email Terdaftar'), findsOneWidget);

      expect(find.text('KEAMANAN KATA SANDI'), findsOneWidget);
      expect(find.text('Ubah Kata Sandi Langsung'), findsOneWidget);
      expect(find.text('Kirim Link Reset ke Email'), findsOneWidget);

      // Status tahap pengembangan
      expect(find.text('Tahap Pengembangan'), findsNWidgets(2));

      expect(find.text('PENGATURAN KRITIS AKUN'), findsOneWidget);
      expect(find.text('Hapus Akun Peternak Permanen'), findsOneWidget);
    });

    testWidgets('mengetuk opsi reset kata sandi email menampilkan dialog informasi tahap pengembangan', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Link Reset ke Email'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Kata Sandi via Email (Tahap Pengembangan)'), findsOneWidget);
      expect(find.text('Saya Mengerti'), findsOneWidget);
    });

    testWidgets('mengetuk opsi verifikasi email menampilkan dialog informasi tahap pengembangan', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verifikasi Email Terdaftar'));
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi Email (Tahap Pengembangan)'), findsOneWidget);
      expect(find.text('Saya Mengerti'), findsOneWidget);
    });
  });
}
