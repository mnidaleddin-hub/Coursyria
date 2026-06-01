import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../screens/update_screen.dart';
import 'dart:io' as io;

class UpdateService {
  static final Dio _dio = Get.find<Dio>();

  static Future<void> checkVersion() async {
    try {
      // 0. Only run on Android for APK updates, skip on Web
      if (kIsWeb) return;
      
      // Safe platform check
      bool isAndroid = false;
      try {
        isAndroid = !kIsWeb && io.Platform.isAndroid;
      } catch (_) {}
      
      if (!isAndroid) return;

      // 1. Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Fetch version info from backend
      final response = await _dio.get('/system/version-check');
      final data = response.data;

      String latestVersion = data['latest_version'];
      String minRequiredVersion = data['min_required_version'];
      String downloadUrl = data['download_url'];
      String releaseNotes = data['release_notes'];
      bool isMandatory = data['is_mandatory'] ?? false;

      // 3. Compare versions
      bool needsUpdate = _isVersionLower(currentVersion, latestVersion);
      bool isForced = _isVersionLower(currentVersion, minRequiredVersion) || isMandatory;

      if (needsUpdate || isForced) {
        // Navigate to UpdateScreen
        Get.to(() => UpdateScreen(
              downloadUrl: downloadUrl,
              releaseNotes: releaseNotes,
              isMandatory: isForced,
            ));
      }
    } catch (e) {
      debugPrint("Error checking version: $e");
      // Don't block the app flow if version check fails due to network issues
    }
  }

  static bool _isVersionLower(String current, String target) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> targetParts = target.split('.').map(int.parse).toList();

      for (int i = 0; i < targetParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (currentPart < targetParts[i]) return true;
        if (currentPart > targetParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
