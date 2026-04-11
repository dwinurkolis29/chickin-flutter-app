import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/dashboard/presentation/dashboard.dart';
import 'package:recording_app/features/onboarding/presentation/pages/onboarding_page.dart';

import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'package:recording_app/core/tour/tour_controller.dart';

/// AuthWrapper handles authentication state at the app root level.
/// It listens to Firebase Auth state changes and displays the appropriate screen.
/// Because it is rendered below MultiProvider, it can safely reset controllers.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _authSubscription;
  String? _previousUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        final currentUid = user?.uid;

        if (currentUid == null) {
          // Logout: hanya bersihkan data, JANGAN subscribe ulang ke Firestore.
          _clearAllControllers();
        } else if (_previousUid != currentUid) {
          // Ganti akun atau login dari kondisi null: subscribe ulang dengan UID baru.
          _reloadAllControllers();
        }

        _previousUid = currentUid;
      });
    });
  }

  void _clearAllControllers() {
    if (!mounted) return;
    context.read<CageController>().clear();
    context.read<HomeController>().clear();
    context.read<PeriodController>().clear();
    context.read<RecordingController>().clear();
    context.read<ReportingController>().clear();
    context.read<TourController>().clear();
  }

  void _reloadAllControllers() {
    if (!mounted) return;
    context.read<CageController>().reload();
    context.read<HomeController>().reload();
    context.read<PeriodController>().reload();
    context.read<RecordingController>().reload();
    context.read<ReportingController>().reload();
    context.read<TourController>().reload();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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
