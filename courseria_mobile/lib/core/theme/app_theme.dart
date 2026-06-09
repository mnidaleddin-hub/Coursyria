import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/constants.dart';

class AppTheme {
  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.notoSansArabicTextTheme(),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: primaryColor.withOpacity(0.8),
        surface: Colors.white,
        onSurface: const Color(0xFF2D3436),
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3436),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Color(0xFF2D3436),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primaryColor.withOpacity(0.1), width: 1),
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.notoSansArabicTextTheme(ThemeData.dark().textTheme),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF0A0E21),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: primaryColor.withOpacity(0.8),
        surface: const Color(0xFF1D1E33),
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1D1E33),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
    );
  }

  // Predefined theme colors
  static const Map<String, Color> themeColors = {
    'Indigo': Color(0xFF3F51B5),
    'Teal': Color(0xFF009688),
    'Amber': Color(0xFFFFA000),
    'Navy': Color(0xFF1A237E),
    'Emerald': Color(0xFF2E7D32),
    'Gold': Color(0xFFFFD700),
    'Sage': Color(0xFF87A96B),
    'ElectricBlue': Color(0xFF007FFF),
    'MidnightPurple': Color(0xFF2E1A47),
  };

  // 1. Coursyria Original
  static ThemeData originalTheme(bool isDark) {
    final primary = themeColors['Navy']!;
    return isDark ? darkTheme(primary) : lightTheme(primary);
  }

  // 2. Light Academia
  static ThemeData academiaTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.notoSansArabicTextTheme(),
      primaryColor: themeColors['Sage'],
      scaffoldBackgroundColor: const Color(0xFFFDF5E6), // Cream
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors['Sage']!,
        primary: themeColors['Sage']!,
        surface: const Color(0xFFFDF5E6),
        onSurface: const Color(0xFF5D4037), // Dark brown text
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 3. Dark Pro (OLED)
  static ThemeData darkProTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.notoSansArabicTextTheme(ThemeData.dark().textTheme),
      primaryColor: themeColors['ElectricBlue'],
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors['ElectricBlue']!,
        primary: themeColors['ElectricBlue']!,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1A1A1A)),
        ),
      ),
    );
  }

  // 4. Vibrant Learn
  static ThemeData vibrantTheme(bool isDark) {
    final primary = isDark ? Colors.pinkAccent : Colors.deepPurpleAccent;
    return (isDark ? darkTheme(primary) : lightTheme(primary)).copyWith(
      scaffoldBackgroundColor: isDark ? const Color(0xFF1A0B2E) : const Color(0xFFF5F0FF),
    );
  }

  // 5. Minimal White
  static ThemeData minimalTheme() {
    return lightTheme(Colors.black).copyWith(
      scaffoldBackgroundColor: Colors.white,
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 6. Midnight Study
  static ThemeData midnightTheme() {
    return darkTheme(themeColors['MidnightPurple']!).copyWith(
      scaffoldBackgroundColor: const Color(0xFF100818),
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors['MidnightPurple']!,
        secondary: themeColors['Teal']!,
      ),
    );
  }
}
