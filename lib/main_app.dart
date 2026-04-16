// main_app.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/auth/auth_wrapper.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/tour/tour_controller.dart';
import 'package:recording_app/core/services/storage_service.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserController(
            firebaseService: FirebaseService(),
            storageService: StorageService(),
            auth: FirebaseAuth.instance,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CageController(
            firebaseService: FirebaseService(),
            storageService: StorageService(),
            auth: FirebaseAuth.instance,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeController(
            firebaseService: FirebaseService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PeriodController(
            firebaseService: FirebaseService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordingController(
            firebaseService: FirebaseService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportingController(
            firebaseService: FirebaseService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TourController(
            firebaseService: FirebaseService(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}