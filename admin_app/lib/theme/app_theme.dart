import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin palette: calm neutrals + the same caramel as the customer app,
/// so both apps feel like one brand.
class AdminColors {
  static const ink = Color(0xFF1F1A17); // main text
  static const canvas = Color(0xFFF6F4F1); // page background
  static const line = Color(0xFFE7E1DA); // borders and dividers
  static const muted = Color(0xFF7A7068); // secondary text
  static const caramel = Color(0xFFC8742F); // brand accent: actions, selection
  static const espresso = Color(0xFF2B1D16); // sidebar background
  static const success = Color(0xFF2E7D4F); // "Available"
}

class AppTheme {
  static ThemeData light() {
    final colors = ColorScheme.fromSeed(
      seedColor: AdminColors.caramel,
      primary: AdminColors.caramel,
      surface: AdminColors.canvas,
      onSurface: AdminColors.ink,
    );
    // Inter is made for screens and numbers: a classic choice for dashboards.
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AdminColors.ink,
      displayColor: AdminColors.ink,
    );

    return ThemeData(
      colorScheme: colors,
      textTheme: textTheme,
      scaffoldBackgroundColor: AdminColors.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: AdminColors.canvas,
        foregroundColor: AdminColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0, // flat card + thin border = modern dashboard look
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AdminColors.line, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AdminColors.caramel.withValues(alpha: 0.15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.caramel, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.caramel,
          minimumSize: const Size(0, 48), // NOT full-width anymore
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
