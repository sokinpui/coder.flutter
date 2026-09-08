import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0F1218);
  static const Color surface = Color(0xFF181C24);
  static const Color surfaceSubtle = Color(0xFF222733);
  static const Color border = Color(0xFF2D3342);

  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(0xFFF1F3F4);
  static const Color lightBorder = Color(0xFFE0E3E7);
  static const Color lightTextMain = Color(0xFF202124);
  static const Color lightTextMuted = Color(0xFF5F6368);

  static const Color primary = Color(0xFF4C8DFF);
  static const Color accentCyan = Color(0xFF26B5CE);
  static const Color accentYellow = Color(0xFFF2CC60);
  static const Color accentPink = Color(0xFFFF7B72);
  static const Color textMain = Color(0xFFF0F6FC);
  static const Color textMuted = Color(0xFF8B949E);

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        surfaceContainerHighest: surfaceSubtle,
        outline: border,
        onSurface: textMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          color: surfaceSubtle,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        textStyle: const TextStyle(color: textMain, fontSize: 12),
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: lightSurface,
        surfaceContainerHighest: lightSurfaceSubtle,
        outline: lightBorder,
        onSurface: lightTextMain,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: lightTextMain),
        titleTextStyle: TextStyle(
          color: lightTextMain,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          color: lightSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: lightBorder),
        ),
        textStyle: const TextStyle(color: lightTextMain, fontSize: 12),
      ),
    );
  }
}
