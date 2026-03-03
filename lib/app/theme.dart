import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF006A6A),
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF80D5D5),
    brightness: Brightness.dark,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: _lightScheme.surface,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightScheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: _darkScheme.surface,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkScheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
