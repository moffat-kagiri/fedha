import 'package:flutter/material.dart';

/// Fedha color palette for theming
class FedhaColors {
  // Primary green shades
  static const Color primaryGreen = Color(0xFF007A39);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF005025);
  
  // Accent colors
  static const Color accentGreen = Color(0xFF66BB6A);
  
  // Semantic colors (status & feedback)
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningOrange = Color(0xFFF57C00);
  static const Color infoBlue = Color(0xFF1976D2);
  
  // Neutral colors for light mode
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color outlineLight = Color(0xFFBDBDBD);
  static const Color hintLight = Color(0xFFBDBDBD);
  
  // Neutral colors for dark mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFECECEC);
  static const Color textSecondaryDark = Color(0xFFAEAEAE);
  static const Color outlineDark = Color(0xFF424242);
  static const Color hintDark = Color(0xFF666666);
}

/// Unified App Theme for Fedha
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: FedhaColors.primaryGreen,
    scaffoldBackgroundColor: FedhaColors.backgroundLight,
    colorScheme: ColorScheme.light(
      primary: FedhaColors.primaryGreen,
      onPrimary: Colors.white,
      surface: FedhaColors.surfaceLight,
      onSurface: FedhaColors.textPrimaryLight,
      background: FedhaColors.backgroundLight,
      onBackground: FedhaColors.textPrimaryLight,
      error: FedhaColors.errorRed,
      onError: Colors.white,
      outline: FedhaColors.outlineLight,
    ),
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FedhaColors.textPrimaryLight),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FedhaColors.textPrimaryLight),
      bodyLarge: TextStyle(fontSize: 16, color: FedhaColors.textPrimaryLight),
      bodyMedium: TextStyle(fontSize: 14, color: FedhaColors.textPrimaryLight),
      bodySmall: TextStyle(fontSize: 12, color: FedhaColors.textSecondaryLight),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: FedhaColors.textSecondaryLight),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FedhaColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.outlineLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.errorRed, width: 2),
      ),
      labelStyle: const TextStyle(color: FedhaColors.textSecondaryLight),
      hintStyle: const TextStyle(color: FedhaColors.hintLight),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FedhaColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FedhaColors.primaryGreen,
        side: const BorderSide(color: FedhaColors.primaryGreen),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: FedhaColors.surfaceLight,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: FedhaColors.primaryGreen,
    scaffoldBackgroundColor: FedhaColors.backgroundDark,
    colorScheme: ColorScheme.dark(
      primary: FedhaColors.primaryGreen,
      onPrimary: Colors.white,
      surface: FedhaColors.surfaceDark,
      onSurface: FedhaColors.textPrimaryDark,
      background: FedhaColors.backgroundDark,
      onBackground: FedhaColors.textPrimaryDark,
      error: FedhaColors.errorRed,
      onError: Colors.white,
      outline: FedhaColors.outlineDark,
    ),
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FedhaColors.textPrimaryDark),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FedhaColors.textPrimaryDark),
      bodyLarge: TextStyle(fontSize: 16, color: FedhaColors.textPrimaryDark),
      bodyMedium: TextStyle(fontSize: 14, color: FedhaColors.textPrimaryDark),
      bodySmall: TextStyle(fontSize: 12, color: FedhaColors.textSecondaryDark),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: FedhaColors.textSecondaryDark),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FedhaColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.outlineDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FedhaColors.errorRed, width: 2),
      ),
      labelStyle: const TextStyle(color: FedhaColors.textSecondaryDark),
      hintStyle: const TextStyle(color: FedhaColors.hintDark),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FedhaColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FedhaColors.primaryGreen,
        side: const BorderSide(color: FedhaColors.primaryGreen),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: FedhaColors.surfaceDark,
    ),
  );
}
