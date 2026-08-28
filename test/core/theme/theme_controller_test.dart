import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/core/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_theme_test');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    final box = Hive.box('settings');
    await box.clear();
  });

  group('ThemeController Unit Tests', () {
    test('default theme mode adalah ThemeMode.light dengan nama Tema Terang', () {
      final controller = ThemeController();

      expect(controller.themeMode, equals(ThemeMode.light));
      expect(controller.currentThemeKey, equals('light'));
      expect(controller.themeModeName, equals('Tema Terang'));
    });

    test('setThemeMode("dark") mengubah mode ke ThemeMode.dark', () async {
      final controller = ThemeController();

      await controller.setThemeMode('dark');

      expect(controller.themeMode, equals(ThemeMode.dark));
      expect(controller.currentThemeKey, equals('dark'));
      expect(controller.themeModeName, equals('Tema Gelap'));
    });

    test('setThemeMode("Gelap") mengubah mode ke ThemeMode.dark', () async {
      final controller = ThemeController();

      await controller.setThemeMode('Gelap');

      expect(controller.themeMode, equals(ThemeMode.dark));
      expect(controller.themeModeName, equals('Tema Gelap'));
    });

    test('setThemeMode("system") mengubah mode ke ThemeMode.system', () async {
      final controller = ThemeController();

      await controller.setThemeMode('system');

      expect(controller.themeMode, equals(ThemeMode.system));
      expect(controller.currentThemeKey, equals('system'));
      expect(controller.themeModeName, equals('Sesuai Sistem'));
    });

    test('setThemeMode("Sesuai Sistem") mengubah mode ke ThemeMode.system', () async {
      final controller = ThemeController();

      await controller.setThemeMode('Sesuai Sistem');

      expect(controller.themeMode, equals(ThemeMode.system));
      expect(controller.themeModeName, equals('Sesuai Sistem'));
    });

    test('setThemeMode("Terang") mengembalikan mode ke ThemeMode.light', () async {
      final controller = ThemeController();

      await controller.setThemeMode('dark');
      expect(controller.themeMode, equals(ThemeMode.dark));

      await controller.setThemeMode('Terang');
      expect(controller.themeMode, equals(ThemeMode.light));
      expect(controller.themeModeName, equals('Tema Terang'));
    });
  });
}
