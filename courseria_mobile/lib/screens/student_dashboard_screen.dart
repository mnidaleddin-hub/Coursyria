import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../core/constants/constants.dart';
import '../widgets/animated_counter.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refreshDashboard(),
          color: AppColors.accentTeal,
          backgroundColor: AppColors.secondaryNavy,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Dynamic Header with Hero
              SliverToBoxAdapter(child: _buildHeader(controller)),

              // 2. Animated Stats Grid
              SliverToBoxAdapter(child: _buildQuickStats(controller)),

              // 3. Horizontal Learning Path
              SliverToBoxAdapter(child: _buildContinueLearning(controller)),

              // 4. AI Powered Recommendations
              SliverToBoxAdapter(child: _buildRecommendations(controller)),

              SliverToBoxAdapter(child: SizedBox(height: 100.h)), // Space for bottom bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  "مرحباً، ${controller.studentName.value}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                  ),
                )),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "استعد لرحلة تعليمية ممتعة اليوم 🚀",
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/settings'),
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentTeal, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 24.r,
                      backgroundColor: AppColors.secondaryNavy,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Obx(() => controller.studyStreak.value > 0 
                ? Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    child: const Icon(Icons.local_fire_department, color: Colors.white, size: 12),
                  )
                : const SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DashboardController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard("ساعة مشاهدة", controller.hoursWatched.value, Icons.timer_rounded, Colors.blueAccent, precision: 1),
          _buildStatCard("درس مكتمل", controller.completedLessons.value.toDouble(), Icons.check_circle_rounded, Colors.greenAccent),
          _buildStatCard("شهادة", controller.earnedCertificates.value.toDouble(), Icons.workspace_premium_rounded, Colors.amberAccent),
        ],
      )),
    );
  }

  Widget _buildStatCard(String label, double value, IconData icon, Color color, {int precision = 0}) {
    return Container(
      width: 95.w,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12.h),
          AnimatedCounter(
            begin: 0,
            end: value,
            precision: precision,
            style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContinueLearning(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 36.h, 24.w, 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "تابع التعلم",
                style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
            ],
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return _buildShimmerCarousel();
          }
          if (controller.continueLearning.isEmpty) {
            return _buildEmptyState("ابدأ رحلتك التعليمية الآن!", Icons.play_lesson_rounded);
          }
          return SizedBox(
            height: 200.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              physics: const BouncingScrollPhysics(),
              itemCount: controller.continueLearning.length,
              itemBuilder: (context, index) {
                final item = controller.continueLearning[index];
                return _buildContinueCard(item);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContinueCard(Map<String, dynamic> item) {
    final progress = (item['progress_percent'] ?? 0.0) / 100.0;
    return GestureDetector(
      onTap: () {
        Get.find<AuthController>().triggerHaptic(AppHapticFeedback.medium);
        // Handle navigation
      },
      child: Container(
        width: 260.w,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          image: DecorationImage(
            image: NetworkImage(item['course_thumbnail'] ?? ""),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  item['course_title'] ?? "",
                  style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                item['lesson_title'] ?? "بدون عنوان",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
                        minHeight: 6.h,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
          child: Text(
            "مقترحات لك ✨",
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return _buildShimmerGrid();
          }
          if (controller.recommendations.isEmpty) {
            return const SizedBox.shrink();
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: controller.recommendations.length,
            itemBuilder: (context, index) {
              final course = controller.recommendations[index];
              return _buildRecommendationCard(course);
            },
          );
        }),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> course) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              course['cover_url'] ?? "",
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.book, color: Colors.white24)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.h),
                Text(
                  course['instructor'] ?? "",
                  style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: 2,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCarousel() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: 3,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            width: 260.w,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(30.r),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white12, size: 50),
          SizedBox(height: 16.h),
          Text(message, style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
        ],
      ),
    );
  }
}
