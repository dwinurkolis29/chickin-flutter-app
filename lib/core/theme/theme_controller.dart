import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final Box _box = Hive.box('settings');

  ThemeMode get themeMode {
    final value = _box.get(_themeKey, defaultValue: 'light');
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  String get currentThemeKey {
    return _box.get(_themeKey, defaultValue: 'light');
  }

  String get themeModeName {
    final value = _box.get(_themeKey, defaultValue: 'light');
    switch (value) {
      case 'dark':
        return 'Tema Gelap';
      case 'system':
        return 'Sesuai Sistem';
      case 'light':
      default:
        return 'Tema Terang';
    }
  }

  Future<void> setThemeMode(String mode) async {
    String modeValue;
    switch (mode.toLowerCase()) {
      case 'dark':
      case 'gelap':
      case 'tema gelap':
        modeValue = 'dark';
        break;
      case 'system':
      case 'sesuai sistem':
      case 'mengikuti sistem':
        modeValue = 'system';
        break;
      case 'light':
      case 'terang':
      case 'tema terang':
      default:
        modeValue = 'light';
    }
    await _box.put(_themeKey, modeValue);
    notifyListeners();
  }
}
