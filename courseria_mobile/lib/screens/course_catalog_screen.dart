import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/course_controller.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';
import 'course_details_screen.dart';

class CourseCatalogScreen extends StatelessWidget {
  CourseCatalogScreen({super.key});

  final CourseController _courseController = Get.find<CourseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: Text(
          "تصفح الكورسات",
          style: TextStyle(
              fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Categories (Horizontal List)
          SizedBox(height: 10.h),
          _buildCategoriesList(),
          
          SizedBox(height: 20.h),
          
          // 2. Section Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "الكورسات المعتمدة",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() => Text(
                  "${_courseController.filteredCourses.length} كورس",
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                )),
              ],
            ),
          ),
          
          SizedBox(height: 15.h),
          
          // 3. Courses Grid
          Expanded(
            child: Obx(() {
              if (_courseController.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
              }
              
              if (_courseController.filteredCourses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64.sp, color: Colors.white24),
                      SizedBox(height: 16.h),
                      Text("لا توجد كورسات في هذا التصنيف", style: TextStyle(color: Colors.white54, fontSize: 16.sp)),
                    ],
                  ),
                );
              }
              
              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 15.w,
                  mainAxisSpacing: 15.h,
                ),
                itemCount: _courseController.filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = _courseController.filteredCourses[index];
                  return _buildCourseCard(course);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 45.h,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        scrollDirection: Axis.horizontal,
        itemCount: _courseController.subjects.length,
        itemBuilder: (context, index) {
          final subject = _courseController.subjects[index];
          return Obx(() {
            bool isSelected = _courseController.selectedSubject.value == subject;
            return GestureDetector(
              onTap: () {
                _courseController.selectedSubject.value = subject;
                _courseController.applyFilters();
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5.w),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentTeal : AppColors.secondaryNavy,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.accentTeal : Colors.white10,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.accentTeal.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  subject,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return GestureDetector(
      onTap: () => Get.to(() => CourseDetailsScreen(course: course)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  course.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: course.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.secondaryNavy, child: const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))),
                          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                        )
                      : Container(
                          color: AppColors.primaryNavy,
                          child: Icon(Icons.book_rounded, color: Colors.white24, size: 40.sp),
                        ),
                  // Subject Badge
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.subject,
                        style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          course.instructor,
                          style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                        ),
                        Text(
                          "${course.price.toInt()} ليرة سورية جديدة",
                          style: TextStyle(color: AppColors.accentTeal, fontSize: 11.sp, fontWeight: FontWeight.bold),
                        ),
                      ],
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
