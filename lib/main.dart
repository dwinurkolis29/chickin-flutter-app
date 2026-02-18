import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'firebase_options.dart';

import 'main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notification Service
  await NotificationService().initialize();

  // Inisialisasi Hive
  await Hive.initFlutter();
  
  // Inisialisasi Hive boxes
  await _initHive();

  runApp(const MainApp());
}

Future<void> _initHive() async {
  await Hive.openBox("login");
  await Hive.openBox("accounts");
}
