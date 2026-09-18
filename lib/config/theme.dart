import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFF1C2430);
  static const muted = Color(0xFF5C6B7A);
  static const accent = Color(0xFF1F6FEB);
  static const paper = Color(0xFFF6F3EC);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: accent),
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFDFBF7),
        foregroundColor: ink,
        elevation: 0,
      ),
    );
  }
}
