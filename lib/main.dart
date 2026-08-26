import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recording_app/core/services/notification_service.dart';
import 'firebase_options.dart';

import 'main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: 'assets/env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Aktifkan Firebase App Check jika bukan web, atau jika di web site key reCAPTCHA diisi.
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
  } else {
    final siteKey = dotenv.env['RECAPTCHA_ENTERPRISE_SITE_KEY'] ?? '';
    if (siteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaEnterpriseProvider(siteKey),
      );
    }
  }

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

