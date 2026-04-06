import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static palette — keeps all existing colour references working
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Primary – Electric Blue
  static const Color primary      = Color(0xFF0A84FF);
  static const Color primaryDark  = Color(0xFF0066CC);
  static const Color primaryLight = Color(0xFF3D9FFF);

  // Secondary
  static const Color secondary      = Color(0xFF5AC8FA);
  static const Color secondaryLight = Color(0xFF7DD5FF);
  static const Color secondaryDark  = Color(0xFF32B4F0);

  // Status
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error   = Color(0xFFFF453A);
  static const Color info    = Color(0xFF0A84FF);

  // Order status
  static const Color pending    = Color(0xFFFFD60A);
  static const Color processing = Color(0xFF0A84FF);
  static const Color shipped    = Color(0xFF5AC8FA);
  static const Color delivered  = Color(0xFF32D74B);
  static const Color cancelled  = Color(0xFF8E8E93);

  // Account badges
  static const Color goldBadge     = Color(0xFFFFD700);
  static const Color silverBadge   = Color(0xFFC0C0C0);
  static const Color bronzeBadge   = Color(0xFFCD7F32);
  static const Color standardBadge = Color(0xFF8E8E93);

  // Always-white / always-black
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Overlays / shadows
  static const Color overlay      = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color shadow       = Color(0x33000000);
  static const Color shadowLight  = Color(0x1A000000);
  static const Color shadowDark   = Color(0x4D000000);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF0A84FF), Color(0xFF5AC8FA)];
  static const List<Color> accentGradient  = [Color(0xFF0A84FF), Color(0xFF0066CC)];

  // ── Dark-theme static constants (legacy references) ────────────────────────
  static const Color background          = Color(0xFF1A1A1A);
  static const Color backgroundSecondary = Color(0xFF121212);
  static const Color surface             = Color(0xFF2C2C2E);
  static const Color surfaceLight        = Color(0xFF3A3A3C);
  static const Color cardBackground      = Color(0xFF2C2C2E);
  static const Color textPrimary         = Color(0xFFFFFFFF);
  static const Color textSecondary       = Color(0xFF8E8E93);
  static const Color textTertiary        = Color(0xFF636366);
  static const Color textHint            = Color(0xFF48484A);
  static const Color textLight           = Color(0xFFFFFFFF);
  static const Color offWhite            = Color(0xFFF2F2F7);
  static const Color lightGray           = Color(0xFF48484A);
  static const Color gray                = Color(0xFF8E8E93);
  static const Color darkGray            = Color(0xFF3A3A3C);
  static const Color border              = Color(0xFF3A3A3C);
  static const Color borderLight         = Color(0xFF48484A);
  static const List<Color> darkGradient  = [Color(0xFF1A1A1A), Color(0xFF2C2C2E)];
  static const List<Color> cardGradient  = [Color(0xFF2C2C2E), Color(0xFF3A3A3C)];
}

/// Theme-aware colors — use these in build() so the whole app responds to dark/light toggle.
extension ThemeColors on BuildContext {
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;
  Color get textSecondaryColor => Theme.of(this).brightness == Brightness.dark
      ? AppColors.textSecondary
      : LightColors.textSecondary;
  Color get borderColor => Theme.of(this).brightness == Brightness.dark
      ? AppColors.border
      : LightColors.border;
  Color get cardColor => Theme.of(this).colorScheme.surface;
  Brightness get brightness => Theme.of(this).brightness;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Light-theme colour constants
// ─────────────────────────────────────────────────────────────────────────────
class LightColors {
  static const Color background  = Color(0xFFF8F2DA);
  static const Color surface     = Color(0xFFEEE7C6);
  static const Color surfaceLight= Color(0xFFE5DCAF);
  static const Color border      = Color(0xFFDDD5B8);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary= Color(0xFF6B6B6B);
  static const Color textHint    = Color(0xFFADA08A);
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme definitions
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  // ── DARK ───────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textPrimary,
      onError: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
      hintStyle: const TextStyle(color: AppColors.textHint),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border, width: 1)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : AppColors.gray),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary.withOpacity(0.5) : AppColors.darkGray),
    ),
  );

  // ── LIGHT ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: LightColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: LightColors.textPrimary,
      onError: AppColors.white,
    ),
    scaffoldBackgroundColor: LightColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: LightColors.background,
      foregroundColor: LightColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: LightColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LightColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LightColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
      hintStyle: const TextStyle(color: LightColors.textHint),
      labelStyle: const TextStyle(color: LightColors.textSecondary),
    ),
    cardTheme: CardThemeData(
      color: LightColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: LightColors.border, width: 1)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LightColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: LightColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: LightColors.border, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: LightColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: const TextStyle(color: LightColors.textPrimary),
      side: const BorderSide(color: LightColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: LightColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LightColors.surfaceLight,
      contentTextStyle: const TextStyle(color: LightColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : LightColors.textHint),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary.withOpacity(0.5) : LightColors.border),
    ),
    textTheme: const TextTheme(
      bodyLarge:   TextStyle(color: LightColors.textPrimary),
      bodyMedium:  TextStyle(color: LightColors.textPrimary),
      bodySmall:   TextStyle(color: LightColors.textSecondary),
      titleLarge:  TextStyle(color: LightColors.textPrimary),
      titleMedium: TextStyle(color: LightColors.textPrimary),
      titleSmall:  TextStyle(color: LightColors.textSecondary),
    ),
  );
}
