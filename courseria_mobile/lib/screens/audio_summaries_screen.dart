import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class AudioSummariesScreen extends StatelessWidget {
  const AudioSummariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> summaries = [
      {'title': 'ملخص أساسيات البرمجة', 'duration': '05:30', 'size': '5.2 MB'},
      {'title': 'مقدمة في هياكل البيانات', 'duration': '08:45', 'size': '8.1 MB'},
      {'title': 'أهمية الخوارزميات', 'duration': '04:15', 'size': '4.0 MB'},
      {'title': 'مستقبل الذكاء الاصطناعي', 'duration': '12:20', 'size': '11.5 MB'},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("الملخصات الصوتية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(24.r),
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final summary = summaries[index];
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), color: AppColors.accentTeal, size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary['title']!,
                        style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "${summary['duration']} • ${summary['size']}",
                        style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(PhosphorIcons.downloadSimple(), color: Colors.white54, size: 20.sp),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
