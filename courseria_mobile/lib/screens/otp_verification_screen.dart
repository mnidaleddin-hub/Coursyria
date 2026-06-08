import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';
import '../widgets/shake_widget.dart';
import '../widgets/custom_loading.dart';
import '../widgets/pressable_scale.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();
  late AnimationController _gradientController;
  final RxBool _hasError = false.obs;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    _gradientController.dispose();
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
    _shakeKey.currentState?.shake();
    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: ShakeWidget(
              key: _shakeKey,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),
                          _buildIconHeader(),
                          SizedBox(height: 40.h),
                          _buildHeaderText(),
                          SizedBox(height: 48.h),
                          _buildPinInput(),
                          SizedBox(height: 48.h),
                          _buildVerifyButton(),
                          SizedBox(height: 32.h),
                          _buildResendSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                Color.lerp(const Color(0xFF1A1A2E), const Color(0xFF16213E), _gradientController.value)!,
                Color.lerp(const Color(0xFF16213E), AppColors.primaryNavy.withOpacity(0.1), _gradientController.value)!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildIconHeader() {
    return Obx(() {
      IconData channelIcon;
      Color iconColor;
      switch (_authController.selectedChannel.value) {
        case OtpChannel.whatsapp: 
          channelIcon = Icons.message_rounded; 
          iconColor = const Color(0xFF25D366);
          break;
        case OtpChannel.telegram: 
          channelIcon = Icons.send_rounded; 
          iconColor = const Color(0xFF0088CC);
          break;
        default: 
          channelIcon = Icons.lock_outline_rounded;
          iconColor = AppColors.primaryNavy;
      }
      
      return Container(
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(channelIcon, size: 56.sp, color: iconColor),
      );
    });
  }

  Widget _buildHeaderText() {
    return Obx(() {
      String identifier = _authController.phoneNumber.value;
      String channelName = _authController.selectedChannel.value == OtpChannel.whatsapp ? "واتساب" : "تليغرام";

      return Column(
        children: [
          Text(
            "كود التحقق",
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text.rich(
              TextSpan(
                text: "أدخل الرمز المكون من 6 أرقام المرسل إلى ",
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
                    text: channelName,
                    style: TextStyle(
                      color: _authController.selectedChannel.value == OtpChannel.whatsapp 
                        ? const Color(0xFF25D366) 
                        : const Color(0xFF0088CC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPinInput() {
    final defaultPinTheme = PinTheme(
      width: 52.w,
      height: 62.h,
      textStyle: TextStyle(fontSize: 24.sp, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white10),
      ),
    );

    return Pinput(
          length: 6,
          controller: _pinController,
          focusNode: _pinFocus,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: AppColors.primaryNavy, width: 2),
              boxShadow: [
                BoxShadow(color: AppColors.primaryNavy.withOpacity(0.2), blurRadius: 15),
              ],
            ),
          ),
          errorPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
          ),
          onCompleted: (pin) => _onVerify(),
          keyboardType: TextInputType.text,
          closeKeyboardWhenCompleted: true,
        );
  }

  Widget _buildVerifyButton() {
    return Obx(() => PressableScale(
      onTap: _authController.isLoading.value ? null : _onVerify,
      child: Container(
        width: double.infinity,
        height: 58.h,
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _authController.isLoading.value
            ? const CustomLoadingIndicator(color: Colors.white, size: 24)
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
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
              label: const Text(
                "إعادة إرسال الرمز",
                style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "تغيير رقم الهاتف",
              style: TextStyle(color: Colors.white38, fontSize: 13.sp),
            ),
          ),
        ],
      );
    });
  }
}
