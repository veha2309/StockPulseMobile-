import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Global flag synchronized by ThemeProvider
  static bool isDark = true;

  // ── Core Palette (getters that adapt to theme mode) ──
  static Color get background => isDark ? const Color(0xFF08080F) : const Color(0xFFF2F5FF);
  static Color get card => isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  static Color get surface => isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  static Color get surfaceContainer => isDark ? const Color(0xFF18182A) : const Color(0xFFECF0FF);
  static Color get accent => isDark ? const Color(0xFF18182E) : const Color(0xFFE4EAFF);

  // ── Brand Color: Mint/Emerald ──
  static const Color primary = Color(0xFF00D09C);
  static const Color primaryLight = Color(0xFF4DDFBE);
  static const Color primaryDark = Color(0xFF00A87D);

  // ── Semantic Colors ──
  static const Color secondary = Color(0xFFFF4D6D);
  static const Color secondaryLight = Color(0xFFFF8099);
  static const Color tertiary = Color(0xFF00D09C);

  // ── Accent Palette (Color Theory: Split-complementary + analogous) ──
  // Electric Violet - triadic opposite of mint
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetLight = Color(0xFFA78BFA);

  // Solar Amber - analogous to coral, for warnings / neutral momentum
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);

  // Sapphire Blue - complementary to amber, for info / indices
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF60A5FA);

  // Indigo - adjacent to violet, for dark cards / section headers
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFF818CF8);

  // Rose Quartz - for SELL side highlights
  static const Color rose = Color(0xFFE11D48);
  static const Color roseLight = Color(0xFFFB7185);

  // Emerald - alternative profit / options green
  static const Color emerald = Color(0xFF10B981);

  // Cyan - for live/real-time indicators
  static const Color cyan = Color(0xFF06B6D4);

  // ── Sector avatar palette (10 distinct harmonious hues cycling) ──
  static const List<Color> sectorColors = [
    Color(0xFF00D09C), // Mint
    Color(0xFF7C3AED), // Violet
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFE11D48), // Rose
    Color(0xFF10B981), // Emerald
    Color(0xFF0EA5E9), // Sky
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
  ];

  static Color sectorColor(int index) => sectorColors[index % sectorColors.length];

  // ── Gradient Definitions ──
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF00E4A8), Color(0xFF00A87D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get violetGradient => const LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get blueGradient => const LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get amberGradient => const LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get roseGradient => const LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get premiumGradient => const LinearGradient(
    colors: [Color(0xFF00E4A8), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardGradient(Color baseColor) => LinearGradient(
    colors: [baseColor.withValues(alpha: 0.15), baseColor.withValues(alpha: 0.04)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text / surface tokens ──
  static Color get onBackground => isDark ? const Color(0xFFF0F4FF) : const Color(0xFF0A0F1E);
  static Color get onSurface => isDark ? const Color(0xFFF0F4FF) : const Color(0xFF0A0F1E);
  static Color get onSurfaceVariant => isDark ? const Color(0xFF8A9BBE) : const Color(0xFF5A6882);
  static Color get onSurfaceMuted => isDark ? const Color(0xFF5A6882) : const Color(0xFF8A9BBE);

  static const Color glowColor = Color(0xFF00D09C);
  static Color get borderColor => isDark ? const Color(0xFF1C1C2E) : const Color(0xFFD8DFF2);
  static Color get borderColorSubtle => isDark ? const Color(0xFF141428) : const Color(0xFFE8EDF8);

  // ── ThemeData Generators ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF08080F),
      primaryColor: primary,
      cardColor: const Color(0xFF13131A),
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: violet,
        surface: const Color(0xFF13131A),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFF1F5F9),
        surfaceTint: primary.withValues(alpha: 0.03),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFFF1F5F9)),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF1F5F9)),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF1F5F9)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
        labelLarge: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: const Color(0xFF94A3B8)),
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
        color: const Color(0xFF13131A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E1E2E), width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFF1F5F9)),
        iconTheme: const IconThemeData(color: primary),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: Color(0xFF94A3B8),
        dividerColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F5FF),
      primaryColor: primary,
      cardColor: const Color(0xFFFFFFFF),
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: violet,
        surface: const Color(0xFFFFFFFF),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF0F172A),
        surfaceTint: primary.withValues(alpha: 0.02),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF0F172A)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
        labelLarge: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: const Color(0xFF64748B)),
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
          side: const BorderSide(color: Color(0xFFDDE1F0), width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        iconTheme: const IconThemeData(color: primary),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: Color(0xFF64748B),
        dividerColor: Colors.transparent,
      ),
    );
  }

  // ── Card decoration factory ──
  static BoxDecoration glassDecoration({
    double opacity = 1.0,
    Color? borderColor,
    double borderWidth = 1.0,
    double radius = 20,
    List<BoxShadow>? shadows,
    Color? accentColor,
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
          color: isDark ? Colors.black.withValues(alpha: 0.30) : Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        if (accentColor != null)
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: 24,
            spreadRadius: -4,
          ),
      ],
    );
  }

  static BoxDecoration glowDecoration({double radius = 20, Color? color}) {
    final glowC = color ?? primary;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: glowC.withValues(alpha: isDark ? 0.22 : 0.10),
          blurRadius: 24,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: glowC.withValues(alpha: isDark ? 0.08 : 0.04),
          blurRadius: 48,
          spreadRadius: 4,
        ),
      ],
    );
  }
}
