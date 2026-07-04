import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HomieThemePreference { dark, light, system }

class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final instance = ThemeService._();

  static const _prefKey = 'homie_theme_preference';

  HomieThemePreference _preference = HomieThemePreference.dark;
  bool _initialized = false;

  HomieThemePreference get preference => _preference;
  bool get isInitialized => _initialized;

  ThemeMode get materialThemeMode => switch (_preference) {
        HomieThemePreference.light => ThemeMode.light,
        HomieThemePreference.dark => ThemeMode.dark,
        HomieThemePreference.system => ThemeMode.system,
      };

  Brightness get resolvedBrightness {
    if (_preference == HomieThemePreference.light) return Brightness.light;
    if (_preference == HomieThemePreference.dark) return Brightness.dark;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  bool get isLight => resolvedBrightness == Brightness.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    _preference = HomieThemePreference.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => HomieThemePreference.dark,
    );
    _initialized = true;
    notifyListeners();
  }

  Future<void> setPreference(HomieThemePreference value) async {
    if (_preference == value) return;
    _preference = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value.name);
  }
}
