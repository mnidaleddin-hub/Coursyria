import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> coupons = [
      {'code': 'WELCOME10', 'discount': '10%', 'expiry': '30 يونيو 2024'},
      {'code': 'BRAVO20', 'discount': '20%', 'expiry': '15 يوليو 2024'},
      {'code': 'SMART50', 'discount': '50%', 'expiry': '1 أغسطس 2024'},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("الكوبونات والخصومات", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(24.r),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return Container(
            margin: EdgeInsets.only(bottom: 20.h),
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryNavy.withOpacity(0.1), AppColors.accentTeal.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: AppColors.accentTeal.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.goldAchievement.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIcons.ticket(), color: AppColors.goldAchievement, size: 24.sp),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon['code']!, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      Text("خصم ${coupon['discount']}", style: TextStyle(color: AppColors.accentTeal, fontSize: 14.sp)),
                      SizedBox(height: 4.h),
                      Text("ينتهي في: ${coupon['expiry']}", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.snackbar("تم النسخ", "تم نسخ كود الخصم بنجاح!");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: const Text("نسخ"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
