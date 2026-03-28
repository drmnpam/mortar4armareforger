import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Military Dark Theme Colors
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color primary = Color(0xFF4CAF50); // Military Green
  static const Color primaryLight = Color(0xFF81C784);
  static const Color accent = Color(0xFF00E676); // Neon Green
  static const Color accentGlow = Color(0xFF00FF00);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF707070);
  static const Color danger = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color gridLine = Color(0xFF333333);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.robotoMono(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: accent,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.robotoMono(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: accent,
          letterSpacing: 1.5,
        ),
        displaySmall: GoogleFonts.robotoMono(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.robotoMono(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.robotoMono(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.robotoMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.robotoMono(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.robotoMono(
          fontSize: 12,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.robotoMono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.robotoMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: gridLine, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: gridLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: gridLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textSecondary,
        ),
        hintStyle: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textMuted,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 8,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: gridLine,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Custom card decoration for firing solution display
  static BoxDecoration solutionCardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: primary.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: accent.withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  // Glowing accent text style
  static TextStyle get glowingAccentText => GoogleFonts.robotoMono(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: accent,
    shadows: [
      Shadow(
        color: accent.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(0, 0),
      ),
    ],
  );
}
