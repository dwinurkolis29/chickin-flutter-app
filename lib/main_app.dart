// main_app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recording_app/core/services/firebase_service.dart';
import 'package:recording_app/features/cage/presentation/controllers/cage_controller.dart';
import 'package:recording_app/features/auth/presentation/login.dart';
import 'package:recording_app/features/dashboard/presentation/home.dart';

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
        // Tambahkan provider lain di sini kalau ada
      ],
      child: MaterialApp(
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromRGBO(32, 63, 129, 1.0),
          ),
        ),
        // Gunakan FirebaseAuth untuk menentukan initial route
        home: FirebaseAuth.instance.currentUser != null 
            ? const Home() 
            : const Login(),
      ),
    );
  }
}