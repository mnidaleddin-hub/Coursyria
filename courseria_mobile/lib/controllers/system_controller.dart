import 'dart:async';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class SystemController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _secureStorage = Get.find<FlutterSecureStorage>();
  // Using a generic storage for preferences (e.g., GetStorage)
  final _storage = Get.find<FlutterSecureStorage>(); // Mocking with secure storage for now or define elsewhere
  
  var isCheckingUpdate = false.obs;
  var updateProgress = 0.0.obs;
  var isDownloading = false.obs;
  var isScreenshotProtected = false.obs;

  // Connectivity State
  final Rx<ConnectivityResult> connectivityStatus = ConnectivityResult.wifi.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Phase 5: Administrative & Preference Options
  var autoDownload = false.obs;
  var useTestServer = false.obs;
  var selectedThemeColor = AppColors.accentTeal.obs;
  var offlinePreference = 'high_quality'.obs; // 'high_quality', 'data_saver'
  var selectedAIModel = AIModel.gemini25FlashLite.obs; // Default to Lite
  var isBlueLightFilterEnabled = false.obs;
  var isGlobalLoading = false.obs;
  var loadingProgress = 0.0.obs;

  // Strategic Deployment Flag
  var isOfflineMode = false.obs; // Force mock data for all new screens

  Future<void> sendWhatsAppOTP(String phoneNumber, String otp) async {
    final chatId = "${phoneNumber.replaceAll('+', '')}@c.us";
    
    final payload = {
      "chatId": chatId,
      "message": "رمز التحقق الخاص بك في كورسيريا هو: $otp"
    };

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _supabase.functions.invoke('send-whatsapp', body: payload);
        debugPrint("[GREEN-API] Attempt ${attempt + 1}: ${response.status}");
        if (response.status == 200) break;
      } catch (e) {
        debugPrint("[GREEN-API] Attempt ${attempt + 1} failed: $e");
        await Future.delayed(Duration(seconds: math.pow(2, attempt).toInt()));
      }
    }
  }

  bool isValidUuid(String id) {
    return RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false)
        .hasMatch(id);
  }

  void toggleScreenshotProtection(bool enable) async {
    if (kIsWeb) return;
    try {
      if (enable) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
      isScreenshotProtected.value = enable;
      _secureStorage.write(key: 'screenshot_protection', value: enable.toString());
    } catch (e) {
      debugPrint("Error toggling screenshot protection: $e");
    }
  }

  bool containsProfanity(String text) {
    final List<String> badWords = [
      'badword1', 'badword2', 'سيء1', 'سيء2'
    ]; // In production, this should be a large list or an API call
    for (var word in badWords) {
      if (text.toLowerCase().contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    _loadOfflineFlag();
    _loadPreferences();
    initConnectivity();
    _loadScreenshotProtection();
  }

  Future<void> _loadScreenshotProtection() async {
    final flag = await _secureStorage.read(key: 'screenshot_protection');
    if (flag == 'true') {
      toggleScreenshotProtection(true);
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> initConnectivity() async {
    final Connectivity connectivity = Connectivity();
    try {
      final List<ConnectivityResult> result = await connectivity.checkConnectivity();
      if (result.isNotEmpty) {
        connectivityStatus.value = result.first;
      }
    } catch (e) {
      debugPrint('❌ Connectivity Check Error: $e');
    }

    _connectivitySubscription?.cancel();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        connectivityStatus.value = results.first;
      }
    });
  }

  Future<void> _loadOfflineFlag() async {
    final flag = await _secureStorage.read(key: 'is_offline_mode');
    if (flag != null) {
      isOfflineMode.value = flag == 'true';
    }
  }

  void toggleOfflineMode(bool val) {
    isOfflineMode.value = val;
    _secureStorage.write(key: 'is_offline_mode', value: val.toString());
    Get.snackbar("وضع النظام", val ? "تم تفعيل وضع التجربة (بدون إنترنت)" : "تم تفعيل وضع الاتصال المباشر",
        backgroundColor: AppColors.accentTeal, colorText: Colors.white);
  }

  void setGlobalLoading(bool loading, {double? progress}) {
    isGlobalLoading.value = loading;
    if (progress != null) loadingProgress.value = progress;
  }

  Future<void> _loadPreferences() async {
    try {
      // Using _secureStorage as a fallback since _storage might not be fully configured
      final themeColor = await _secureStorage.read(key: 'app_theme_color');
      if (themeColor != null) {
        // Get.find<ThemeController>().selectedThemeName.value = themeColor;
      }
      
      final filter = await _secureStorage.read(key: 'blue_light_filter');
      isBlueLightFilterEnabled.value = filter == 'true';
      
      final autoDown = await _secureStorage.read(key: 'auto_download');
      autoDownload.value = autoDown == 'true';
    } catch (e) {
      debugPrint("Error loading preferences: $e");
    }
  }

  void toggleBlueLightFilter(bool value) {
    isBlueLightFilterEnabled.value = value;
    _secureStorage.write(key: 'blue_light_filter', value: value.toString());
  }

  @override
  void onReady() {
    super.onReady();
    if (!kIsWeb) {
      checkForUpdates();
    }
  }

  // --- Performance & Batching ---
  Future<void> runOptimizedTask(Future<void> Function() task) async {
    try {
      isGlobalLoading.value = true;
      await task();
    } catch (e) {
      debugPrint("Optimized Task Error: $e");
    } finally {
      isGlobalLoading.value = false;
    }
  }

  void updateAIModel(AIModel model) {
    selectedAIModel.value = model;
    // GetStorage().write('selected_ai_model', model.index.toString());
  }

  void toggleAutoDownload(bool val) {
    autoDownload.value = val;
    // storage.write('auto_download', val);
  }

  void toggleTestServer(bool val) {
    useTestServer.value = val;
    Get.snackbar("تنبيه السيرفر", val ? "تم التحويل إلى السيرفر التجريبي" : "تم العودة للسيرفر الأساسي", 
        backgroundColor: val ? Colors.amber : AppColors.accentTeal, colorText: Colors.white);
  }

  void updateThemeColor(Color color) {
    selectedThemeColor.value = color;
  }

  void setOfflinePreference(String pref) {
    offlinePreference.value = pref;
  }

  Future<void> checkForUpdates() async {
    try {
      if (kIsWeb) return; // Skip update check on Web
      isCheckingUpdate.value = true;
      
      // 1. Get Current Local Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 2. Fetch Latest Version from Supabase (app_config table)
      final config = await _supabase
          .from('app_config')
          .select()
          .maybeSingle();

      if (config == null) return;

      String latestVersion = config['current_version'] ?? currentVersion;
      int latestBuildNumber = config['latest_build_number'] ?? currentBuildNumber;
      bool forceUpdate = config['force_update'] ?? false;
      String updateUrl = config['update_url'] ?? "";
      String patchUrl = config['patch_url'] ?? "";
      String updateNotes = config['update_notes'] ?? "يتوفر تحديث جديد ومحسّن للمنصة لتوفير بياناتك.";

      // 3. Compare Versions
      if (latestBuildNumber > currentBuildNumber) {
        // Determine if it's a Major or Minor update
        // Logic: If forceUpdate is true -> Full APK
        // Otherwise -> Minor Patch (simulation for now)
        bool isMajor = forceUpdate;

        _showUpdateDialog(
          isMajor: isMajor,
          version: latestVersion,
          notes: updateNotes,
          updateUrl: updateUrl,
          patchUrl: patchUrl,
        );
      }
    } catch (e) {
      debugPrint("Error checking updates: $e");
    } finally {
      isCheckingUpdate.value = false;
    }
  }

  void _showUpdateDialog({
    required bool isMajor,
    required String version,
    required String notes,
    required String updateUrl,
    required String patchUrl,
  }) {
    Get.dialog(
      PopScope(
        canPop: !isMajor, // Prevent closing if forced
        child: AlertDialog(
          backgroundColor: AppColors.secondaryNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: AppColors.accentTeal),
              const SizedBox(width: 10),
              Text(
                isMajor ? "تحديث إجباري" : "تحديث متوفر",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "إصدار جديد: $version",
                style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                notes,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Obx(() => isDownloading.value
                  ? Column(
                      children: [
                        LinearProgressIndicator(
                          value: updateProgress.value,
                          backgroundColor: Colors.white10,
                          color: AppColors.accentTeal,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "جاري التحميل... ${(updateProgress.value * 100).toInt()}%",
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    )
                  : const SizedBox.shrink()),
            ],
          ),
          actions: [
            if (!isMajor)
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("لاحقاً", style: TextStyle(color: Colors.white24)),
              ),
            ElevatedButton(
              onPressed: () => isMajor ? _launchUpdateUrl(updateUrl) : _startMinorUpdate(patchUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isMajor ? "تحديث الآن (APK)" : "تحديث سريع (Patch)",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: !isMajor,
    );
  }

  Future<void> _launchUpdateUrl(String url) async {
    if (url.isEmpty) return;
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _startMinorUpdate(String patchUrl) async {
    isDownloading.value = true;
    updateProgress.value = 0.0;

    // Simulate Minor Patch Download (Future Engine integration)
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      updateProgress.value = i / 100;
    }

    isDownloading.value = false;
    Get.back();
    Get.snackbar(
      "اكتمل التحديث",
      "تم تطبيق التحديث السريع بنجاح. سيتم إعادة تشغيل التطبيق.",
      backgroundColor: AppColors.accentTeal,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // Future: Logic to restart app internally or reload hot-reload-like patches
  }
}
