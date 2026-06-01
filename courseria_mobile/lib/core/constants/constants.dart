import 'package:flutter/material.dart';

class AppColors {
  // Corporate Identity: Modern Indigo
  static const Color primaryNavy = Color(0xFF6C63FF);
  static const Color secondaryNavy = Color(0xFF5146C7);

  // Dynamic Accent: Amber/Gold for achievements
  static const Color accentTeal = Color(0xFFFFD700);
  static const Color lightTeal = Color(0xFFFFE14D);

  // Background Canvas
  static const Color bgCanvasStart = Color(0xFFF0F2F5);
  static const Color bgCanvasEnd = Color(0xFFE4E7EB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Typography & Status
  static const Color textMain = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
  static const Color statusLocked = Color(0xFFB2BEC3);
  static const Color errorRed = Color(0xFFD63031);
  static const Color successGreen = Color(0xFF00B894);

  // Backward compatibility aliases (to prevent immediate crashes)
  static const Color primaryBlue = primaryNavy;
  static const Color secondaryBlue = secondaryNavy;
  static const Color accentOrange = accentTeal;
  static const Color backgroundWhite = surfaceWhite;
  static const Color surfaceGrey = bgCanvasStart;
  static const Color textBlack = textMain;
  static const Color textGrey = textMuted;
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
}

enum AIModel {
  llama3_3_70b,
  gemini2_5_flash,
  gemini2_5_flash_lite,
  qwen3_next,
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
    AIModel.gemini2_5_flash: {
      'id': 'google/gemini-2.0-flash-001', // Updated to stable flash ID
      'name': 'Gemini 2.5 Flash',
      'description': 'الأسرع والأدق عربياً',
    },
    AIModel.gemini2_5_flash_lite: {
      'id': 'google/gemini-flash-1.5-8b:free', // Using the free 8b as lite
      'name': 'Gemini Lite',
      'description': 'الأوفر في استهلاك البيانات',
    },
    AIModel.qwen3_next: {
      'id': 'qwen/qwen3-next-80b-a3b-instruct:free',
      'name': 'Qwen 3 Next',
      'description': 'ممتاز للمواد العلمية',
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
  static const String openRouterKey = "YOUR_OPENROUTER_KEY_HERE";
  static const String aiModel = "google/gemini-flash-1.5-8b:free";
}
