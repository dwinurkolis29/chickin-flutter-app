import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/core/auth/auth_wrapper.dart';
import 'package:recording_app/features/onboarding/presentation/pages/onboarding_page.dart';

class AppChecker extends StatelessWidget {
  const AppChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingSeen =
        Hive.box('onboarding').get('seen', defaultValue: false) as bool;

    if (!onboardingSeen) {
      return const OnboardingPage();
    }

    return const AuthWrapper();
  }
}