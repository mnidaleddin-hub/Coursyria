import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'كورس جديد متاح!',
        'body': 'تم إضافة كورس "الذكاء الاصطناعي للمبتدئين". ابدأ الآن!',
        'time': 'منذ 10 دقائق',
        'icon': PhosphorIcons.sparkle(),
        'isRead': false,
      },
      {
        'title': 'إنجاز جديد 🎉',
        'body': 'لقد حصلت على لقب "المتصفح الليلي". تفقد إنجازاتك!',
        'time': 'منذ ساعتين',
        'icon': PhosphorIcons.trophy(),
        'isRead': true,
      },
      {
        'title': 'تذكير بالدراسة 📚',
        'body': 'لم تدرس اليوم بعد. خصص 15 دقيقة لتحافظ على مستواك.',
        'time': 'منذ 5 ساعات',
        'icon': PhosphorIcons.bellRinging(),
        'isRead': true,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("مركز الإشعارات", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.bellSlash(), size: 80.sp, color: Colors.white10),
                  SizedBox(height: 20.h),
                  Text("لا توجد إشعارات حالياً", style: TextStyle(color: Colors.white24, fontSize: 16.sp)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(20.r),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: notif['isRead'] ? Colors.white.withOpacity(0.02) : AppColors.primaryNavy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: notif['isRead'] ? Colors.white.withOpacity(0.05) : AppColors.primaryNavy.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: notif['isRead'] ? Colors.white10 : AppColors.primaryNavy.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(notif['icon'], color: notif['isRead'] ? Colors.white38 : AppColors.accentTeal, size: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: notif['isRead'] ? FontWeight.normal : FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              notif['body'],
                              style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              notif['time'],
                              style: TextStyle(color: Colors.white24, fontSize: 10.sp),
                            ),
                          ],
                        ),
                      ),
                      if (!notif['isRead'])
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(color: AppColors.accentTeal, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
