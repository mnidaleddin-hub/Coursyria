import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class MyGalleryScreen extends StatelessWidget {
  const MyGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          title: Text("معرضي الشخصي", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.accentTeal,
            tabs: [
              Tab(child: Text("الشهادات 🎓", style: TextStyle(fontSize: 14.sp))),
              Tab(child: Text("الملصقات 🌟", style: TextStyle(fontSize: 14.sp))),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCertificatesTab(),
            _buildStickersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesTab() {
    final List<Map<String, String>> certs = [
      {'title': 'أساسيات البرمجة', 'date': '2024-05-15'},
      {'title': 'تطوير الويب', 'date': '2024-04-20'},
    ];

    return certs.isEmpty
        ? _buildEmptyState("لا توجد شهادات بعد")
        : GridView.builder(
            padding: EdgeInsets.all(24.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.8,
            ),
            itemCount: certs.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.goldAchievement.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.certificate(), size: 60.sp, color: AppColors.goldAchievement),
                    SizedBox(height: 12.h),
                    Text(
                      certs[index]['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                    Text(certs[index]['date']!, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildStickersTab() {
    final List<String> stickers = ['🚀', '🧠', '🏆', '🔥'];

    return stickers.isEmpty
        ? _buildEmptyState("لم تحصل على ملصقات بعد")
        : GridView.builder(
            padding: EdgeInsets.all(24.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(stickers[index], style: TextStyle(fontSize: 40.sp)),
              );
            },
          );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.folderOpen(), size: 60.sp, color: Colors.white10),
          SizedBox(height: 16.h),
          Text(message, style: TextStyle(color: Colors.white24, fontSize: 14.sp)),
        ],
      ),
    );
  }
}
