import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// Hand-picked light/dark color schemes per palette. We build explicit
/// ColorSchemes (rather than ColorScheme.fromSeed) so the exact palette
/// colors the user picked are preserved, with onColors chosen for strong
/// text contrast in both light and dark mode.
class PaletteColors {
  final ColorScheme light;
  final ColorScheme dark;

  const PaletteColors({required this.light, required this.dark});
}

const _busClassic = PaletteColors(
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFFFC107),
    onPrimary: Color(0xFF212121),
    secondary: Color(0xFFFF6F00),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFF212121),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFDF6),
    onSurface: Color(0xFF212121),
    surfaceContainerHighest: Color(0xFFFFF3D6),
    outline: Color(0xFF8A7A4E),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFC107),
    onPrimary: Color(0xFF212121),
    secondary: Color(0xFFFFA040),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFFFFE082),
    onTertiary: Color(0xFF212121),
    error: Color(0xFFCF6679),
    onError: Color(0xFF212121),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFF5F5F5),
    surfaceContainerHighest: Color(0xFF2C2A22),
    outline: Color(0xFFB8AC85),
  ),
);

const _blueTrust = PaletteColors(
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1E88E5),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFFFC107),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFF37474F),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFF7FAFD),
    onSurface: Color(0xFF1B2126),
    surfaceContainerHighest: Color(0xFFDCEBFA),
    outline: Color(0xFF5C7A94),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF64B5F6),
    onPrimary: Color(0xFF0D2436),
    secondary: Color(0xFFFFD54F),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFFB0BEC5),
    onTertiary: Color(0xFF1B2126),
    error: Color(0xFFCF6679),
    onError: Color(0xFF212121),
    surface: Color(0xFF1A1F23),
    onSurface: Color(0xFFF0F4F7),
    surfaceContainerHighest: Color(0xFF29323A),
    outline: Color(0xFF8FA6B5),
  ),
);

const _greenSafe = PaletteColors(
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E7D32),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFFBC02D),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFF455A64),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAF6),
    onSurface: Color(0xFF1C231D),
    surfaceContainerHighest: Color(0xFFDCEDD4),
    outline: Color(0xFF6E8A64),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF81C784),
    onPrimary: Color(0xFF0F2911),
    secondary: Color(0xFFFFD95E),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFFB0BEC5),
    onTertiary: Color(0xFF1B2126),
    error: Color(0xFFCF6679),
    onError: Color(0xFF212121),
    surface: Color(0xFF1B1F1A),
    onSurface: Color(0xFFF1F5EF),
    surfaceContainerHighest: Color(0xFF283227),
    outline: Color(0xFF9AB090),
  ),
);

const _purpleModern = PaletteColors(
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6A1B9A),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFFFA000),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFF37474F),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFAF7FC),
    onSurface: Color(0xFF231B27),
    surfaceContainerHighest: Color(0xFFEADCF2),
    outline: Color(0xFF8A6E96),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFCE93D8),
    onPrimary: Color(0xFF2E0E3D),
    secondary: Color(0xFFFFC46B),
    onSecondary: Color(0xFF212121),
    tertiary: Color(0xFFB0BEC5),
    onTertiary: Color(0xFF1B2126),
    error: Color(0xFFCF6679),
    onError: Color(0xFF212121),
    surface: Color(0xFF201B23),
    onSurface: Color(0xFFF3EEF5),
    surfaceContainerHighest: Color(0xFF322B36),
    outline: Color(0xFFAC94B3),
  ),
);

PaletteColors colorsForPalette(AppPalette palette) {
  switch (palette) {
    case AppPalette.busClassic:
      return _busClassic;
    case AppPalette.blueTrust:
      return _blueTrust;
    case AppPalette.greenSafe:
      return _greenSafe;
    case AppPalette.purpleModern:
      return _purpleModern;
  }
}
