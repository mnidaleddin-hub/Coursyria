import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/constants.dart';

class WeeklyChallengesScreen extends StatelessWidget {
  const WeeklyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final challenges = [
      {'title': 'دودة القراءة 📚', 'desc': 'شاهد 3 فيديوهات تعليمية', 'progress': 0.6, 'points': 150, 'icon': Icons.play_circle_fill_rounded},
      {'title': 'ملك الاختبارات 👑', 'desc': 'أكمل اختبارين بنسبة نجاح > 80%', 'progress': 0.5, 'points': 300, 'icon': Icons.quiz_rounded},
      {'title': 'المثابر الأسبوعي ⚡', 'desc': 'سجل دخول لمدة 4 أيام متتالية', 'progress': 1.0, 'points': 200, 'icon': Icons.bolt_rounded},
      {'title': 'المشارك النشط 💬', 'desc': 'أضف 5 تعليقات مفيدة على الدروس', 'progress': 0.2, 'points': 100, 'icon': Icons.comment_rounded},
      {'title': 'الباحث عن الكمال ✨', 'desc': 'أكمل كورساً بالكامل هذا الأسبوع', 'progress': 0.0, 'points': 500, 'icon': Icons.workspace_premium_rounded},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("تحديات الأسبوع 🏆"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallProgress(),
            SizedBox(height: 32.h),
            Text("التحديات الحالية", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final item = challenges[index];
                return _buildChallengeCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("تقدمك العام", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              Text("60%", style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 10.h,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 12.h),
          Text("أكملت 3 من أصل 5 تحديات", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> item) {
    final bool isCompleted = item['progress'] >= 1.0;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isCompleted ? AppColors.accentTeal.withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(color: AppColors.primaryNavy.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(item['icon'] as IconData, color: isCompleted ? AppColors.accentTeal : Colors.white24, size: 28.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                Text(item['desc'] as String, style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: item['progress'] as double,
                    minHeight: 4.h,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.accentTeal : AppColors.primaryNavy),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            children: [
              Text("+${item['points']}", style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Text("نقطة", style: TextStyle(color: Colors.white24, fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }
}
