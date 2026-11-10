import 'package:flutter/material.dart';

/// Rustige uitstraling: diep blauw als primair, subtiel warm oranje als accent.
/// Alarmkleur (error) wordt alleen gebruikt voor verlopen items.
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1F4E79),
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF9CC4F0) : const Color(0xFF1F4E79),
    onPrimary: dark ? const Color(0xFF0B2540) : Colors.white,
    tertiary: dark ? const Color(0xFFF2B27A) : const Color(0xFF9A4F0F),
    tertiaryContainer: dark ? const Color(0xFF4A2F14) : const Color(0xFFFBE6D2),
    onTertiaryContainer: dark ? const Color(0xFFFBE6D2) : const Color(0xFF4A2300),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );
}
