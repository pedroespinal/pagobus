import 'package:intl/intl.dart';

/// Common currencies a school-transport user might need, with the symbol we
/// display (kept independent of the phone's locale so the amount always
/// reads the way the user picked in Settings, not whatever the device
/// language happens to imply).
const Map<String, String> currencySymbols = {
  'USD': r'US$',
  'DOP': r'RD$',
  'EUR': '€',
  'MXN': r'MX$',
  'COP': r'COL$',
  'ARS': r'AR$',
  'CLP': r'CL$',
  'PEN': 'S/',
  'GTQ': 'Q',
  'HNL': 'L',
  'CRC': '₡',
  'PAB': 'B/.',
  'BOB': 'Bs',
  'UYU': r'$U',
  'VES': 'Bs.S',
};

const String defaultCurrencyCode = 'USD';

String formatAmount(double amount, String currencyCode) {
  final symbol = currencySymbols[currencyCode] ?? currencyCode;
  final formatted = NumberFormat('#,##0.00').format(amount);
  return '$symbol$formatted';
}
