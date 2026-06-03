import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AppTheme {
  static ThemeData lightTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: kIsWeb ? 'sans-serif' : null,
      primaryColor: AppColors.primaryNavy,
      scaffoldBackgroundColor: AppColors.bgCanvasStart,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryNavy,
        primary: AppColors.primaryNavy,
        secondary: accentColor,
        surface: AppColors.surfaceWhite,
        background: AppColors.bgCanvasStart,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 18),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentColor.withOpacity(0.1), width: 1),
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: kIsWeb ? 'sans-serif' : null,
      primaryColor: AppColors.primaryNavy,
      scaffoldBackgroundColor: AppColors.darkBgStart,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryNavy,
        primary: AppColors.primaryNavy,
        secondary: accentColor,
        surface: AppColors.darkSurface,
        background: AppColors.darkBgStart,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBgEnd,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 18),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
    );
  }
}
