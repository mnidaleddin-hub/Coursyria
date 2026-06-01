import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AppTheme {
  static ThemeData theme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: kIsWeb ? 'sans-serif' : null, // Use system font on web to avoid Roboto fetch errors
      primaryColor: AppColors.primaryNavy,
      scaffoldBackgroundColor: AppColors.bgCanvasStart,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryNavy,
        primary: AppColors.primaryNavy,
        secondary: accentColor,
        surface: AppColors.surfaceWhite,
        background: AppColors.bgCanvasStart,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.header.copyWith(fontSize: 28),
        headlineMedium: AppTextStyles.header.copyWith(fontSize: 22),
        bodyLarge: AppTextStyles.body.copyWith(fontSize: 16),
        bodyMedium: AppTextStyles.body.copyWith(fontSize: 14),
        bodySmall: AppTextStyles.muted.copyWith(fontSize: 12),
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

  // For backward compatibility or default
  static ThemeData get lightTheme => theme(AppColors.accentTeal);
}
