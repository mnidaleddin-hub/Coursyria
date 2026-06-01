import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn) {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Animation
            Icon(Icons.school_rounded, size: 100.sp, color: AppColors.accentTeal),
            SizedBox(height: 20.h),
            Text(
              "كورسيريا",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "منصتك للتعليم السوري المتميز",
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
            SizedBox(height: 50.h),
            const CircularProgressIndicator(color: AppColors.accentTeal),
          ],
        ),
      ),
    );
  }
}
