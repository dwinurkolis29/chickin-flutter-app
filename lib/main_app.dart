import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:recording_app/core/auth/auth_service.dart';
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
        // AuthService — satu pintu semua urusan autentikasi.
        // Didaftarkan paling atas agar bisa diakses oleh StreamProvider di bawah.
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),

        // UID stream dari AuthService — single source of truth.
        // ProxyProvider semua controller bergantung pada ini.
        StreamProvider<String?>(
          create: (context) => context.read<AuthService>().uidStream,
          initialData: null,
        ),

        ChangeNotifierProxyProvider<String?, UserController>(
          create: (_) => UserController(
            firebaseService: FirebaseService(),
            storageService: StorageService(),
            auth: FirebaseAuth.instance,
          ),
          update: (_, uid, controller) {
            controller!.onAuthChanged(uid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<String?, CageController>(
          create: (_) => CageController(
            firebaseService: FirebaseService(), 
            storageService: StorageService(),
            auth: FirebaseAuth.instance,
          ),
          update: (_, uid, controller) {
            controller!.onAuthChanged(uid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<String?, HomeController>(
          create: (_) => HomeController(
            firebaseService: FirebaseService(),
          ),
          update: (_, uid, controller) {
            controller!.onAuthChanged(uid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<String?, PeriodController>(
          create: (_) => PeriodController(
            firebaseService: FirebaseService(),
          ),
          update: (_, uid, controller) {
            controller!.onAuthChanged(uid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<String?, RecordingController>(
          create: (_) => RecordingController(
            firebaseService: FirebaseService(),
          ),
          update: (_, uid, controller) {
            controller!.onAuthChanged(uid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<String?, ReportingController>(
          create: (_) => ReportingController(
            firebaseService: FirebaseService(),
          ),
          update: (_, uid, controller) {
            controller!.onAuthChanged(uid);
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<String?, TourController>(
          create: (_) => TourController(
            firebaseService: FirebaseService(),
          ),
          update: (_, uid, controller) {
            controller!.onAuthChanged(uid);
            return controller;
          },
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