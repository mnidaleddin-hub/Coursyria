import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // Auto focus on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onMethodChange(AuthMethod method) {
    if (_authController.authMethod.value == method) return;
    
    _authController.authMethod.value = method;
    _authController.triggerHaptic(AppHapticFeedback.light);
    
    // Switch focus
    Future.delayed(const Duration(milliseconds: 300), () {
      if (method == AuthMethod.email) {
        _emailFocus.requestFocus();
      } else {
        _phoneFocus.requestFocus();
      }
    });
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
                SizedBox(height: 40.h),
                _buildHeader(),
                SizedBox(height: 40.h),
                _buildMethodToggle(),
                SizedBox(height: 32.h),
                _buildAnimatedSwitcher(),
                SizedBox(height: 24.h),
                _buildSocialSection(),
                SizedBox(height: 32.h),
                _buildFooter(),
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
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.secondaryNavy,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.school_rounded, size: 50, color: AppColors.accentTeal),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "كورسيريا",
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "بوابتك للتميز التعليمي",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodToggle() {
    return Obx(() => Container(
      height: 50.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            label: "البريد الإلكتروني",
            isSelected: _authController.authMethod.value == AuthMethod.email,
            onTap: () => _onMethodChange(AuthMethod.email),
          ),
          _buildToggleItem(
            label: "رقم الهاتف",
            isSelected: _authController.authMethod.value == AuthMethod.phone,
            onTap: () => _onMethodChange(AuthMethod.phone),
          ),
        ],
      ),
    ));
  }

  Widget _buildToggleItem({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14.sp,
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
          ? _buildEmailLayout() 
          : _buildPhoneLayout(),
    ));
  }

  Widget _buildEmailLayout() {
    return Column(
      key: const ValueKey('email_layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "البريد الإلكتروني",
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        TextFormField(
          controller: _authController.emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(
            hint: "example@gmail.com",
            icon: Icons.email_outlined,
          ),
          validator: (val) => GetUtils.isEmail(val ?? "") ? null : "بريد إلكتروني غير صالح",
        ),
        SizedBox(height: 32.h),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      key: const ValueKey('phone_layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "رقم الهاتف",
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        IntlPhoneField(
          controller: _authController.phoneController,
          focusNode: _phoneFocus,
          initialCountryCode: 'SY',
          style: const TextStyle(color: Colors.white),
          dropdownTextStyle: const TextStyle(color: Colors.white),
          pickerDialogStyle: PickerDialogStyle(
            backgroundColor: AppColors.secondaryNavy,
            countryCodeStyle: const TextStyle(color: Colors.white),
            countryNameStyle: const TextStyle(color: Colors.white),
            searchFieldInputDecoration: _buildInputDecoration(hint: "ابحث عن بلد...", icon: Icons.search),
          ),
          decoration: _buildInputDecoration(
            hint: "9xx xxx xxx",
            icon: Icons.phone_android_rounded,
          ).copyWith(
            counterText: "", // Hide character counter
            helperText: "أدخل 9 أرقام (بدون الصفر في البداية)",
            helperStyle: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          languageCode: "ar",
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (phone) {
            _authController.countryCode.value = phone.countryCode;
            
            // Auto-strip leading zero if entered
            if (phone.number.startsWith('0')) {
              _authController.phoneController.text = phone.number.substring(1);
              _authController.phoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: _authController.phoneController.text.length),
              );
            }
          },
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) return null;
            // Only show error if 9th digit is reached or form is submitted
            if (phone.number.length < 9) return null;
            if (phone.number.length > 9) return "الرقم طويل جداً";
            return null;
          },
        ),
        SizedBox(height: 24.h),
        Text(
          "اختر وسيلة الاستلام",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _buildChannelTile(
              label: "واتساب",
              channel: OtpChannel.whatsapp,
              icon: Icons.chat_bubble_outline_rounded,
              activeColor: Colors.green,
            ),
            SizedBox(width: 16.w),
            _buildChannelTile(
              label: "تليغرام",
              channel: OtpChannel.telegram,
              icon: Icons.send_rounded,
              activeColor: Colors.blue,
            ),
          ],
        ),
        SizedBox(height: 32.h),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildChannelTile({
    required String label, 
    required OtpChannel channel, 
    required IconData icon, 
    required Color activeColor
  }) {
    return Expanded(
      child: Obx(() {
        bool isSelected = _authController.selectedChannel.value == channel;
        return GestureDetector(
          onTap: () {
            _authController.selectedChannel.value = channel;
            _authController.triggerHaptic(AppHapticFeedback.light);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.15) : AppColors.secondaryNavy,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected ? activeColor : Colors.white10,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? activeColor : Colors.white54, size: 20),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeColor : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
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
      prefixIcon: Icon(icon, color: AppColors.accentTeal, size: 22),
      filled: true,
      fillColor: AppColors.secondaryNavy,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: _authController.isLoading.value ? null : () {
          if (_formKey.currentState!.validate()) {
            _authController.sendOTP();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          elevation: 5,
        ),
        child: _authController.isLoading.value 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "استمرار",
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
              child: const Text("أو المتابعة عبر", style: TextStyle(color: Colors.white24)),
            ),
            const Expanded(child: Divider(color: Colors.white10)),
          ],
        ),
        SizedBox(height: 24.h),
        _buildGitHubButton(),
      ],
    );
  }

  Widget _buildGitHubButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _authController.signInWithGitHub(),
        borderRadius: BorderRadius.circular(15.r),
        child: Container(
          width: double.infinity,
          height: 55.h,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.code_rounded, color: Colors.white, size: 24),
              SizedBox(width: 12.w),
              Text(
                "GitHub",
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: "بالاستمرار، أنت توافق على ",
          style: TextStyle(color: Colors.white38, fontSize: 12.sp),
          children: const [
            TextSpan(
              text: "شروط الخدمة",
              style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
