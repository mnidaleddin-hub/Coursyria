import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class GroupSessionsScreen extends StatelessWidget {
  const GroupSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sessions = [
      {'title': 'مراجعة الرياضيات العامة', 'teacher': 'أ. محمد العلي', 'time': 'اليوم، 08:00 مساءً', 'students': 45},
      {'title': 'نقاش مفتوح: الذكاء الاصطناعي', 'teacher': 'د. سارة خليل', 'time': 'غداً، 04:00 مساءً', 'students': 120},
      {'title': 'أساسيات الفيزياء', 'teacher': 'أ. علي حسن', 'time': '6 يونيو، 06:00 مساءً', 'students': 30},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("جلسات المذاكرة الجماعية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(24.r),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Container(
            margin: EdgeInsets.only(bottom: 20.h),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text("بث مباشر", style: TextStyle(color: AppColors.accentTeal, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        Icon(PhosphorIcons.users(), color: Colors.white38, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text("${session['students']} طالب", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(session['title'], style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 4.h),
                Text(session['teacher'], style: TextStyle(color: AppColors.accentTeal, fontSize: 13.sp)),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(PhosphorIcons.calendarBlank(), color: Colors.white38, size: 14.sp),
                    SizedBox(width: 8.w),
                    Text(session['time'], style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                  ],
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.snackbar("غرفة الانتظار", "تم تسجيل انضمامك. ستبدأ الجلسة في الوقت المحدد.");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    ),
                    child: const Text("انضمام للجلسة"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
