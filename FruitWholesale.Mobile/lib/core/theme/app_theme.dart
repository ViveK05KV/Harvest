import 'package:flutter/material.dart';

/// Design tokens mirroring the Angular client's redesigned palette exactly
/// (see FruitWholesale.Client/src/styles.scss and the per-component .scss
/// files) so the two apps read as one product. Kept as named constants
/// rather than inlined so any screen needing a raw hex (e.g. a custom-painted
/// chart or badge Flutter's theme can't reach) pulls from the same source
/// instead of re-guessing a color.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF1C6B45);
  static const primaryDark = Color(0xFF155538);
  static const primaryTint = Color(0xFFEAF2ED);

  static const ink = Color(0xFF121614);
  static const mutedInk = Color(0xFF78837C);
  static const faintInk = Color(0xFFA8B1A9);

  static const pageBackground = Color(0xFFF3F5F2);
  static const surfaceTint = Color(0xFFF7F9F7);
  static const border = Color(0xFFE4E8E4);
  static const borderStrong = Color(0xFFC3CBC4);
  static const divider = Color(0xFFF3F5F2);

  static const negative = Color(0xFFB03A2E);
  static const negativeTint = Color(0xFFF6ECEA);
  static const positive = primary;
  static const positiveTint = primaryTint;

  static const sidebarBg = Color(0xFF141C17);
  static const sidebarText = Color(0xFFE6ECE7);
  static const sidebarMuted = Color(0xFF7D9285);
}

/// Material 3 theme matching the Angular client's redesigned look — same
/// green, same neutrals, same 10-14px corner radii.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondaryContainer: AppColors.primaryTint,
      onSecondaryContainer: AppColors.primary,
      error: AppColors.negative,
      errorContainer: AppColors.negativeTint,
      onErrorContainer: AppColors.negative,
      surface: Colors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.mutedInk,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );
    return _themeFrom(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    return _themeFrom(scheme);
  }

  static ThemeData _themeFrom(ColorScheme scheme) {
    const ink = AppColors.ink;
    const mutedInk = AppColors.mutedInk;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: ink,
        titleTextStyle: TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        iconTheme: IconThemeData(color: AppColors.mutedInk),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.negative)),
        labelStyle: const TextStyle(color: mutedInk, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryTint,
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
        iconColor: AppColors.mutedInk,
        subtitleTextStyle: TextStyle(color: mutedInk),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceTint,
        labelStyle: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
