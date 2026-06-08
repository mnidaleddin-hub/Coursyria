import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("معلومات التطبيق", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_rounded, size: 80.sp, color: AppColors.accentTeal),
            ),
            SizedBox(height: 24.h),
            Text("كورسيريا", style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
            Text("الإصدار 1.0.0", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
            SizedBox(height: 40.h),
            _buildInfoTile(PhosphorIcons.info(), "عن المنصة", "كورسيريا هي منصة تعليمية سورية تهدف لتوفير أفضل المحتوى التعليمي للطلاب بكفاءة عالية."),
            _buildInfoTile(PhosphorIcons.shieldCheck(), "سياسة الخصوصية", "نحن نحترم خصوصيتك ونحمي بياناتك بأحدث تقنيات التشفير."),
            _buildInfoTile(PhosphorIcons.copyright(), "حقوق النشر", "جميع الحقوق محفوظة لمنصة كورسيريا 2024."),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(PhosphorIcons.facebookLogo()),
                SizedBox(width: 20.w),
                _buildSocialIcon(PhosphorIcons.telegramLogo()),
                SizedBox(width: 20.w),
                _buildSocialIcon(PhosphorIcons.whatsappLogo()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentTeal, size: 20.sp),
              SizedBox(width: 12.w),
              Text(title, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12.h),
          Text(content, style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Icon(icon, color: Colors.white70, size: 24.sp),
    );
  }
}
