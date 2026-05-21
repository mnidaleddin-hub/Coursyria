import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../core/constants/constants.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController =
        Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (notificationController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationController.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 64.sp, color: Colors.redAccent),
                SizedBox(height: 16.h),
                Text(notificationController.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () => notificationController.fetchNotifications(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("إعادة المحاولة"),
                )
              ],
            ),
          );
        }

        if (notificationController.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 64.sp, color: AppColors.textGrey),
                SizedBox(height: 16.h),
                Text("لا توجد إشعارات حالياً",
                    style:
                        TextStyle(color: AppColors.textGrey, fontSize: 16.sp)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notificationController.notifications.length,
          itemBuilder: (context, index) {
            final notification = notificationController.notifications[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: AppColors.primaryNavy),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      notification.message,
                      style: TextStyle(
                          fontSize: 14.sp, color: AppColors.textBlack),
                    ),
                    if (notification.courseTitle != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          "الكورس: ${notification.courseTitle}",
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12.sp,
                              color: AppColors.textGrey),
                        ),
                      ),
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
