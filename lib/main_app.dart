// main_app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/auth/auth_wrapper.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Setup CageController
        ChangeNotifierProvider(
          create: (_) => CageController(
            firebaseService: FirebaseService(),
            auth: FirebaseAuth.instance,
          ),
        ),
        // Setup HomeController
        ChangeNotifierProvider(
          create: (_) => HomeController(
            firebaseService: FirebaseService(),
          ),
        ),
        // Setup PeriodController
        ChangeNotifierProvider(
          create: (_) => PeriodController(
            firebaseService: FirebaseService(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        // Use AuthWrapper at app root for centralized auth management
        home: const AuthWrapper(),
      ),
    );
  }
}