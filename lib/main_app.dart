import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/core/theme/app_theme.dart';
import 'package:recording_app/core/tour/tour_controller.dart';
import 'package:recording_app/core/services/storage_service.dart';
import 'package:recording_app/features/user/presentation/controllers/user_controller.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/dashboard/presentation/controllers/home_controller.dart';
import 'package:recording_app/features/period/presentation/controllers/period_controller.dart';
import 'package:recording_app/features/recording/presentation/controllers/recording_controller.dart';
import 'package:recording_app/features/reporting/presentation/controllers/reporting_controller.dart';
import 'app_checker.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthService — single source of truth untuk semua auth state.
        // Semua controller bergantung langsung ke instance ini via ProxyProvider.
        ChangeNotifierProvider(create: (_) => AuthService()),

        ChangeNotifierProxyProvider<AuthService, UserController>(
          create:
              (_) => UserController(
                firebaseService: FirebaseService(),
                storageService: StorageService(),
                auth: FirebaseAuth.instance,
              ),
          update: (_, auth, controller) {
            controller!.onAuthChanged(auth.currentUid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<AuthService, CageController>(
          create:
              (_) => CageController(
                firebaseService: FirebaseService(),
                storageService: StorageService(),
                auth: FirebaseAuth.instance,
              ),
          update: (_, auth, controller) {
            controller!.onAuthChanged(auth.currentUid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<AuthService, HomeController>(
          create: (_) => HomeController(firebaseService: FirebaseService()),
          update: (_, auth, controller) {
            controller!.onAuthChanged(auth.currentUid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<AuthService, PeriodController>(
          create: (_) => PeriodController(firebaseService: FirebaseService()),
          update: (_, auth, controller) {
            controller!.onAuthChanged(auth.currentUid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<AuthService, RecordingController>(
          create:
              (_) => RecordingController(firebaseService: FirebaseService()),
          update: (_, auth, controller) {
            controller!.onAuthChanged(auth.currentUid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<AuthService, ReportingController>(
          create:
              (_) => ReportingController(firebaseService: FirebaseService()),
          update: (_, auth, controller) {
            controller!.onAuthChanged(auth.currentUid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<AuthService, TourController>(
          create: (_) => TourController(firebaseService: FirebaseService()),
          update: (_, auth, controller) {
            controller!.onAuthChanged(auth.currentUid);
            return controller;
          },
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AppChecker(),
      ),
    );
  }
}
