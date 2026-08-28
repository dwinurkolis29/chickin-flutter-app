import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/auth/presentation/signup.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';

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
  bool signUpCalled = false;
  String? lastEmail;
  String? lastPassword;
  UserProfile? lastProfile;
  bool shouldSucceed = true;
  String? errorMsg;

  @override
  bool get isLoggedIn => false;

  @override
  bool get isInitialized => true;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    signUpCalled = true;
    lastEmail = email;
    lastPassword = password;
    lastProfile = profile;

    if (shouldSucceed) {
      return AuthResult.success(
        _FakeUser(displayName: profile.name, email: email, uid: 'uid123'),
      );
    } else {
      return AuthResult.failure(errorMsg ?? 'Gagal membuat akun');
    }
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
        home: const Signup(),
      ),
    );
  }

  group('Signup Widget Tests', () {
    testWidgets('menampilkan header pendaftaran, form input, dan tombol daftar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Daftar Akun Peternak'), findsOneWidget);
      expect(find.text('Mulai Bersama Chickin'), findsOneWidget);
      expect(find.text('DATA DIRI & KANDANG'), findsOneWidget);

      expect(find.text('Nama Lengkap Peternak'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Nomor WhatsApp / HP (Opsional)'), findsOneWidget);
      expect(find.text('Alamat / Lokasi Kandang (Opsional)'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
      expect(find.text('Sudah punya akun peternak? '), findsOneWidget);
      expect(find.text('Masuk di Sini'), findsOneWidget);
    });

    testWidgets('validasi form pendaftaran ketika input kosong atau tidak cocok', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = _FakeAuthService();
      await tester.pumpWidget(createWidgetUnderTest(authService: auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
      expect(auth.signUpCalled, isFalse);
    });

    testWidgets('memproses registrasi dengan data valid', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = _FakeAuthService();
      await tester.pumpWidget(createWidgetUnderTest(authService: auth));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Nama Lengkap Peternak');
      final emailField = find.widgetWithText(TextFormField, 'Alamat Email');
      final phoneField = find.widgetWithText(TextFormField, 'Nomor WhatsApp / HP (Opsional)');
      final addressField = find.widgetWithText(TextFormField, 'Alamat / Lokasi Kandang (Opsional)');
      final passField = find.widgetWithText(TextFormField, 'Kata Sandi');
      final confirmPassField = find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi');

      await tester.enterText(nameField, 'Budi Santoso');
      await tester.enterText(emailField, 'budi@peternak.com');
      await tester.enterText(phoneField, '081234567890');
      await tester.enterText(addressField, 'Subang, Jawa Barat');
      await tester.enterText(passField, 'rahasia123');
      await tester.enterText(confirmPassField, 'rahasia123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(auth.signUpCalled, isTrue);
      expect(auth.lastEmail, 'budi@peternak.com');
      expect(auth.lastPassword, 'rahasia123');
      expect(auth.lastProfile?.name, 'Budi Santoso');
      expect(auth.lastProfile?.phone, '081234567890');
      expect(auth.lastProfile?.address, 'Subang, Jawa Barat');
    });
  });
}
