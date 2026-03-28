import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Night red theme for low-light operations
/// Preserves night vision while maintaining readability
class NightRedTheme {
  // Night vision red theme colors
  static const Color background = Color(0xFF0A0000);      // Very dark red-black
  static const Color surface = Color(0xFF140000);         // Dark red surface
  static const Color surfaceLight = Color(0xFF1F0000);    // Slightly lighter
  static const Color primary = Color(0xFFFF0000);         // Bright red
  static const Color primaryLight = Color(0xFFFF3333);    // Lighter red
  static const Color accent = Color(0xFFFF4444);          // Neon red
  static const Color accentGlow = Color(0xFFFF6666);        // Glowing red
  static const Color textPrimary = Color(0xFFFFCCCC);     // Light red-white
  static const Color textSecondary = Color(0xFFCC8888);   // Medium red
  static const Color textMuted = Color(0xFF994444);       // Dark red
  static const Color gridLine = Color(0xFF330000);        // Very dark red
  static const Color danger = Color(0xFFFF2222);          // Bright danger red
  static const Color warning = Color(0xFFFF8800);         // Orange warning

  static ThemeData get theme {
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
        error: danger,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.robotoMono(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: accent,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: accent.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
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
        bodyLarge: GoogleFonts.robotoMono(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textSecondary,
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
        labelStyle: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: gridLine,
        thickness: 1,
      ),
    );
  }
  
  /// Dimming overlay for additional night vision protection
  static Widget nightVisionOverlay({required Widget child}) {
    return Stack(
      children: [
        child,
        // Red filter overlay
        IgnorePointer(
          child: Container(
            color: Colors.red.withOpacity(0.05),
          ),
        ),
      ],
    );
  }
  
  /// Brightness slider widget for night mode
  static Widget brightnessControl(ValueChanged<double> onChanged) {
    return StatefulBuilder(
      builder: (context, setState) {
        var brightness = 1.0;
        return Row(
          children: [
            const Icon(Icons.brightness_2, size: 20),
            Expanded(
              child: Slider(
                value: brightness,
                min: 0.3,
                max: 1.0,
                onChanged: (value) {
                  setState(() => brightness = value);
                  onChanged(value);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
