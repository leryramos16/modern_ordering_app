import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The café palette. Screens use these names, never raw hex codes.
class AppColors {
  static const espresso = Color(0xFF2B1D16); // text, dark buttons
  static const cream = Color(0xFFF7F1E8); // page background
  static const latte = Color(0xFFEADBC8); // soft fills, borders
  static const caramel = Color(0xFFC8742F); // prices, main actions
  static const sage = Color(0xFF7A8B6F); // small accents
  static const muted = Color(0xFF8C7B6F); // secondary text
}

class AppTheme {
  static ThemeData light() {
    final colors = ColorScheme.fromSeed(
      seedColor: AppColors.caramel,
      primary: AppColors.caramel,
      surface: AppColors.cream,
      onSurface: AppColors.espresso,
    );

    // Manrope for everything...
    final base = GoogleFonts.manropeTextTheme().apply(
      bodyColor: AppColors.espresso,
      displayColor: AppColors.espresso,
    );
    // ...and Fraunces for the big titles, for personality.
    final textTheme = base.copyWith(
      headlineMedium: GoogleFonts.fraunces(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.fraunces(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      colorScheme: colors,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.cream,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.caramel, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.espresso,
          foregroundColor: AppColors.cream,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
