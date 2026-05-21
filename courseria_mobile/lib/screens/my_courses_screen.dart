import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/course_controller.dart';
import '../core/constants/constants.dart';
import '../widgets/shimmer_loading.dart';
import '../models/course_model.dart';
import 'course_details_screen.dart';

class MyCoursesScreen extends StatelessWidget {
  MyCoursesScreen({super.key});

  final CourseController _courseController = Get.find<CourseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("كورساتي", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (_courseController.isLoading.value && _courseController.myCourses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_courseController.myCourses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sentiment_dissatisfied_outlined, size: 64.sp, color: AppColors.textGrey),
                SizedBox(height: 16.h),
                Text("لم تشترِ أي كورسات بعد.", style: TextStyle(color: AppColors.textGrey, fontSize: 16.sp)),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back(); // Go back to home or explore courses
                  },
                  icon: const Icon(Icons.school_outlined),
                  label: const Text("تصفح الكورسات"),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: _courseController.myCourses.length,
          itemBuilder: (context, index) {
            final course = _courseController.myCourses[index];
            return _buildCourseCard(course);
          },
        );
      }),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryNavy.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
        border: Border.all(
            color: AppColors.primaryNavy.withOpacity(0.05), width: 1),
      ),
      child: InkWell(
        onTap: () => Get.to(() => CourseDetailsScreen(course: course)),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            // Course Image with Shimmer
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
              child: Image.network(
                course.coverUrl,
                width: 120.w,
                height: 120.h,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return ShimmerLoading.rectangular(
                      width: 120.w, height: 120.h);
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120.w,
                  height: 120.h,
                  color: AppColors.primaryNavy.withOpacity(0.05),
                  child: const Icon(Icons.book_rounded,
                      color: AppColors.primaryNavy, size: 32),
                ),
              ),
            ),

            // Course Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.header.copyWith(fontSize: 15.sp),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.person_rounded,
                            size: 14.r, color: AppColors.textMuted),
                        SizedBox(width: 4.w),
                        Text(
                          course.instructor,
                          style: AppTextStyles.muted.copyWith(
                              fontSize: 12.sp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r)),
                      child: Text("تم الشراء",
                          style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.green)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
