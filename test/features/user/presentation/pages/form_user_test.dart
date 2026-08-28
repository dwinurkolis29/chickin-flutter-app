import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/theme/app_theme_option.dart';
import 'package:recording_app/features/user/data/models/user_data.dart';
import 'package:recording_app/features/user/presentation/pages/form_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class _FakeUser extends Fake implements fb.User {
  @override
  final String email = 'peternak@example.com';
  @override
  final String displayName = 'Pak Haji Slamet';
}

class _FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  fb.User? get currentUser => _FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createWidgetUnderTest({UserProfile? initialProfile}) {
    return ChangeNotifierProvider<AuthService>.value(
      value: _FakeAuthService(),
      child: MaterialApp(
        theme: AppTheme.build(AppThemeOption.light),
        home: FormUser(
          userProfile: initialProfile ??
              const UserProfile(
                name: 'H. Ahmad Supriyadi',
                phone: '081234567890',
                address: 'Dusun Krajan RT 01/02',
              ),
        ),
      ),
    );
  }

  group('FormUser Widget Tests', () {
    testWidgets('menampilkan header panduan, field input yang jelas, dan tombol simpan', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil Peternak'), findsOneWidget);
      expect(find.text('Informasi Akun Peternak'), findsOneWidget);
      expect(find.text('Nama Lengkap Peternak'), findsOneWidget);
      expect(find.text('Nomor HP / WhatsApp Aktif'), findsOneWidget);
      expect(find.text('Alamat Domisili Peternak'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });
  });
}
