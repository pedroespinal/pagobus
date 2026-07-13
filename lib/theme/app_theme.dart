import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import 'app_palettes.dart';

class AppTheme {
  static ThemeData light(AppPalette palette) => _build(colorsForPalette(palette).light);

  static ThemeData dark(AppPalette palette) => _build(colorsForPalette(palette).dark);

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: scheme.primary.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: scheme.onSurface,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      textTheme: Typography.material2021(colorScheme: scheme).black.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.secondary
              : null,
        ),
      ),
    );
  }
}
