import 'package:flutter/material.dart';

/// Material 3 theme matching the Harvest green dashboard redesign.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF277A4B);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return _themeFrom(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _themeFrom(scheme);
  }

  static ThemeData _themeFrom(ColorScheme scheme) {
    const ink = Color(0xFF1D3125);
    const mutedInk = Color(0xFF4F6255);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F9F6),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF7F9F6),
        foregroundColor: ink,
        titleTextStyle: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: Color(0xFF315C40)),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDCE6DD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF277A4B), width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE7ECE6)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scheme.secondaryContainer,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ).copyWith(
        bodySmall: const TextStyle(color: mutedInk, fontSize: 12),
        bodyMedium: const TextStyle(color: ink, fontSize: 14),
        titleSmall: const TextStyle(color: ink, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: ink,
        iconColor: Color(0xFF39744F),
        subtitleTextStyle: TextStyle(color: mutedInk),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE1E9E2)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF277A4B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
