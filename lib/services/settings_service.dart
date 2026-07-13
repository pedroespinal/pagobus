import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPalette { busClassic, blueTrust, greenSafe, purpleModern }

class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';
  static const _paletteKey = 'palette';

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  AppPalette _palette = AppPalette.busClassic;

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null) {
      _locale = Locale(localeCode);
    }
    final themeModeStr = prefs.getString(_themeModeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeModeStr,
      orElse: () => ThemeMode.system,
    );
    final paletteStr = prefs.getString(_paletteKey);
    _palette = AppPalette.values.firstWhere(
      (p) => p.name == paletteStr,
      orElse: () => AppPalette.busClassic,
    );
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setPalette(AppPalette palette) async {
    _palette = palette;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.name);
  }
}
