import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final _supabase = Supabase.instance.client;
  
  // Storage Keys
  final _themeModeKey = 'themeMode';
  final _themeColorKey = 'selectedThemeColor';
  final _customColorKey = 'customPrimaryColor';
  final _fontSizeFactorKey = 'fontSizeFactor';
  final _selectedFontKey = 'selectedFont';
  final _emergencyNightModeKey = 'emergencyNightMode';

  // Observables
  var themeMode = ThemeMode.system.obs;
  var selectedThemeName = 'Original'.obs; 
  var customPrimaryColor = const Color(0xFF3F51B5).obs;
  
  // Feature 184: Custom Fonts
  var selectedFontFamily = 'Amiri'.obs; // Amiri, Tahoma, Cairo, etc.
  
  // Feature 186: Text Scaling
  var fontSizeFactor = 1.0.obs; // 1.0 to 2.0
  
  // Feature 185: Emergency Night Mode
  var isEmergencyNightMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeSettings();
  }

  void _loadThemeSettings() {
    fontSizeFactor.value = _storage.read(_fontSizeFactorKey) ?? 1.0;
    selectedFontFamily.value = _storage.read(_selectedFontKey) ?? 'Amiri';
    isEmergencyNightMode.value = _storage.read(_emergencyNightModeKey) ?? false;
  }

  void updateFontSize(double factor) {
    fontSizeFactor.value = factor;
    _storage.write(_fontSizeFactorKey, factor);
  }

  void updateFontFamily(String font) {
    selectedFontFamily.value = font;
    _storage.write(_selectedFontKey, font);
    _refreshTheme();
  }

  void toggleEmergencyNightMode(bool value) {
    isEmergencyNightMode.value = value;
    _storage.write(_emergencyNightModeKey, value);
  }

  ThemeData get currentTheme {
    bool isDark = themeMode.value == ThemeMode.dark || (themeMode.value == ThemeMode.system && Get.isPlatformDarkMode);
    
    switch (selectedThemeName.value) {
      case 'Original':
        return AppTheme.originalTheme(isDark);
      case 'Academia':
        return isDark ? AppTheme.darkTheme(AppTheme.themeColors['Sage']!) : AppTheme.academiaTheme();
      case 'DarkPro':
        return isDark ? AppTheme.darkProTheme() : AppTheme.minimalTheme();
      case 'Vibrant':
        return AppTheme.vibrantTheme(isDark);
      case 'Minimal':
        return isDark ? AppTheme.darkProTheme() : AppTheme.minimalTheme();
      case 'Midnight':
        return AppTheme.midnightTheme();
      default:
        return isDark ? AppTheme.darkTheme(currentPrimaryColor) : AppTheme.lightTheme(currentPrimaryColor);
    }
  }

  void _refreshTheme() {
    Get.changeTheme(currentTheme);
  }

  void changeThemeColor(String colorName) {
    selectedThemeName.value = colorName;
    _storage.write(_themeColorKey, colorName);
    
    // Getx requires a manual trigger for dynamic theme changes
    Get.changeTheme(currentTheme);
    _syncWithSupabase();
  }

  bool get isDarkMode {
    if (themeMode.value == ThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return themeMode.value == ThemeMode.dark;
  }

  Future<void> _syncWithSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('user_profiles').update({
          'app_theme_mode': themeMode.value.toString().split('.').last,
          'app_theme_color': selectedThemeName.value,
          'app_custom_color': customPrimaryColor.value.value.toString(),
        }).eq('id', user.id);
      } catch (e) {
        debugPrint('Error syncing theme with Supabase: $e');
      }
    }
  }
}
