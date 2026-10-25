import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SafeHerColors {
  // Exact Design System Palette from Reference
  static const Color midnightPurple = Color(0xFF21142F);
  static const Color deepPlum = Color(0xFF352047);
  static const Color plumCard = Color(0xFF2B1A3D);
  static const Color primaryRose = Color(0xFFF52F79);
  static const Color brightPink = Color(0xFFFF4F91);
  static const Color palePink = Color(0xFFFFF1F7);
  static const Color softPinkSurface = Color(0xFFFDF6FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF21182F);
  static const Color secondaryText = Color(0xFF756A80);
  static const Color textPrimary = primaryText;
  static const Color textSecondary = secondaryText;
  static const Color mutedText = Color(0xFF988C9F);
  static const Color successGreen = Color(0xFF27B878);
  static const Color successGreenLight = Color(0xFFE8F8F1);
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color emergencyRedLight = Color(0xFFFFEBEE);
  static const Color warningAmber = Color(0xFFFFA000);
  static const Color warningAmberLight = Color(0xFFFFF8E1);
  static const Color border = Color(0xFFEDE2ED);
  static const Color darkBorder = Color(0xFF452D5C);

  // Gradients
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [midnightPurple, deepPlum],
  );

  static const LinearGradient pinkButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryRose, brightPink],
  );

  static const RadialGradient sosRadialGradient = RadialGradient(
    colors: [brightPink, primaryRose],
    center: Alignment(-0.2, -0.2),
    radius: 0.85,
  );
}

class SafeHerTheme {
  // Color Tokens mapped directly on SafeHerTheme for clean cross-component access
  static const Color midnightPurple = SafeHerColors.midnightPurple;
  static const Color deepPlum = SafeHerColors.deepPlum;
  static const Color plumPrimary = Color(0xFF352047);
  static const Color plumLight = Color(0xFF4A2F63);
  static const Color plumCard = SafeHerColors.plumCard;
  static const Color primaryRose = SafeHerColors.primaryRose;
  static const Color brightPink = SafeHerColors.brightPink;
  static const Color roseAccent = SafeHerColors.primaryRose;
  static const Color roseLight = SafeHerColors.palePink;
  static const Color palePink = SafeHerColors.palePink;
  static const Color roseBorder = SafeHerColors.border;
  static const Color softPinkSurface = SafeHerColors.softPinkSurface;
  static const Color surfaceWhite = SafeHerColors.surfaceWhite;
  static const Color offWhite = Color(0xFFFAF7F9);
  static const Color primaryText = SafeHerColors.primaryText;
  static const Color secondaryText = SafeHerColors.secondaryText;
  static const Color textPrimary = SafeHerColors.primaryText;
  static const Color textSecondary = SafeHerColors.secondaryText;
  static const Color textDark = SafeHerColors.primaryText;
  static const Color textMuted = SafeHerColors.secondaryText;
  static const Color successGreen = SafeHerColors.successGreen;
  static const Color safeGreen = SafeHerColors.successGreen;
  static const Color successGreenLight = SafeHerColors.successGreenLight;
  static const Color safeGreenLight = SafeHerColors.successGreenLight;
  static const Color emergencyRed = SafeHerColors.emergencyRed;
  static const Color emergencyRedDark = Color(0xFFC62828);
  static const Color emergencyRedLight = SafeHerColors.emergencyRedLight;
  static const Color warningAmber = SafeHerColors.warningAmber;
  static const Color warningAmberLight = SafeHerColors.warningAmberLight;
  static const Color border = SafeHerColors.border;
  static const Color borderSubtle = SafeHerColors.border;
  static const Color darkBorder = SafeHerColors.darkBorder;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.outfit().fontFamily,
      scaffoldBackgroundColor: SafeHerColors.surfaceWhite,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: SafeHerColors.primaryRose,
        onPrimary: Colors.white,
        primaryContainer: SafeHerColors.palePink,
        onPrimaryContainer: SafeHerColors.primaryRose,
        secondary: SafeHerColors.deepPlum,
        onSecondary: Colors.white,
        secondaryContainer: SafeHerColors.palePink,
        onSecondaryContainer: SafeHerColors.deepPlum,
        tertiary: SafeHerColors.midnightPurple,
        onTertiary: Colors.white,
        error: SafeHerColors.emergencyRed,
        onError: Colors.white,
        errorContainer: SafeHerColors.emergencyRedLight,
        onErrorContainer: SafeHerColors.emergencyRed,
        surface: SafeHerColors.surfaceWhite,
        onSurface: SafeHerColors.primaryText,
        surfaceContainerHighest: SafeHerColors.softPinkSurface,
        outline: SafeHerColors.border,
        shadow: Colors.black.withValues(alpha: 0.06),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: SafeHerColors.primaryText,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: SafeHerColors.primaryText,
          fontWeight: FontWeight.w800,
          fontSize: 26,
        ),
        headlineMedium: TextStyle(
          color: SafeHerColors.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleLarge: TextStyle(
          color: SafeHerColors.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: SafeHerColors.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: SafeHerColors.primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: SafeHerColors.secondaryText,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SafeHerColors.midnightPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: SafeHerColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SafeHerColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SafeHerColors.primaryRose,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SafeHerColors.primaryRose,
          side: const BorderSide(color: SafeHerColors.primaryRose, width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SafeHerColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SafeHerColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: SafeHerColors.primaryRose,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SafeHerColors.emergencyRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SafeHerColors.midnightPurple,
        selectedItemColor: SafeHerColors.primaryRose,
        unselectedItemColor: Color(0xFF8E7E9C),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }
}
