import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment.dart';

/// Manages which days are excluded from the normal payment calendar
/// (weekends + holidays), while still allowing an extraordinary/eventual
/// service to be added on those days.
class HolidayService {
  HolidayService._internal();
  static final HolidayService instance = HolidayService._internal();

  static const _prefsKey = 'custom_holidays';

  /// Fixed-date holidays that repeat every year regardless of country
  /// (New Year, Labor Day, Christmas). Country-specific / movable holidays
  /// should be added by the user via settings.
  static const List<(int month, int day, String labelEs, String labelEn)>
  _fixedHolidays = [
    (1, 1, 'Año Nuevo', "New Year's Day"),
    (5, 1, 'Dia del Trabajo', 'Labor Day'),
    (12, 25, 'Navidad', 'Christmas'),
  ];

  List<String>? _customCache;

  bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool _isFixedHoliday(DateTime date) {
    return _fixedHolidays.any((h) => h.$1 == date.month && h.$2 == date.day);
  }

  Future<List<Map<String, String>>> getCustomHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _customCache = raw;
    return raw.map((entry) {
      final parts = jsonDecode(entry) as Map<String, dynamic>;
      return parts.map((k, v) => MapEntry(k, v.toString()));
    }).toList();
  }

  Future<void> addCustomHoliday(DateTime date, String label) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    raw.add(jsonEncode({'date': Payment.dateKey(date), 'label': label}));
    await prefs.setStringList(_prefsKey, raw);
    _customCache = raw;
  }

  Future<void> removeCustomHoliday(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    raw.removeWhere((entry) {
      final parts = jsonDecode(entry) as Map<String, dynamic>;
      return parts['date'] == dateKey;
    });
    await prefs.setStringList(_prefsKey, raw);
    _customCache = raw;
  }

  Future<bool> isCustomHoliday(DateTime date) async {
    final raw =
        _customCache ??
        await (() async {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getStringList(_prefsKey) ?? [];
        })();
    final key = Payment.dateKey(date);
    return raw.any((entry) {
      final parts = jsonDecode(entry) as Map<String, dynamic>;
      return parts['date'] == key;
    });
  }

  Future<bool> isHoliday(DateTime date) async {
    if (_isFixedHoliday(date)) return true;
    return isCustomHoliday(date);
  }

  /// True when this day is normally excluded from the payment calendar
  /// (weekend or holiday) and would need an extraordinary service entry.
  Future<bool> isExcludedDay(DateTime date) async {
    return isWeekend(date) || await isHoliday(date);
  }
}
