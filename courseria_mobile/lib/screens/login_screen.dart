import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:animations/animations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';
import '../widgets/shake_widget.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/custom_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ShakeWidgetState> _shakeKey = GlobalKey<ShakeWidgetState>();
  
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  late AnimationController _gradientController;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  
  int _welcomeIndex = 0;
  Timer? _welcomeTimer;

  final List<String> _welcomeMessages = [
    "مرحباً بك في مستقبل التعليم الذكي ✨",
    "انضم إلى آلاف الطلاب السوريين المبدعين 🇸🇾",
    "تعلم مهارات جديدة تفتح لك أبواب العالم 🌍",
    "كورسيريا.. رفيقك في رحلة النجاح 🚀",
  ];

  @override
  void initState() {
    super.initState();
    
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();

    _welcomeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _welcomeIndex = (_welcomeIndex + 1) % _welcomeMessages.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneFocus.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _gradientController.dispose();
    _logoController.dispose();
    _welcomeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ShakeWidget(
                key: _shakeKey,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),
                      _buildHeader(),
                      SizedBox(height: 40.h),
                      _buildAuthCard(),
                      SizedBox(height: 24.h),
                      _buildSocialSection(),
                      SizedBox(height: 32.h),
                      _buildWelcomeCard(),
                      SizedBox(height: 30.h),
                      _buildBiometricButton(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
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
                Color.lerp(const Color(0xFF16213E), AppColors.primaryNavy.withOpacity(0.2), _gradientController.value)!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ScaleTransition(
          scale: _logoAnimation,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 50.sp, color: AppColors.primaryNavy),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          "كورسيريا",
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildAuthTabToggle(),
          SizedBox(height: 32.h),
          _buildFormFields(),
          SizedBox(height: 24.h),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildAuthTabToggle() {
    return Obx(() => Row(
      children: [
        const Expanded(child: Divider(color: Colors.white10, endIndent: 10)),
        Text(
          _authController.isLoginTab.value ? "تسجيل الدخول" : "إنشاء حساب",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Expanded(child: Divider(color: Colors.white10, indent: 10)),
      ],
    ));
  }

  Widget _buildFormFields() {
    return Obx(() => Column(
      children: [
        if (!_authController.isLoginTab.value) ...[
          _buildInputField(
            label: "الاسم الكامل",
            controller: _authController.nameController,
            focusNode: _nameFocus,
            hint: "أدخل اسمك الثلاثي",
            icon: Icons.person_outline_rounded,
          ),
          SizedBox(height: 20.h),
        ],
        _buildPhoneInputField(),
        SizedBox(height: 20.h),
        _buildChannelSelector(),
      ],
    ));
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
          child: Text(label, style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(hint: hint, icon: icon, focusNode: focusNode),
        ),
      ],
    );
  }

  Widget _buildPhoneInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
          child: Text("رقم الهاتف الدولي", style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
        ),
        IntlPhoneField(
          controller: _authController.phoneController,
          focusNode: _phoneFocus,
          initialCountryCode: 'SY',
          textAlign: TextAlign.left,
          style: const TextStyle(color: Colors.white),
          dropdownTextStyle: const TextStyle(color: Colors.white),
          disableLengthCheck: true, // Allow backdoor and flexible input
          pickerDialogStyle: PickerDialogStyle(
            backgroundColor: const Color(0xFF1A1A2E),
            countryCodeStyle: const TextStyle(color: Colors.white),
            countryNameStyle: const TextStyle(color: Colors.white),
          ),
          decoration: _buildInputDecoration(hint: "9xx xxx xxx", icon: Icons.phone_android_rounded, focusNode: _phoneFocus),
          onChanged: (phone) {
            _authController.countryCode.value = phone.countryCode;
          },
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) {
              return "يرجى إدخال رقم الهاتف";
            }
            
            // Backdoor bypass
            if (phone.number == "987654321") return null;

            // Sanitize local part
            final localPart = phone.number.replaceAll(RegExp(r'[\s\-]'), '');
            
            // RULE 1: Must be exactly 9 digits
            if (localPart.length != 9) {
              return "يجب أن يتكون الرقم من 9 خانات بالضبط";
            }
            
            // RULE 2: Must not start with 0
            if (localPart.startsWith('0')) {
              return "لا يمكن أن يبدأ الرقم بصفر (أدخل الرقم مباشرة بعد الصفر)";
            }

            // International standards: All must be digits
            if (!RegExp(r'^\d{9}$').hasMatch(localPart)) {
              return "رقم الهاتف غير صالح";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildChannelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
          child: Text("اختار القناة", style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
        ),
        Row(
          children: [
            _buildChannelOption(label: "Telegram", channel: OtpChannel.telegram, icon: Icons.send_rounded),
            SizedBox(width: 12.w),
            _buildChannelOption(label: "WhatsApp", channel: OtpChannel.whatsapp, icon: Icons.message_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelOption({required String label, required OtpChannel channel, required IconData icon}) {
    return Expanded(
      child: Obx(() {
        bool isSelected = _authController.selectedChannel.value == channel;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _authController.selectedChannel.value = channel;
              _authController.triggerHaptic(AppHapticFeedback.light);
            },
            borderRadius: BorderRadius.circular(15.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryNavy : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: isSelected ? AppColors.primaryNavy : Colors.white10,
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18.sp, color: isSelected ? Colors.white : Colors.white54),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 14.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon, required FocusNode focusNode}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: AppColors.primaryNavy, size: 20.sp),
      filled: true,
      fillColor: const Color(0xFFF5F5F7).withOpacity(0.05),
      contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
      ),
      // Adding a subtle glow effect on focus
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => PressableScale(
      onTap: _authController.isLoading.value ? null : () async {
        if (_formKey.currentState!.validate()) {
          bool success = await _authController.sendOTP(type: _authController.isLoginTab.value ? "login" : "register");
          if (!success) {
            _shakeKey.currentState?.shake();
          }
        } else {
          _shakeKey.currentState?.shake();
        }
      },
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
                _authController.isLoginTab.value ? "تسجيل الدخول" : "إنشاء حساب",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    ));
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white10)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text("أو المتابعة عبر", style: TextStyle(color: Colors.white38, fontSize: 13.sp)),
            ),
            const Expanded(child: Divider(color: Colors.white10)),
          ],
        ),
        SizedBox(height: 24.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialCircle(icon: Icons.g_mobiledata_rounded, color: const Color(0xFFDB4437), onTap: () => _authController.signInWithGoogle()),
            SizedBox(width: 20.w),
            _buildSocialCircle(icon: Icons.facebook_rounded, color: const Color(0xFF4267B2), onTap: () {}), // Add Facebook logic if available
            SizedBox(width: 20.w),
            _buildSocialCircle(icon: PhosphorIcons.githubLogo(PhosphorIconsStyle.fill), color: Colors.white, onTap: () => _authController.signInWithGitHub()),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialCircle({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: color, size: 32.sp),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primaryNavy.withOpacity(0.2)),
      ),
      child: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Colors.transparent,
            child: child,
          );
        },
        child: Text(
          _welcomeMessages[_welcomeIndex],
          key: ValueKey<int>(_welcomeIndex),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Obx(() => _authController.isLoginTab.value && _authController.isBiometricSupported.value
        ? Center(
            child: InkWell(
              onTap: () => _authController.authenticateWithBiometrics(),
              borderRadius: BorderRadius.circular(50.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint_rounded, color: Colors.white, size: 28.sp),
                    SizedBox(width: 12.w),
                    Text(
                      'تسجيل الدخول بالبصمة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink());
  }
}
