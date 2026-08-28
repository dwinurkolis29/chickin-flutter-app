import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/user/presentation/pages/user_profile.dart';

class _FakeUser extends Fake implements fb.User {
  @override
  final String displayName;
  @override
  final String email;

  _FakeUser({required this.displayName, required this.email});
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  fb.User? _currentUser;
  bool passwordResetSent = false;

  _FakeAuthService({fb.User? user}) : _currentUser = user;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetSent = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserController extends ChangeNotifier implements UserController {
  final UserProfile? _userProfile;
  final bool _isLoading;
  final String? _errorMessage;

  _FakeUserController({
    UserProfile? profile,
    bool isLoading = false,
    String? errorMessage,
  })  : _userProfile = profile,
        _isLoading = isLoading,
        _errorMessage = errorMessage;

  @override
  UserProfile? get userProfile => _userProfile;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isUploadingAvatar => false;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> loadUserData() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createWidgetUnderTest({
    _FakeAuthService? authService,
    _FakeUserController? userController,
  }) {
    final fakeAuth = authService ??
        _FakeAuthService(
          user: _FakeUser(
            displayName: 'Pak Slamet',
            email: 'slamet.broiler@gmail.com',
          ),
        );
    final fakeUser = userController ??
        _FakeUserController(
          profile: const UserProfile(
            name: 'Pak Slamet Peternak',
            phone: '081234567890',
            address: 'Desa Sukamaju, RT 02/05',
          ),
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuth),
        ChangeNotifierProvider<UserController>.value(value: fakeUser),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: const User(),
      ),
    );
  }

  group('UserProfile (Profil Saya) Widget Tests', () {
    testWidgets('menampilkan informasi identitas peternak, kontak, dan keamanan akun', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // 1. Identitas
      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('Pak Slamet Peternak'), findsOneWidget);
      expect(find.text('Peternak Terdaftar Aktif'), findsOneWidget);

      // 2. Kontak
      expect(find.text('Informasi Kontak & Domisili'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('slamet.broiler@gmail.com'), findsOneWidget);
      expect(find.text('Desa Sukamaju, RT 02/05'), findsOneWidget);

      // 3. Tombol Utama
      expect(find.text('Ubah Data Profil'), findsOneWidget);
    });
  });
}
