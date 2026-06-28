import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final Box _box = Hive.box('settings');

  ThemeMode get themeMode {
    final value = _box.get(_themeKey, defaultValue: 'system');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get themeModeName {
    final value = _box.get(_themeKey, defaultValue: 'system');
    switch (value) {
      case 'light':
        return 'Terang';
      case 'dark':
        return 'Gelap';
      default:
        return 'Mengikuti Sistem';
    }
  }

  Future<void> setThemeMode(String mode) async {
    String modeValue;
    switch (mode) {
      case 'Terang':
        modeValue = 'light';
        break;
      case 'Gelap':
        modeValue = 'dark';
        break;
      default:
        modeValue = 'system';
    }
    await _box.put(_themeKey, modeValue);
    notifyListeners();
  }
}
