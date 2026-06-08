import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> pathItems = [
      {'title': 'أساسيات البرمجة', 'status': 'completed', 'icon': PhosphorIcons.code()},
      {'title': 'هياكل البيانات', 'status': 'in_progress', 'icon': PhosphorIcons.treeStructure()},
      {'title': 'الخوارزميات المتقدمة', 'status': 'locked', 'icon': PhosphorIcons.function()},
      {'title': 'تطوير تطبيقات الموبايل', 'status': 'locked', 'icon': PhosphorIcons.deviceMobile()},
      {'title': 'الذكاء الاصطناعي', 'status': 'locked', 'icon': PhosphorIcons.brain()},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("مسار التعلم الشخصي", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimationLimiter(
        child: ListView.builder(
          padding: EdgeInsets.all(24.r),
          itemCount: pathItems.length,
          itemBuilder: (context, index) {
            final item = pathItems[index];
            final bool isLast = index == pathItems.length - 1;
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 50.r,
                            height: 50.r,
                            decoration: BoxDecoration(
                              color: _getStatusColor(item['status']).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: _getStatusColor(item['status']), width: 2),
                            ),
                            child: Icon(item['icon'], color: _getStatusColor(item['status']), size: 24.sp),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 60.h,
                              color: _getStatusColor(item['status']).withOpacity(0.3),
                            ),
                        ],
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(bottom: 30.h),
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  decoration: item['status'] == 'locked' ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _getStatusText(item['status']),
                                style: TextStyle(color: _getStatusColor(item['status']).withOpacity(0.7), fontSize: 12.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.successGreen;
      case 'in_progress': return AppColors.accentTeal;
      default: return Colors.white24;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed': return "مكتمل ✅";
      case 'in_progress': return "قيد التعلم ⏳";
      default: return "مغلق 🔒";
    }
  }
}
