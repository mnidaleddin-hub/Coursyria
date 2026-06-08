import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import '../controllers/gamification_controller.dart';

class RareAchievementsScreen extends StatelessWidget {
  const RareAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gamificationController = Get.find<GamificationController>();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("الإنجازات النادرة", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() => GridView.builder(
            padding: EdgeInsets.all(24.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.8,
            ),
            itemCount: gamificationController.achievements.length,
            itemBuilder: (context, index) {
              final ach = gamificationController.achievements[index];
              final bool unlocked = ach.isUnlocked;
              return Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: unlocked ? AppColors.primaryNavy.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: unlocked ? AppColors.goldAchievement.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                    width: unlocked ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _getIconData(ach.iconName),
                          size: 50.sp,
                          color: unlocked ? AppColors.goldAchievement : Colors.white24,
                        ),
                        if (!unlocked) Icon(PhosphorIcons.lockKey(), size: 20.sp, color: Colors.white38),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      ach.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      ach.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white24, fontSize: 10.sp),
                    ),
                    if (unlocked) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.goldAchievement.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          ach.rarity == 'legendary' ? 'أسطوري' : 'نادر',
                          style: TextStyle(color: AppColors.goldAchievement, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          )),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'moon':
        return PhosphorIcons.moon();
      case 'calendarCheck':
        return PhosphorIcons.calendarCheck();
      case 'target':
        return PhosphorIcons.target();
      case 'usersThree':
        return PhosphorIcons.usersThree();
      default:
        return PhosphorIcons.medal();
    }
  }
}

