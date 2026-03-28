import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  dark,
  night,
}

class AppTheme {
  static AppThemeMode _mode = AppThemeMode.dark;
  static bool _highContrast = false;

  static const _darkPalette = _ThemePalette(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    surfaceLight: Color(0xFF2A2A2A),
    primary: Color(0xFF4CAF50),
    primaryLight: Color(0xFF81C784),
    accent: Color(0xFF00E676),
    accentGlow: Color(0xFF00FF00),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    textMuted: Color(0xFF707070),
    danger: Color(0xFFEF5350),
    warning: Color(0xFFFFA726),
    gridLine: Color(0xFF333333),
  );

  static const _nightPalette = _ThemePalette(
    background: Color(0xFF0A0000),
    surface: Color(0xFF140000),
    surfaceLight: Color(0xFF1F0000),
    primary: Color(0xFFFF0000),
    primaryLight: Color(0xFFFF3333),
    accent: Color(0xFFFF4444),
    accentGlow: Color(0xFFFF6666),
    textPrimary: Color(0xFFFFCCCC),
    textSecondary: Color(0xFFCC8888),
    textMuted: Color(0xFF994444),
    danger: Color(0xFFFF2222),
    warning: Color(0xFFFF8800),
    gridLine: Color(0xFF330000),
  );

  static void setTheme({
    required AppThemeMode mode,
    bool highContrast = false,
  }) {
    _mode = mode;
    _highContrast = highContrast;
  }

  static AppThemeMode get mode => _mode;
  static bool get highContrast => _highContrast;

  static ThemeData get darkTheme => _buildTheme(
        _darkPalette,
        highContrast: _highContrast,
      );

  static ThemeData get nightTheme => _buildTheme(
        _nightPalette,
        highContrast: _highContrast,
      );

  static ThemeData get activeTheme => themeFor(
        mode: _mode,
        highContrast: _highContrast,
      );

  static ThemeData themeFor({
    required AppThemeMode mode,
    required bool highContrast,
  }) {
    return _buildTheme(
      mode == AppThemeMode.night ? _nightPalette : _darkPalette,
      highContrast: highContrast,
    );
  }

  static _ThemePalette get _activePalette =>
      _mode == AppThemeMode.night ? _nightPalette : _darkPalette;

  static Color get background => _activePalette.background;
  static Color get surface => _activePalette.surface;
  static Color get surfaceLight => _activePalette.surfaceLight;
  static Color get primary => _activePalette.primary;
  static Color get primaryLight => _activePalette.primaryLight;
  static Color get accent => _activePalette.accent;
  static Color get accentGlow => _activePalette.accentGlow;
  static Color get textPrimary => _activePalette.textPrimary;
  static Color get textSecondary => _highContrast
      ? _activePalette.textPrimary.withOpacity(0.9)
      : _activePalette.textSecondary;
  static Color get textMuted => _highContrast
      ? _activePalette.textPrimary.withOpacity(0.7)
      : _activePalette.textMuted;
  static Color get danger => _activePalette.danger;
  static Color get warning => _activePalette.warning;
  static Color get gridLine => _highContrast
      ? _activePalette.accent.withOpacity(0.45)
      : _activePalette.gridLine;

  static ThemeData _buildTheme(
    _ThemePalette palette, {
    required bool highContrast,
  }) {
    final textSecondaryColor =
        highContrast ? palette.textPrimary.withOpacity(0.9) : palette.textSecondary;
    final textMutedColor =
        highContrast ? palette.textPrimary.withOpacity(0.7) : palette.textMuted;
    final gridColor =
        highContrast ? palette.accent.withOpacity(0.45) : palette.gridLine;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.accent,
        surface: palette.surface,
        background: palette.background,
        error: palette.danger,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: palette.textPrimary,
        onBackground: palette.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.robotoMono(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: palette.accent,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.robotoMono(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: palette.accent,
          letterSpacing: 1.5,
        ),
        displaySmall: GoogleFonts.robotoMono(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: palette.textPrimary,
        ),
        headlineLarge: GoogleFonts.robotoMono(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        headlineMedium: GoogleFonts.robotoMono(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        headlineSmall: GoogleFonts.robotoMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textSecondaryColor,
        ),
        bodyLarge: GoogleFonts.robotoMono(
          fontSize: 16,
          color: palette.textPrimary,
        ),
        bodyMedium: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        bodySmall: GoogleFonts.robotoMono(
          fontSize: 12,
          color: textMutedColor,
        ),
        labelLarge: GoogleFonts.robotoMono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: palette.primary,
          letterSpacing: 1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.robotoMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: palette.primary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: gridColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
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
          foregroundColor: palette.accent,
          side: BorderSide(color: palette.accent, width: 2),
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
          foregroundColor: palette.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: gridColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: gridColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: palette.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        hintStyle: GoogleFonts.robotoMono(
          fontSize: 14,
          color: textMutedColor,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: Colors.black,
        elevation: 8,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.accent,
        unselectedItemColor: textMutedColor,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: gridColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static BoxDecoration solutionCardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: primary.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: accent.withOpacity(0.1),
        blurRadius: 8,
      ),
    ],
  );

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

class _ThemePalette {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color accentGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color danger;
  final Color warning;
  final Color gridLine;

  const _ThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.accentGlow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.danger,
    required this.warning,
    required this.gridLine,
  });
}
