import 'package:flutter/material.dart';

/// App Colors - Dark Theme with Blue Accent
/// Velox Shipping App
class AppColors {
  // Primary Colors - Electric Blue
  static const Color primary = Color(0xFF0A84FF); // Electric Blue
  static const Color primaryDark = Color(0xFF0066CC); // Darker blue
  static const Color primaryLight = Color(0xFF3D9FFF); // Lighter blue
  
  // Secondary Colors
  static const Color secondary = Color(0xFF5AC8FA); // Light blue
  static const Color secondaryLight = Color(0xFF7DD5FF);
  static const Color secondaryDark = Color(0xFF32B4F0);
  
  // Background Colors - Dark Theme
  static const Color background = Color(0xFF1A1A1A); // Main dark background
  static const Color backgroundSecondary = Color(0xFF121212); // Darker background
  static const Color surface = Color(0xFF2C2C2E); // Card/Surface color
  static const Color surfaceLight = Color(0xFF3A3A3C); // Lighter surface
  static const Color cardBackground = Color(0xFF2C2C2E); // Card background
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White text
  static const Color textSecondary = Color(0xFF8E8E93); // Gray text
  static const Color textTertiary = Color(0xFF636366); // Darker gray text
  static const Color textHint = Color(0xFF48484A); // Hint text
  static const Color textLight = Color(0xFFFFFFFF); // White text on dark bg
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF2F2F7);
  static const Color lightGray = Color(0xFF48484A);
  static const Color gray = Color(0xFF8E8E93);
  static const Color darkGray = Color(0xFF3A3A3C);
  static const Color black = Color(0xFF000000);
  
  // Status Colors
  static const Color success = Color(0xFF32D74B); // Green
  static const Color warning = Color(0xFFFFD60A); // Yellow
  static const Color error = Color(0xFFFF453A); // Red
  static const Color info = Color(0xFF0A84FF); // Blue
  
  // Order Status Colors
  static const Color pending = Color(0xFFFFD60A); // Yellow
  static const Color processing = Color(0xFF0A84FF); // Blue
  static const Color shipped = Color(0xFF5AC8FA); // Light blue
  static const Color delivered = Color(0xFF32D74B); // Green
  static const Color cancelled = Color(0xFF8E8E93); // Gray
  
  // Account Type Badge Colors
  static const Color goldBadge = Color(0xFFFFD700);
  static const Color silverBadge = Color(0xFFC0C0C0);
  static const Color bronzeBadge = Color(0xFFCD7F32);
  static const Color standardBadge = Color(0xFF8E8E93);
  
  // Shadow Colors
  static const Color shadow = Color(0x33000000); // 20% black
  static const Color shadowLight = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x4D000000); // 30% black
  
  // Overlay Colors
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color overlayLight = Color(0x40000000); // 25% black
  
  // Border Colors
  static const Color border = Color(0xFF3A3A3C);
  static const Color borderLight = Color(0xFF48484A);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF0A84FF), // Electric blue
    Color(0xFF5AC8FA), // Light blue
  ];
  
  static const List<Color> darkGradient = [
    Color(0xFF1A1A1A), // Dark
    Color(0xFF2C2C2E), // Slightly lighter
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFF2C2C2E),
    Color(0xFF3A3A3C),
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFF0A84FF),
    Color(0xFF0066CC),
  ];
}

/// App Theme Data - Dark Theme
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.gray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.darkGray;
        }),
      ),
    );
  }
}

