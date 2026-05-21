import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';
import '../screens/video_player_screen.dart';

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(
              color: AppColors.accentTeal.withOpacity(0.2), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withOpacity(0.05),
                  shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 40.r, color: AppColors.accentTeal),
            ),
            SizedBox(height: 20.h),
            Text(
              "مرحباً بك في مجتمع كورسيريا",
              style: AppTextStyles.header
                  .copyWith(fontSize: 20.sp, color: AppColors.primaryNavy),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              "نحن هنا لمساعدتك في رحلتك التعليمية للوصول إلى أعلى الدرجات. شاهد الفيديو التعريفي لتتعرف على مميزات المنصة.",
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(fontSize: 14.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 32.h),
            _buildVideoButton(),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: const Text("ابدأ الآن",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12.w),
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text("تخطي الشرح",
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13.sp)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVideoButton() {
    return InkWell(
      onTap: _playTutorialVideo,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        height: 160.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryNavy.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
          image: const DecorationImage(
            image: NetworkImage(
                "https://placehold.co/600x400/0B132B/white?text=Tutorial+Video"),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.play_circle_fill_rounded,
                size: 64.r, color: AppColors.accentTeal),
            Positioned(
              bottom: 15,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20.r)),
                child: Text("شاهد كيف تبدأ",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _playTutorialVideo() {
    final storage = GetStorage();
    final settings = storage.read('settings') ?? {};
    final videoUrl = settings['tutorial_video_url'] ?? "";

    Get.to(() => VideoPlayerScreen(
          lesson: Lesson(id: "tutorial", title: "دليل استخدام المنصة"),
          videoUrl: videoUrl,
        ));
  }

  void _completeOnboarding() {
    GetStorage().write('has_seen_tutorial', true);
    Get.back();
  }

  static void show() {
    Get.dialog(
      const WelcomeDialog(),
      barrierDismissible: false,
    );
  }
}
