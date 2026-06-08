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
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: 16.h, bottom: 32.h),
          itemCount: notificationController.notifications.length,
          itemBuilder: (context, index) {
            final notification = notificationController.notifications[index];
            return _buildNotificationCard(notification);
          },
        );
      }),
    );
  }

  Widget _buildNotificationCard(dynamic notification) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active_outlined, color: AppColors.primaryNavy, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.primaryNavy),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  notification.message,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textBlack, height: 1.5),
                ),
                if (notification.courseTitle != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "📚 ${notification.courseTitle}",
                      style: TextStyle(color: AppColors.accentTeal, fontSize: 11.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 10.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
