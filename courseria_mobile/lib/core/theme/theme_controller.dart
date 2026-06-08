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

  // Observables
  var themeMode = ThemeMode.system.obs;
  var selectedThemeName = 'Indigo'.obs; // 'Indigo', 'Teal', 'Amber', 'Navy', 'Emerald', 'Custom'
  var customPrimaryColor = const Color(0xFF3F51B5).obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialSettings();
  }

  void _loadInitialSettings() {
    // 1. Load Theme Mode
    String? savedMode = _storage.read(_themeModeKey);
    if (savedMode != null) {
      themeMode.value = ThemeMode.values.firstWhere((e) => e.toString() == savedMode);
    }

    // 2. Load Theme Color Name
    String? savedColorName = _storage.read(_themeColorKey);
    if (savedColorName != null) {
      selectedThemeName.value = savedColorName;
    }

    // 3. Load Custom Color
    int? savedCustomColor = _storage.read(_customColorKey);
    if (savedCustomColor != null) {
      customPrimaryColor.value = Color(savedCustomColor);
    }
    
    // Initial UI apply
    Get.changeThemeMode(themeMode.value);
  }

  // Get current active primary color
  Color get currentPrimaryColor {
    if (selectedThemeName.value == 'Custom') {
      return customPrimaryColor.value;
    }
    return AppTheme.themeColors[selectedThemeName.value] ?? AppTheme.themeColors['Indigo']!;
  }

  void changeThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    _storage.write(_themeModeKey, mode.toString());
    _syncWithSupabase();
  }

  void changeThemeColor(String colorName) {
    selectedThemeName.value = colorName;
    _storage.write(_themeColorKey, colorName);
    
    // Force refresh theme in GetMaterialApp
    _refreshTheme();
    _syncWithSupabase();
  }

  void setCustomColor(Color color) {
    customPrimaryColor.value = color;
    selectedThemeName.value = 'Custom';
    _storage.write(_customColorKey, color.value);
    _storage.write(_themeColorKey, 'Custom');
    
    _refreshTheme();
    _syncWithSupabase();
  }

  void _refreshTheme() {
    // Getx requires a manual trigger sometimes for dynamic theme colors
    Get.changeTheme(isDarkMode ? AppTheme.darkTheme(currentPrimaryColor) : AppTheme.lightTheme(currentPrimaryColor));
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
