import 'package:flutter/material.dart';

/// Theme Configuration for PourRice App
///
/// Professional vegan green aesthetic with Material Design 3.
/// Key color theory concepts:
/// - Green evokes nature, health, and sustainability (perfect for vegan theme)
/// - We use various shades of green for depth and visual interest
/// - Light theme: Fresh, bright greens with white backgrounds
/// - Dark theme: Deep, rich greens with dark backgrounds
/// - All colors pass WCAG accessibility standards for contrast

/// Light Theme Colors
class LightThemeColors {
  static const Color primary = Color(0xFF2E7D32);      // Forest green
  static const Color secondary = Color(0xFF66BB6A);    // Light green
  static const Color surface = Color(0xFFF1F8E9);      // Very light green tint
  static const Color background = Colors.white;        // Pure white for main content
}

/// Dark Theme Colors
class DarkThemeColors {
  static const Color primary = Color(0xFF66BB6A);      // Light green (primary in dark)
  static const Color secondary = Color(0xFF81C784);    // Lighter green
  static const Color surface = Color(0xFF1B5E20);      // Dark forest green
  static const Color background = Color(0xFF0D1F0E);   // Very dark green-black
}

/// App Theme Builder
///
/// Provides consistent theme configuration for both light and dark modes.
class AppTheme {
  /// Build Light Theme
  ///
  /// Fresh, bright greens with white backgrounds for a clean, modern look.
  static ThemeData buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: LightThemeColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LightThemeColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: LightThemeColors.primary,
        secondary: LightThemeColors.secondary,
        surface: LightThemeColors.surface,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LightThemeColors.surface,
        foregroundColor: LightThemeColors.primary,
        elevation: 1,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LightThemeColors.surface,
        selectedItemColor: LightThemeColors.primary,
        unselectedItemColor: Colors.black54,
      ),
      cardTheme: CardThemeData(
        color: LightThemeColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightThemeColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LightThemeColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Build Dark Theme
  ///
  /// Deep, rich greens with dark backgrounds while maintaining brand identity.
  static ThemeData buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DarkThemeColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DarkThemeColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: DarkThemeColors.primary,
        secondary: DarkThemeColors.secondary,
        surface: DarkThemeColors.surface,
        onPrimary: Colors.black87,
        onSurface: Colors.white70,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DarkThemeColors.surface,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DarkThemeColors.surface,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
      ),
      cardTheme: CardThemeData(
        color: DarkThemeColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkThemeColors.primary,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DarkThemeColors.primary,
        foregroundColor: Colors.black87,
      ),
    );
  }
}
