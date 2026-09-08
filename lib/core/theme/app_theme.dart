import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0F1218);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceSubtle = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);

  static const Color primary = Color(0xFF58A6FF);
  static const Color accentCyan = Color(0xFF39C5CF);
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
    );
  }
}
