import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/dashboard/presentation/dashboard.dart';
import 'package:recording_app/features/onboarding/presentation/pages/onboarding_page.dart';

/// AuthWrapper handles authentication state at the app root level.
/// It listens to Firebase Auth state changes and displays the appropriate screen.
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
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show Home if user is logged in, otherwise show Login
        if (snapshot.hasData) {
          return const Dashboard();
        } else {
          return const Login();
        }
      },
    );
  }
}
