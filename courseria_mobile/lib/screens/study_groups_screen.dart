import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';

class StudyGroupsScreen extends StatelessWidget {
  const StudyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = [
      {'name': 'عباقرة الرياضيات 📐', 'members': 15, 'subject': 'رياضيات بكالوريا'},
      {'name': 'فيزياء بلا حدود ⚡', 'members': 8, 'subject': 'فيزياء'},
      {'name': 'نادي اللغة الإنجليزية 🇬🇧', 'members': 24, 'subject': 'إنجليزي'},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("مجموعات الدراسة 👥"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("انضم لزملائك وذاكروا سوياً!", 
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 24.h),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryNavy,
                          child: Text("${group['members']}", style: const TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group['name'] as String, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                              Text(group['subject'] as String, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Get.snackbar("تم الانضمام", "أهلاً بك في المجموعة!", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryNavy),
                          child: const Text("انضمام"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text("إنشاء مجموعة جديدة"),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal, foregroundColor: Colors.black, padding: EdgeInsets.symmetric(vertical: 16.h)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    Get.defaultDialog(
      title: "إنشاء مجموعة دراسة",
      backgroundColor: AppColors.darkBg,
      titleStyle: const TextStyle(color: Colors.white),
      content: Column(
        children: [
          const TextField(decoration: InputDecoration(hintText: "اسم المجموعة", hintStyle: TextStyle(color: Colors.white24))),
          SizedBox(height: 16.h),
          const TextField(decoration: InputDecoration(hintText: "المادة", hintStyle: TextStyle(color: Colors.white24))),
        ],
      ),
      confirm: ElevatedButton(onPressed: () => Get.back(), child: const Text("إنشاء")),
    );
  }
}
