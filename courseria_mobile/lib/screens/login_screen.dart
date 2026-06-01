import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:animations/animations.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onMethodChange(AuthMethod method) {
    if (_authController.authMethod.value == method) return;
    _authController.authMethod.value = method;
    _authController.triggerHaptic(AppHapticFeedback.light);
  }

  void _onTabChange(bool isLogin) {
    if (_authController.isLoginTab.value == isLogin) return;
    _authController.isLoginTab.value = isLogin;
    _authController.triggerHaptic(AppHapticFeedback.medium);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),
                _buildHeader(),
                SizedBox(height: 30.h),
                _buildAuthTabToggle(),
                SizedBox(height: 24.h),
                _buildMethodToggle(),
                SizedBox(height: 24.h),
                _buildAnimatedSwitcher(),
                SizedBox(height: 24.h),
                _buildSocialSection(),
                SizedBox(height: 32.h),
                _buildFooter(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.secondaryNavy,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withOpacity(0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.school_rounded, size: 40, color: AppColors.accentTeal),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "كورسيريا",
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTabToggle() {
    return Obx(() => Container(
      height: 55.h,
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            label: "تسجيل الدخول",
            isSelected: _authController.isLoginTab.value,
            onTap: () => _onTabChange(true),
            activeColor: AppColors.accentTeal,
          ),
          _buildToggleItem(
            label: "إنشاء حساب",
            isSelected: !_authController.isLoginTab.value,
            onTap: () => _onTabChange(false),
            activeColor: AppColors.accentTeal,
          ),
        ],
      ),
    ));
  }

  Widget _buildMethodToggle() {
    return Obx(() => Container(
      height: 45.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            label: "البريد الإلكتروني",
            isSelected: _authController.authMethod.value == AuthMethod.email,
            onTap: () => _onMethodChange(AuthMethod.email),
            fontSize: 12.sp,
          ),
          _buildToggleItem(
            label: "رقم الهاتف",
            isSelected: _authController.authMethod.value == AuthMethod.phone,
            onTap: () => _onMethodChange(AuthMethod.phone),
            fontSize: 12.sp,
          ),
        ],
      ),
    ));
  }

  Widget _buildToggleItem({
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap,
    Color? activeColor,
    double? fontSize,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? (activeColor ?? AppColors.accentTeal.withOpacity(0.8)) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize ?? 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSwitcher() {
    return Obx(() => PageTransitionSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: _authController.authMethod.value == AuthMethod.email 
          ? _buildEmailForm() 
          : _buildPhoneForm(),
    ));
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'),
      children: [
        if (!_authController.isLoginTab.value) ...[
          _buildInputField(
            label: "الاسم الكامل",
            controller: _authController.nameController,
            focusNode: _nameFocus,
            hint: "أدخل اسمك الثلاثي",
            icon: Icons.person_outline_rounded,
            validator: (val) => (val?.length ?? 0) < 3 ? "الاسم قصير جداً" : null,
          ),
          SizedBox(height: 16.h),
        ],
        _buildInputField(
          label: "البريد الإلكتروني",
          controller: _authController.emailController,
          focusNode: _emailFocus,
          hint: "example@gmail.com",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == "@1258998521@") return null;
            return GetUtils.isEmail(val ?? "") ? null : "بريد إلكتروني غير صالح";
          },
        ),
        SizedBox(height: 16.h),
        _buildInputField(
          label: "كلمة المرور",
          controller: _authController.passwordController,
          focusNode: _passwordFocus,
          hint: "••••••••",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          validator: (val) => (val?.length ?? 0) < 6 ? "كلمة المرور ضعيفة" : null,
        ),
        if (!_authController.isLoginTab.value) ...[
          SizedBox(height: 16.h),
          _buildInputField(
            label: "تأكيد كلمة المرور",
            controller: _authController.confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            hint: "••••••••",
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            validator: (val) => val != _authController.passwordController.text ? "كلمات المرور غير متطابقة" : null,
          ),
        ],
        SizedBox(height: 32.h),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      key: const ValueKey('phone_form'),
      children: [
        if (!_authController.isLoginTab.value) ...[
          _buildInputField(
            label: "الاسم الكامل",
            controller: _authController.nameController,
            focusNode: _nameFocus,
            hint: "أدخل اسمك الثلاثي",
            icon: Icons.person_outline_rounded,
          ),
          SizedBox(height: 16.h),
        ],
        _buildPhoneInputField(),
        SizedBox(height: 16.h),
        _buildOtpChannelSelector(),
        if (!_authController.isLoginTab.value) ...[
          SizedBox(height: 16.h),
          _buildInputField(
            label: "كلمة المرور",
            controller: _authController.passwordController,
            focusNode: _passwordFocus,
            hint: "••••••••",
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (val) => (val?.length ?? 0) < 6 ? "كلمة المرور ضعيفة" : null,
          ),
          SizedBox(height: 16.h),
          _buildInputField(
            label: "تأكيد كلمة المرور",
            controller: _authController.confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            hint: "••••••••",
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            validator: (val) => val != _authController.passwordController.text ? "كلمات المرور غير متطابقة" : null,
          ),
        ],
        SizedBox(height: 32.h),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(hint: hint, icon: icon),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhoneInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("رقم الهاتف الدولي", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        IntlPhoneField(
          controller: _authController.phoneController,
          focusNode: _phoneFocus,
          initialCountryCode: 'SY',
          textAlign: TextAlign.left,
          style: const TextStyle(color: Colors.white),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          dropdownTextStyle: const TextStyle(color: Colors.white),
          pickerDialogStyle: PickerDialogStyle(
            backgroundColor: AppColors.secondaryNavy,
            countryCodeStyle: const TextStyle(color: Colors.white),
            countryNameStyle: const TextStyle(color: Colors.white),
          ),
          decoration: _buildInputDecoration(
            hint: "رقم الهاتف",
            icon: Icons.phone_android_rounded,
          ).copyWith(
            counterText: "",
            errorStyle: const TextStyle(height: 0, fontSize: 0), // Hide red error text
          ),
          languageCode: "ar",
          disableLengthCheck: true, // Disable internal length validation
          autovalidateMode: AutovalidateMode.disabled, // Disable auto validation on type
          onChanged: (phone) {
              _authController.phoneNumber.value = phone.number;
              _authController.countryCode.value = phone.countryCode;
            },
          validator: (phone) => null, // Disable internal validator
        ),
      ],
    );
  }

  Widget _buildOtpChannelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("تلقي الرمز عبر", style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
        SizedBox(height: 12.h),
        Row(
          children: [
            _buildChannelTile(label: "واتساب", channel: OtpChannel.whatsapp, icon: Icons.chat_bubble_outline, activeColor: Colors.green),
            SizedBox(width: 12.w),
            _buildChannelTile(label: "تليغرام", channel: OtpChannel.telegram, icon: Icons.send_rounded, activeColor: Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelTile({required String label, required OtpChannel channel, required IconData icon, required Color activeColor}) {
    return Expanded(
      child: Obx(() {
        bool isSelected = _authController.selectedChannel.value == channel;
        return GestureDetector(
          onTap: () => _authController.selectedChannel.value = channel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.1) : AppColors.secondaryNavy,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isSelected ? activeColor : Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? activeColor : Colors.white38, size: 18),
                SizedBox(width: 8.w),
                Text(label, style: TextStyle(color: isSelected ? activeColor : Colors.white38, fontSize: 13.sp)),
              ],
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: AppColors.accentTeal, size: 20),
      filled: true,
      fillColor: AppColors.secondaryNavy,
      contentPadding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 16.w),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.accentTeal, width: 1)),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: _authController.isLoading.value ? null : () {
          _authController.triggerHaptic(AppHapticFeedback.medium);
          // Manual validation for phone number
          if (_authController.authMethod.value == AuthMethod.phone) {
            final phone = _authController.phoneController.text.trim();
            if (phone.length != 9) {
              Get.snackbar(
                "خطأ في الإدخال", 
                "يرجى إدخال رقم هاتف سوري صحيح مكون من 9 أرقام (بدون الصفر)",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.redAccent.withOpacity(0.9),
                colorText: Colors.white,
                margin: EdgeInsets.all(15.r),
                borderRadius: 15.r,
                icon: const Icon(Icons.error_outline, color: Colors.white),
              );
              return;
            }
          }

          if (_formKey.currentState!.validate()) {
            if (_authController.isLoginTab.value) {
              if (_authController.authMethod.value == AuthMethod.email) {
                _authController.loginWithPassword();
              } else {
                // Final check for channel
                if (_authController.selectedChannel.value == OtpChannel.email) {
                  _authController.selectedChannel.value = OtpChannel.whatsapp; // Auto-select if forgotten
                }
                _authController.sendOTP(type: "login");
              }
            } else {
              // Same for registration
              if (_authController.authMethod.value == AuthMethod.phone && 
                  _authController.selectedChannel.value == OtpChannel.email) {
                _authController.selectedChannel.value = OtpChannel.whatsapp;
              }
              _authController.registerWithPassword();
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          elevation: _authController.isLoading.value ? 0 : 4,
          shadowColor: AppColors.accentTeal.withOpacity(0.4),
        ),
        child: _authController.isLoading.value 
            ? SizedBox(
                height: 24.r,
                width: 24.r,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                _authController.isLoginTab.value ? "تسجيل الدخول" : "إنشاء حساب جديد",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
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
              child: const Text("أو المتابعة عبر", style: TextStyle(color: Colors.white24)),
            ),
            const Expanded(child: Divider(color: Colors.white10)),
          ],
        ),
        SizedBox(height: 20.h),
        _buildSocialButton(
          label: "GitHub",
          icon: Icons.code_rounded,
          onTap: () => _authController.signInWithGitHub(),
        ),
      ],
    );
  }

  Widget _buildSocialButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                SizedBox(width: 12.w),
                Text(label, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 10.h),
            // Temporary test button for Supabase verification
            TextButton(
              onPressed: () => Get.toNamed('/supabase_test'),
              child: const Text("اختبار اتصال Supabase", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFooter() {
    return Obx(() => Center(
      child: Column(
        children: [
          if (!_authController.isLoginTab.value)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: true,
                  onChanged: (v) {},
                  activeColor: AppColors.accentTeal,
                  side: const BorderSide(color: Colors.white24),
                ),
                Text("أوافق على الشروط والأحكام", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
              ],
            ),
          SizedBox(height: 8.h),
          Text.rich(
            TextSpan(
              text: "بالمتابعة، أنت توافق على ",
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
              children: const [
                TextSpan(
                  text: "سياسة الخصوصية",
                  style: TextStyle(color: AppColors.accentTeal),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
