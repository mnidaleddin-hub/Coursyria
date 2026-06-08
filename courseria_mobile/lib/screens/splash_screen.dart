import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _gradientController;
  final AuthController _authController = Get.find<AuthController>();
  final GetStorage _storage = GetStorage();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    
    // Controller for the moving gradient background
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _startNavigationTimer();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  void _startNavigationTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isNavigating) {
        _navigateToNext();
      }
    });
  }

  void _navigateToNext() {
    if (_isNavigating) return;
    _isNavigating = true;

    bool seenOnboarding = _storage.read('seen_onboarding') ?? false;

    if (!seenOnboarding) {
      Get.offAllNamed('/onboarding');
    } else if (_authController.isLoggedIn) {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Gradient Background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(_gradientController.value * 2 - 1, -1),
                    end: Alignment(1 - _gradientController.value * 2, 1),
                    colors: [
                      AppColors.primaryNavy,
                      AppColors.secondaryNavy,
                      AppColors.primaryNavy.withBlue(100),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Scale, Fade and Pulse
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: EdgeInsets.all(25.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentTeal.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: Icon(
                      PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
                      size: 90.r,
                      color: AppColors.accentTeal,
                    ),
                  )
                  .animate()
                  .scale(duration: const Duration(milliseconds: 800), curve: Curves.easeOutBack)
                  .fadeIn(duration: const Duration(milliseconds: 800))
                  .then(delay: const Duration(milliseconds: 200))
                  .shake(duration: const Duration(milliseconds: 1200), hz: 0.5, offset: const Offset(0, 0.05)), // Gentle pulse effect
                ),
                
                SizedBox(height: 40.h),

                // Text "Courseria" with Fade Slide Up
                Column(
                  children: [
                    Text(
                      "Courseria",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'Montserrat', // Assuming it's available or default
                      ),
                    )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 500), duration: const Duration(milliseconds: 800))
                    .slideY(begin: 0.3, end: 0, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic),

                    SizedBox(height: 8.h),

                    Text(
                      "Your Path to Excellence",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                        letterSpacing: 1,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 1000), duration: const Duration(milliseconds: 800))
                    .slideY(begin: 0.5, end: 0, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic),
                  ],
                ),
              ],
            ),
          ),

          // 3. Bottom Progress Indicator
          Positioned(
            bottom: 80.h,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 200.w,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: LinearProgressIndicator(
                        minHeight: 4.h,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
                      ),
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 1200)),
                  SizedBox(height: 20.h),
                  Text(
                    "جاري التحميل...",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12.sp,
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 1500)),
                ],
              ),
            ),
          ),

          // 4. Skip Button (For Dev)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            right: 20.w,
            child: TextButton(
              onPressed: _navigateToNext,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white30,
                padding: EdgeInsets.symmetric(horizontal: 15.w),
              ),
              child: const Text("تخطي"),
            ),
          ).animate().fadeIn(delay: const Duration(seconds: 2)),
        ],
      ),
    );
  }
}
