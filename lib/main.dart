import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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

  // Aktifkan Firebase App Check.
  // - Debug build: gunakan DebugProvider (tidak perlu token nyata, aman untuk CI/dev).
  // - Release build: gunakan Play Integrity (Android) dan DeviceCheck (iOS).
  // PENTING: Aktifkan juga enforcement di Firebase Console → App Check.
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.deviceCheck,
    webProvider: ReCaptchaEnterpriseProvider(
      dotenv.env['RECAPTCHA_ENTERPRISE_SITE_KEY'] ?? '',
    ),
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
  await Hive.openBox("onboarding");
  await Hive.openBox("reminders");
  await Hive.openBox("settings");
}

