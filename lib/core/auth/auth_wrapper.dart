import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/dashboard/presentation/dashboard.dart';
import 'package:recording_app/features/onboarding/presentation/pages/onboarding_page.dart';

/// AuthWrapper bertanggung jawab untuk routing saja — bukan lifecycle controller.
/// Lifecycle controller dikelola oleh ProxyProvider di main_app.dart.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // First-launch guard: tampilkan onboarding jika belum pernah dilihat
    final onboardingSeen =
        Hive.box('onboarding').get('seen', defaultValue: false) as bool;
    if (!onboardingSeen) {
      return const OnboardingPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return snapshot.hasData ? const Dashboard() : const Login();
      },
    );
  }
}
