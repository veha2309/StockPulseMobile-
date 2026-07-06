import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Global flag synchronized by ThemeProvider
  static bool isDark = true;

  // ── Core Palette (getters that adapt to theme mode) ──
  static Color get background => isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8F9FA);
  static Color get card => isDark ? const Color(0xFF16161A) : const Color(0xFFFFFFFF);
  static Color get surface => isDark ? const Color(0xFF16161A) : const Color(0xFFFFFFFF);
  static Color get surfaceContainer => isDark ? const Color(0xFF1F1F24) : const Color(0xFFFFFFFF);
  static Color get accent => isDark ? const Color(0xFF1E1B4B) : const Color(0xFFE0F2F1);

  // Mint / Teal signature brand color
  static const Color primary = Color(0xFF00D09C);
  static const Color primaryLight = Color(0xFF66E3C4);
  static const Color secondary = Color(0xFFEB5757); // Soft red for loss
  static const Color tertiary = Color(0xFF00D09C); // Keep brand color consistent

  static Color get onBackground => isDark ? const Color(0xFFF8F9FA) : const Color(0xFF1A1D20);
  static Color get onSurface => isDark ? const Color(0xFFF8F9FA) : const Color(0xFF1A1D20);
  static Color get onSurfaceVariant => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6C757D);

  static const Color glowColor = Color(0xFF00D09C);
  static Color get borderColor => isDark ? const Color(0xFF2A2A30) : const Color(0xFFE9ECEF);

  // ── ThemeData Generators ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F12),
      primaryColor: primary,
      cardColor: const Color(0xFF16161A),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: Color(0xFF16161A),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF8F9FA),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFF8F9FA)),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFFF8F9FA)),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF8F9FA)),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF8F9FA)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
        labelLarge: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: const Color(0xFF9CA3AF)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.8),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF16161A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2A30), width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFF8F9FA)),
        iconTheme: const IconThemeData(color: primary),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: Color(0xFF9CA3AF),
        dividerColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      primaryColor: primary,
      cardColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: Color(0xFFFFFFFF),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1D20),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D20)),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D20)),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D20)),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1A1D20)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6C757D)),
        labelLarge: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: const Color(0xFF6C757D)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.8),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE9ECEF), width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D20)),
        iconTheme: const IconThemeData(color: primary),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: Color(0xFF6C757D),
        dividerColor: Colors.transparent,
      ),
    );
  }

  // ── Card decoration factory (Overhauled from glassmorphic to clean card-based) ──
  static BoxDecoration glassDecoration({
    double opacity = 1.0, // Replaced glass opacity with solid card background
    Color? borderColor,
    double borderWidth = 1.0,
    double radius = 20,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppTheme.borderColor,
        width: borderWidth,
      ),
      boxShadow: shadows ?? [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration glowDecoration({double radius = 20}) {
    // Overhauled from aggressive neon glow to a clean, subtle brand outline glow or standard shadow
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: isDark ? 0.08 : 0.03),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
