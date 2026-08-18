import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/dashboard/presentation/dashboard.dart';
import 'package:recording_app/features/onboarding/presentation/pages/onboarding_page.dart';

/// Entry point routing setelah app boot.
///
/// Urutan:
///   1. Cek onboarding — kalau belum pernah lihat, tampilkan [OnboardingPage].
///   2. Kalau sudah, serahkan ke [_AuthGate] yang reactive terhadap auth state.
///
/// Onboarding dan auth state sengaja dipisah — keduanya punya concern berbeda.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Guard saat cold start — tunggu listener Firebase pertama kali fire.
    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return auth.isLoggedIn ? const Dashboard() : const Login();
  }
}
