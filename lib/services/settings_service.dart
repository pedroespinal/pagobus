import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/currency_formatter.dart';

enum AppPalette { busClassic, blueTrust, greenSafe, purpleModern }

class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';
  static const _paletteKey = 'palette';
  static const _currencyKey = 'currency_code';
  static const _reminderEnabledKey = 'reminder_enabled';
  static const _reminderHourKey = 'reminder_hour';
  static const _reminderMinuteKey = 'reminder_minute';

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  AppPalette _palette = AppPalette.busClassic;
  String _currencyCode = defaultCurrencyCode;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;
  String get currencyCode => _currencyCode;
  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;

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
    _currencyCode = prefs.getString(_currencyKey) ?? defaultCurrencyCode;
    _reminderEnabled = prefs.getBool(_reminderEnabledKey) ?? false;
    _reminderTime = TimeOfDay(
      hour: prefs.getInt(_reminderHourKey) ?? 8,
      minute: prefs.getInt(_reminderMinuteKey) ?? 0,
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

  Future<void> setCurrencyCode(String code) async {
    _currencyCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);
  }
}
