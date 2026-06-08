import 'package:flutter/material.dart';

class AppColors {
  // Global Educational Palette (Material 3 Inspired)
  static const Color primaryNavy = Color(0xFF3F51B5);   // Trust Indigo
  static const Color secondaryNavy = Color(0xFF009688); // Education Teal
  static const Color accentTeal = Color(0xFF009688);    // Same as secondary
  static const Color goldAchievement = Color(0xFFFFD700); // Achievement Gold
  static const Color softPink = Color(0xFFFF6584);
  
  // Dark Mode Palette (OLED optimized)
  static const Color darkBg = Color(0xFF0A0E21);
  static const Color darkSurface = Color(0xFF1D1E33);
  static const Color darkCard = Color(0xFF242745);

  // Status Colors
  static const Color errorRed = Color(0xFFEF5350);
  static const Color successGreen = Color(0xFF66BB6A);
  static const Color warningOrange = Color(0xFFFFA726);

  // Background Canvas
  static const Color bgCanvasStart = Color(0xFFF8F9FA);
  static const Color bgCanvasEnd = Color(0xFFE9ECEF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryNavy, Color(0xFF5C6BC0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAchievement, Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const Color textMain = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color statusLocked = Color(0xFFB2BEC3);

  // Missing Constants for Backward Compatibility & UI
  static const Color darkBgStart = Color(0xFF0A0A14);
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color textBlack = Color(0xFF111827);
  static const Color surfaceGrey = Color(0xFFF3F4F6);
  static const Color lightTeal = Color(0xFFB2DFDB);
  static const Color primaryBlue = primaryNavy;
  static const Color secondaryBlue = secondaryNavy;
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color accentOrange = Color(0xFFFF9800);
}

class AppTextStyles {
  static const double arabicHeight = 1.4;

  static TextStyle header = const TextStyle(
    color: AppColors.textMain,
    fontWeight: FontWeight.w800,
    height: arabicHeight,
  );

  static TextStyle body = const TextStyle(
    color: AppColors.textMain,
    fontWeight: FontWeight.w400,
    height: arabicHeight,
  );

  static TextStyle muted = const TextStyle(
    color: AppColors.textMuted,
    fontWeight: FontWeight.w400,
    height: arabicHeight,
  );

  static TextStyle button = const TextStyle(
    color: AppColors.textWhite,
    fontWeight: FontWeight.bold,
    height: arabicHeight,
  );
}

enum AIModel {
  llama3_3_70b,
  gemini25Flash,
  gemini25FlashLite,
  qwen3Next,
}

class AppConstants {
  static const String appName = "Courseria";
  static const String arabicAppName = "كورسيريا";

  // AI Model Details
  static const Map<AIModel, Map<String, String>> aiModels = {
    AIModel.llama3_3_70b: {
      'id': 'meta-llama/llama-3.3-70b-instruct:free',
      'name': 'Llama 3.3',
      'description': 'الأقوى في التفكير والتحليل',
    },
    AIModel.gemini25Flash: {
      'id': 'google/gemini-2.0-flash-001', // Updated to stable flash ID
      'name': 'Gemini 2.5 Flash',
      'description': 'الأسرع والأدق عربياً',
    },
    AIModel.gemini25FlashLite: {
      'id': 'google/gemini-2.0-flash-lite-preview-02-05',
      'name': 'Gemini Lite',
      'description': 'اقتصادي وسريع جداً',
    },
    AIModel.qwen3Next: {
      'id': 'qwen/qwen-2.5-72b-instruct',
      'name': 'Qwen 3 Next',
      'description': 'متخصص في الترجمة والشرح',
    },
  };

  // API & Supabase
  static const String supabaseUrl = "https://kldtrfmhquepsyiflnut.supabase.co";
  static const String supabaseAnonKey =
      "sb_publishable_LJG0_5Q4mXb7mFdTUgGQ0A_vDQTt9m5";

  // Backend Base URL Configuration
  static const bool isProduction = true; // Toggle this for development/production
  
  static String get baseUrl => isProduction 
      ? "https://coursyria-api.onrender.com" 
      : "http://localhost:8000";

  // Green-API Configurations
  // WhatsApp
  static const String waApiUrl = "https://7107.api.greenapi.com";
  static const String waIdInstance = "7107621915";
  static const String waTokenInstance = "671698dabcf043ed84bc4726b52d242f6035b4f0cc3b4a4f81";

  // Telegram
  static const String tgApiUrl = "https://4100.api.green-api.com";
  static const String tgIdInstance = "4100621926";
  static const String tgTokenInstance = "a09261acfb484f7788db3fe9ec7d41cc55db1340d07048a5a6";

  // AI & OpenRouter
  static const String openRouterUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String openRouterKey = String.fromEnvironment('OPENROUTER_KEY', defaultValue: "YOUR_OPENROUTER_KEY_HERE");
  static const String aiModel = "google/gemini-flash-1.5-8b:free";

  // Google Sign-In Client IDs
  // NOTE: The Web Client ID is REQUIRED for Supabase verification
  static const String googleWebClientId = "231543697418-81ftke5kmefopbg800la4utssncf0204.apps.googleusercontent.com";
  static const String googleAndroidClientId = "231543697418-tpbnl1r2r36v21ftbrkc8n5suppf5b9l.apps.googleusercontent.com";
  static const String googleIosClientId = "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com";

  static String formatTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()} سنة";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} شهر";
    if (diff.inDays > 7) return "${(diff.inDays / 7).floor()} أسبوع";
    if (diff.inDays > 0) return "${diff.inDays} يوم";
    if (diff.inHours > 0) return "${diff.inHours} ساعة";
    if (diff.inMinutes > 0) return "${diff.inMinutes} دقيقة";
    return "الآن";
  }
}
