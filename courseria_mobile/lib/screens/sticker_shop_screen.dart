import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import '../controllers/gamification_controller.dart';
import '../controllers/auth_controller.dart';

class StickerShopScreen extends StatelessWidget {
  const StickerShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gamificationController = Get.find<GamificationController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("متجر الملصقات", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            margin: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("رصيدك الحالي:", style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                Obx(() => Text(
                      "${authController.userProfile.value?.totalPoints ?? 0} نقطة",
                      style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ),
          Expanded(
            child: Obx(() => GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: gamificationController.stickers.length,
                  itemBuilder: (context, index) {
                    final sticker = gamificationController.stickers[index];
                    final isPurchased = gamificationController.userStickers.contains(sticker.id);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25.r),
                        border: Border.all(
                          color: isPurchased ? AppColors.accentTeal.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                          width: isPurchased ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(sticker.emoji, style: TextStyle(fontSize: 50.sp)),
                          SizedBox(height: 12.h),
                          Text(sticker.name, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                            onPressed: isPurchased ? null : () => gamificationController.buySticker(sticker),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPurchased ? Colors.grey : AppColors.accentTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: Text(
                              isPurchased ? "تم الشراء" : "${sticker.price} نقطة",
                              style: TextStyle(color: Colors.white, fontSize: 12.sp),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}

