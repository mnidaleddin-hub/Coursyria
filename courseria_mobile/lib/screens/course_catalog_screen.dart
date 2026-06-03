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
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("تصفح الكورسات"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // Show filter bottom sheet
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _courseController.fetchCoursesFromApi(),
            color: AppColors.accentTeal,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildCategoriesList(),
                Expanded(
                  child: Obx(() {
                    if (_courseController.isLoading.value) {
                      return _buildShimmerGrid();
                    }
                    
                    if (_courseController.filteredCourses.isEmpty) {
                      return EmptyStateWidget(
                        title: "لا توجد كورسات",
                        description: "جرب البحث عن شيء آخر أو تغيير التصنيف",
                        onRetry: () => _courseController.fetchCoursesFromApi(),
                      );
                    }
                    
                    return GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.r),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                      ),
                      itemCount: _courseController.filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = _courseController.filteredCourses[index];
                        return _buildCourseCard(context, course);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          Obx(() => _showBackToTop.value
              ? Positioned(
                  bottom: 20.h,
                  left: 20.w,
                  child: FloatingActionButton.small(
                    onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
                    backgroundColor: AppColors.primaryNavy,
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ).animate().fadeIn().scale(),
                )
              : const SizedBox.shrink()),
        ],
      ),
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
              selectedColor: AppColors.accentTeal.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accentTeal : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      )),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Get.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        highlightColor: Get.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
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
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(15.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: course.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.black.withOpacity(0.1)),
                      errorWidget: (context, url, error) => const Icon(Icons.book_rounded),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              course.instructor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                            ),
                          ),
                          Text(
                            "${course.price.toInt()} ل.س",
                            style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold, fontSize: 11.sp),
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
      ),
    );
  }
}
