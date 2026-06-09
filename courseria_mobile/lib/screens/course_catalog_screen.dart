import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animations/animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/course_controller.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';
import 'course_details_screen.dart';
import '../widgets/empty_state_widget.dart';

import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/app_loading_indicator.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final CourseController _courseController = Get.find<CourseController>();
  final ScrollController _scrollController = ScrollController();
  final RxBool _showBackToTop = false.obs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _showBackToTop.value = _scrollController.offset > 500;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _courseController.fetchCoursesFromApi(),
          color: context.theme.primaryColor,
          child: Column(
            children: [
              _buildSearchBar(),
              _buildCategoriesList(),
              Expanded(
                child: Obx(() {
                  return Skeletonizer(
                    enabled: _courseController.isLoading.value,
                    child: _courseController.filteredCourses.isEmpty && !_courseController.isLoading.value
                        ? EmptyStateWidget(
                            title: "لا توجد كورسات",
                            description: "جرب البحث عن شيء آخر أو تغيير التصنيف",
                            onRetry: () => _courseController.fetchCoursesFromApi(),
                          )
                        : GridView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16.r),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 16.w,
                              mainAxisSpacing: 16.h,
                            ),
                            itemCount: _courseController.isLoading.value 
                                ? 4 
                                : _courseController.filteredCourses.length,
                            itemBuilder: (context, index) {
                              if (_courseController.isLoading.value) {
                                return _buildFakeCourseCard();
                              }
                              final course = _courseController.filteredCourses[index];
                              return _buildCourseCard(context, course);
                            },
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
        Obx(() => _showBackToTop.value
            ? Positioned(
                bottom: 20.h,
                right: 20.w,
                child: FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                  },
                  backgroundColor: context.theme.primaryColor,
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: TextField(
        controller: _courseController.searchController,
        onChanged: (val) => _courseController.searchQuery.value = val,
        decoration: InputDecoration(
          hintText: "ابحث عن اسم الكورس أو المدرس...",
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Obx(() => _courseController.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _courseController.searchController.clear();
                    _courseController.searchQuery.value = "";
                  },
                )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: Get.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 40.h,
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _courseController.categories.length,
        itemBuilder: (context, index) {
          final category = _courseController.categories[index];
          final isSelected = _courseController.selectedCategory.value == category;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (val) => _courseController.selectedCategory.value = category,
              selectedColor: Get.theme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Get.theme.primaryColor : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      )),
    );
  }

  Widget _buildFakeCourseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Container(color: Colors.grey)),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: Colors.grey),
                SizedBox(height: 8.h),
                Container(width: 60, height: 12, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openColor: context.theme.scaffoldBackgroundColor,
      openBuilder: (context, _) => CourseDetailsScreen(course: course),
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Hero(
            tag: 'course_${course.id}',
            child: Container(
              decoration: BoxDecoration(
                color: Get.isDarkMode ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                      child: CachedNetworkImage(
                        imageUrl: course.thumbnailUrl ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Get.isDarkMode ? Colors.white : AppColors.textMain,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          course.instructorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
      },
    );
  }
}
