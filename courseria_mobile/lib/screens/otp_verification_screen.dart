import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Auto focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onVerify() async {
    final otp = _pinController.text;
    if (otp.length < 6) return;

    try {
      await _authController.verifyOTP(otp);
    } catch (e) {
      _triggerErrorState();
    }
  }

  void _triggerErrorState() {
    _authController.triggerHaptic(AppHapticFeedback.error);
    _shakeController.forward(from: 0.0);
    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            _buildIconHeader(),
            SizedBox(height: 32.h),
            _buildHeaderText(),
            SizedBox(height: 40.h),
            _buildPinInput(),
            SizedBox(height: 40.h),
            _buildVerifyButton(),
            SizedBox(height: 30.h),
            _buildResendSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconHeader() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.2), width: 2),
      ),
      child: Icon(Icons.mark_email_read_outlined, size: 64.sp, color: AppColors.accentTeal),
    );
  }

  Widget _buildHeaderText() {
    return Obx(() {
      String identifier = _authController.authMethod.value == AuthMethod.email 
          ? _authController.email.value 
          : _authController.phoneNumber.value;
      
      String channelIcon = "";
      Color channelColor = Colors.white;
      switch (_authController.selectedChannel.value) {
        case OtpChannel.whatsapp: 
          channelIcon = "واتساب"; 
          channelColor = Colors.greenAccent;
          break;
        case OtpChannel.telegram: 
          channelIcon = "تليغرام"; 
          channelColor = Colors.blueAccent;
          break;
        case OtpChannel.email: 
          channelIcon = "البريد الإلكتروني"; 
          channelColor = AppColors.accentTeal;
          break;
      }

      return Column(
        children: [
          Text(
            "تحقق من الأمان",
            style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text.rich(
              TextSpan(
                text: "لقد أرسلنا رمز التأكيد إلى ",
                style: TextStyle(fontSize: 15.sp, color: Colors.white60, height: 1.5),
                children: [
                  TextSpan(
                    text: "\n$identifier",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  ),
                  const TextSpan(
                    text: " عبر ",
                    style: TextStyle(color: Colors.white60),
                  ),
                  TextSpan(
                    text: channelIcon,
                    style: TextStyle(color: channelColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.accentTeal),
            label: Text("تعديل الرقم", style: TextStyle(color: AppColors.accentTeal, fontSize: 13.sp)),
          ),
        ],
      );
    });
  }

  Widget _buildPinInput() {
    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 60.h,
      textStyle: TextStyle(fontSize: 22.sp, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
    );

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = Curves.elasticIn.transform(_shakeController.value) * 10.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Pinput(
        length: 6,
        controller: _pinController,
        focusNode: _pinFocus,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            border: Border.all(color: AppColors.accentTeal, width: 2),
            boxShadow: [
              BoxShadow(color: AppColors.accentTeal.withOpacity(0.1), blurRadius: 10),
            ],
          ),
        ),
        errorPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
        ),
        onCompleted: (pin) => _onVerify(),
        keyboardType: TextInputType.text, // Allow special chars for backdoor
        closeKeyboardWhenCompleted: true,
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: _authController.isLoading.value ? null : _onVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          elevation: 5,
        ),
        child: _authController.isLoading.value
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "تحقق الآن",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    ));
  }

  Widget _buildResendSection() {
    return Obx(() {
      final seconds = _authController.timerSeconds.value;
      return Column(
        children: [
          if (seconds > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white38, size: 16),
                SizedBox(width: 8.w),
                Text(
                  "إعادة الإرسال خلال ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: () => _authController.resendOTP(),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accentTeal),
              label: const Text(
                "إعادة إرسال الرمز",
                style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
              ),
            ),
          if (_authController.resendAttempts.value > 0)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                "محاولات إعادة الإرسال: ${_authController.resendAttempts.value}",
                style: TextStyle(color: Colors.white24, fontSize: 12.sp),
              ),
            ),
        ],
      );
    });
  }
}

