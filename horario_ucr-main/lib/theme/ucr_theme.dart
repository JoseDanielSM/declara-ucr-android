import 'package:flutter/material.dart';
import 'ucr_colors.dart';

class UcrTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'MyriadPro',
        colorScheme: ColorScheme.fromSeed(seedColor: UcrColors.blue).copyWith(
          primary: UcrColors.blue,
          onPrimary: UcrColors.white,
          secondary: UcrColors.cyan,
          onSecondary: UcrColors.text,
          surface: UcrColors.white,
          onSurface: UcrColors.text,
        ),
        scaffoldBackgroundColor: UcrColors.background,
        textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 16)),
        appBarTheme: const AppBarTheme(
            backgroundColor: UcrColors.blue,
            foregroundColor: UcrColors.white,
            centerTitle: false),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: UcrColors.white,
                backgroundColor: UcrColors.blue,
                disabledForegroundColor: UcrColors.muted,
                disabledBackgroundColor: UcrColors.border)),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48))),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: UcrColors.white,
          errorMaxLines: 3,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      );
}
