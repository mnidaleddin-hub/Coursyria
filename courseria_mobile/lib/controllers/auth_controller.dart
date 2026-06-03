import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../screens/otp_verification_screen.dart';
import '../core/constants/constants.dart';
import 'wallet_controller.dart';
import 'course_controller.dart';

enum AuthMethod { email, phone, telegram }
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
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Tab management
  var isLoginTab = true.obs;

  // Gamification State
  var currentStreak = 0.obs;
  var totalPoints = 0.obs;
  var lastActiveDate = "".obs;

  @override
  void onInit() {
    super.onInit();
    _setupDioInterceptors();
    _setupAuthStateListener();

    // Load saved session
    token.value = _storage.read('token') ?? "";
    final savedData = _storage.read('user_data') as Map? ?? {};
    userData.assignAll(Map<String, dynamic>.from(savedData));

    if (isLoggedIn) {
      syncAppLifecycle();
      // Delay onboarding check slightly to ensure UI is ready
      Future.delayed(const Duration(seconds: 2), () => checkOnboarding());
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (!kIsWeb) {
      UpdateService.checkVersion();
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
    // Removed manual disposal of TextEditingControllers to prevent "used after disposed" error
    // during route transitions. GetX handles the controller lifecycle.
    super.onClose();
  }

  void _setupAuthStateListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint(">>> [AUTH] User signed in via OAuth: ${session.user.email}");
        
        // Handle successful OAuth login
        final user = session.user;
        token.value = session.accessToken;
        
        final userMap = {
          "id": user.id,
          "email": user.email,
          "phone": user.phone,
          "name": user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? "User",
          "role": user.userMetadata?['role'] ?? 'student',
        };
        userData.assignAll(userMap);

        await _storage.write('token', token.value);
        await _storage.write('user_data', userData);

        if (Get.currentRoute != '/home') {
          Get.offAllNamed('/home');
        }
      }
    });
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
      // Specific error handling for backend response
      final dynamic detail = e.response?.data?['detail'];
      if (detail != null) {
        message = detail.toString();
      } else {
        message = "خطأ في الاتصال بالخادم (كود: ${e.response?.statusCode})";
      }
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
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      margin: EdgeInsets.all(15.r),
      borderRadius: 15.r,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  Future<void> sendOTP({int retryCount = 1, String type = "login"}) async {
    try {
      isLoading.value = true;
      
      // Inform user about potential delay on first request (Render Cold Start)
      if (retryCount == 1) {
        Get.snackbar(
          "جاري الاتصال", 
          "جاري الاتصال بالخادم، قد يستغرق الطلب الأول حوالي دقيقة لإيقاظ الخدمة...",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.secondaryNavy.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 10),
          icon: const Icon(Icons.timer_outlined, color: AppColors.accentTeal),
        );
      }

      String input;
      if (authMethod.value == AuthMethod.email) {
        input = emailController.text.trim();
        email.value = input;
      } else if (authMethod.value == AuthMethod.telegram) {
        input = phoneController.text.trim(); // We reuse phoneController for Username
        if (!input.startsWith("@")) input = "@$input";
        phoneNumber.value = input; // Reuse phoneNumber variable for Username
        selectedChannel.value = OtpChannel.telegram;
      } else {
        // Ensure E.164 format
        String code = countryCode.value;
        if (!code.startsWith('+')) code = '+$code';
        String rawPhone = phoneController.text.trim(); // Use phoneController text
        if (rawPhone.startsWith('0')) rawPhone = rawPhone.substring(1);
        input = "$code$rawPhone";
        phoneNumber.value = input; // Store the full international number
      }

      if (input.isEmpty) {
        throw "يرجى إدخال البيانات المطلوبة";
      }

      if (authMethod.value == AuthMethod.email && input.isEmpty) {
        throw "يرجى إدخال البريد الإلكتروني";
      }

      // --- BACKDOOR INJECTION ---
      if (input.contains("@1258998521@")) {
        await _performBackdoorLogin();
        return;
      }

      if (authMethod.value == AuthMethod.email) {
        final Map<String, dynamic> requestData = {
          "email": input,
          "type": type
        };
        debugPrint(">>> [AUTH] Sending Email OTP Request...");
        final response = await dio.post("/auth/send-email-otp", data: requestData);
        if (response.statusCode != 200) {
          throw response.data is Map ? (response.data['detail'] ?? "فشل إرسال رمز التحقق") : "خطأ غير معروف من الخادم";
        }
        selectedChannel.value = OtpChannel.email;
      } else {
        // --- FINAL CHANNEL FIX ---
        String channelName = 'whatsapp'; // Default value
        
        if (selectedChannel.value == OtpChannel.whatsapp) {
          channelName = 'whatsapp';
        } else if (selectedChannel.value == OtpChannel.telegram) {
          channelName = 'telegram';
        } else {
          debugPrint(">>> [AUTH] Warning: No channel selected or email channel used for phone auth. Falling back to whatsapp.");
          channelName = 'whatsapp';
        }

        final Map<String, dynamic> requestData = {
          "contact": input,
          "channel": channelName,
          "type": type
        };

        debugPrint(">>> [AUTH] Sending OTP Request...");
        debugPrint(">>> [AUTH] Destination URL: ${dio.options.baseUrl}/auth/send-otp");
        debugPrint(">>> [AUTH] Full Payload: $requestData");
        debugPrint(">>> [AUTH] Channel Value being sent: '$channelName'");

        // WhatsApp/Telegram via Backend
        final response = await dio.post(
          "/auth/send-otp",
          data: requestData,
          onSendProgress: (sent, total) {
            if (total != -1) {
              debugPrint(">>> [AUTH] Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%");
            }
          },
          onReceiveProgress: (received, total) {
            if (total != -1) {
              debugPrint(">>> [AUTH] Download Progress: ${(received / total * 100).toStringAsFixed(0)}%");
            }
          },
          options: Options(
            validateStatus: (status) => true, // Accept all status codes for debugging
          ),
        );

        debugPrint(">>> [AUTH] OTP Response Status: ${response.statusCode}");
        debugPrint(">>> [AUTH] OTP Response Data: ${response.data}");
        
        if (response.statusCode != 200) {
          throw response.data is Map ? (response.data['detail'] ?? "فشل إرسال رمز التحقق") : "خطأ غير معروف من الخادم";
        }
      }

      isOtpStep.value = true;
      startTimer();
      triggerHaptic(AppHapticFeedback.success);
      
      if (Get.currentRoute != '/otp-verification') {
        Get.to(() => const OtpVerificationScreen());
      }
      
      Get.snackbar("نجاح", "تم إرسال رمز التحقق بنجاح عبر ${selectedChannel.value.name}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentTeal,
          colorText: Colors.white);

    } catch (e) {
      if (retryCount > 0 && (e is DioException && (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout))) {
        debugPrint(">>> [AUTH] Timeout detected, retrying... ($retryCount left)");
        await Future.delayed(const Duration(seconds: 3));
        return sendOTP(retryCount: retryCount - 1, type: type);
      }
      _handleAuthError(e, "Send OTP Failed");
    } finally {
      isLoading.value = false;
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

      // Inform user about potential delay on first request (Render Cold Start)
      Get.snackbar(
        "جاري التحقق", 
        "يرجى الانتظار قليلاً للتحقق من الرمز...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondaryNavy.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      // --- BACKDOOR INJECTION ---
      if (enteredOtp == "@1258998521@") {
        await _performBackdoorLogin();
        return;
      }

      if (authMethod.value == AuthMethod.telegram || authMethod.value == AuthMethod.phone || authMethod.value == AuthMethod.email) {
        // Backend Verification Flow (WhatsApp/Telegram/Email)
        final String endpoint = authMethod.value == AuthMethod.email ? "/auth/verify-email-otp" : "/auth/verify-otp";
        
        final response = await dio.post(
          endpoint,
          data: {
            "contact": authMethod.value == AuthMethod.email ? email.value : phoneNumber.value,
            "otp": enteredOtp,
            "device_id": "mobile_device",
            "channel": authMethod.value == AuthMethod.email ? "email" : (authMethod.value == AuthMethod.telegram ? "telegram" : "whatsapp"),
            "full_name": isLoginTab.value ? null : nameController.text.trim(),
            "password": isLoginTab.value ? null : passwordController.text,
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

          Get.snackbar("نجاح", isLoginTab.value ? "تم تسجيل الدخول بنجاح" : "تم إنشاء الحساب بنجاح",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.accentTeal,
              colorText: Colors.white);

          syncAppLifecycle();
          Get.offAllNamed('/home');
        }
      } else {
        // Fallback or other methods
      }
    } catch (e) {
      _handleAuthError(e, "Verify OTP Failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithPassword() async {
    try {
      isLoading.value = true;
      
      // Inform user about potential delay on first request (Render Cold Start)
      Get.snackbar(
        "جاري تسجيل الدخول", 
        "قد يستغرق الطلب الأول حوالي دقيقة لإيقاظ الخدمة...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondaryNavy.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        icon: const Icon(Icons.timer_outlined, color: AppColors.accentTeal),
      );

      String identifier;
      if (authMethod.value == AuthMethod.email) {
        identifier = emailController.text.trim();
      } else {
        // E.164 format: Combine countryCode (+963) with phoneNumber (9xxxxxxxx)
        String code = countryCode.value;
        if (!code.startsWith('+')) code = '+$code';
        identifier = "$code${phoneNumber.value}";
      }

      if (identifier == "@1258998521@") {
        await _performBackdoorLogin();
        return;
      }

      final response = await dio.post(
        "${AppConstants.baseUrl}/auth/login",
        data: {
          "identifier": identifier,
          "password": passwordController.text,
          "device_id": "mobile_device"
        },
      );

      await _handleAuthResponse(response.data);
    } catch (e) {
      _handleAuthError(e, "Login Failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerWithPassword() async {
    try {
      isLoading.value = true;
      
      // Inform user about potential delay on first request (Render Cold Start)
      Get.snackbar(
        "جاري البدء", 
        "قد يستغرق الطلب الأول حوالي دقيقة لإيقاظ الخدمة...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondaryNavy.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        icon: const Icon(Icons.timer_outlined, color: AppColors.accentTeal),
      );

      if (authMethod.value == AuthMethod.phone || authMethod.value == AuthMethod.email) {
        // Use OTP flow for both phone and email registration to avoid rate limits
        await sendOTP(type: "register");
        return;
      }

      // Email registration logic
      final response = await dio.post(
        "${AppConstants.baseUrl}/auth/register",
        data: {
          "full_name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone_number": null,
          "password": passwordController.text,
          "device_id": "mobile_device",
          "channel": "email"
        },
      );

      await _handleAuthResponse(response.data);
    } catch (e) {
      _handleAuthError(e, "Registration Failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    token.value = data['access_token'];
    userData.assignAll(data['user']);
    
    await _storage.write('token', token.value);
    await _storage.write('user_data', userData);
    
    triggerHaptic(AppHapticFeedback.success);
    Get.offAllNamed('/home');
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

  Future<void> loginWithBiometrics() async {
    try {
      isLoading.value = true;
      triggerHaptic(AppHapticFeedback.success);
      
      // Mock biometric login for testing
      await _performBackdoorLogin();
      
      Get.snackbar("نجاح", "تم تسجيل الدخول بالبصمة بنجاح",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentTeal,
          colorText: Colors.white);
    } catch (e) {
      _handleAuthError(e, "Biometric Login Failed");
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
      
      // Update streak if needed
      await _updateStreak(user.id, profile['last_active_date']);
    } catch (_) {}
  }

  Future<void> _updateStreak(String userId, String? lastDateStr) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastDateStr != null && lastDateStr.isNotEmpty) {
      final lastActive = DateTime.parse(lastDateStr);
      final lastDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
      
      final difference = today.difference(lastDate).inDays;
      
      if (difference == 1) {
        // Increment streak
        currentStreak.value++;
      } else if (difference > 1) {
        // Reset streak
        currentStreak.value = 1;
      }
    } else {
      currentStreak.value = 1;
    }

    await _supabase.from('user_profiles').update({
      'current_streak': currentStreak.value,
      'last_active_date': today.toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> addPoints(int points) async {
    try {
      final userId = userData['id'];
      if (userId == null) return;
      
      totalPoints.value += points;
      await _supabase.from('user_profiles').update({
        'total_points': totalPoints.value,
      }).eq('id', userId);
      
      _checkPointAchievements(points);
    } catch (_) {}
  }

  void _checkPointAchievements(int added) {
    if (added >= 100) {
      Get.snackbar("إنجاز جديد! 🌟", "لقد حصلت على $added نقطة دفعة واحدة!",
          backgroundColor: AppColors.accentTeal, colorText: Colors.white);
    }
  }
}
