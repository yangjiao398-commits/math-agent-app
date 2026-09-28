import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFF1A2433);
  static const muted = Color(0xFF5C6B7A);
  static const accent = Color(0xFF1F5FBF);
  static const accentSoft = Color(0xFFE7F0FC);
  static const paper = Color(0xFFF3EFE6);
  static const surface = Color(0xFFFFFCF7);
  static const line = Color(0xFFE4DDD0);
  static const success = Color(0xFF0F7B5A);
  static const successSoft = Color(0xFFE3F5EE);
  static const gold = Color(0xFFB8860B);
  static const goldSoft = Color(0xFFF8EDD2);
  static const danger = Color(0xFFB42318);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: Colors.white,
      secondary: success,
      onSecondary: Colors.white,
      tertiary: gold,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(color: line, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: accentSoft,
        selectedColor: accent,
        disabledColor: line,
        labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
        labelStyle: const TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: Color(0xFFBFD3F2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: muted,
        textColor: ink,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        titleLarge: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: muted, fontSize: 13, height: 1.45),
      ),
    );
  }
}
