import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final authController = Get.find<AuthController>();

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
              // 1. Welcome Header
              SliverToBoxAdapter(child: _buildHeader(controller)),

              // 2. Quick Stats Row
              SliverToBoxAdapter(child: _buildQuickStats(controller)),

              // 3. Continue Learning Carousel
              SliverToBoxAdapter(child: _buildContinueLearning(controller)),

              // 4. Recommendations Section
              SliverToBoxAdapter(child: _buildRecommendations(controller)),

              SliverToBoxAdapter(child: SizedBox(height: 30.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardController controller) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Text(
                "مرحباً، ${controller.studentName.value}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              )),
              SizedBox(height: 4.h),
              Text(
                "استعد لرحلة تعليمية ممتعة اليوم 🚀",
                style: TextStyle(color: Colors.white54, fontSize: 13.sp),
              ),
            ],
          ),
          Obx(() => Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                SizedBox(width: 4.w),
                Text(
                  "${controller.studyStreak.value} أيام",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ],
            ),
          )),
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
          _buildStatCard("ساعة مشاهدة", controller.hoursWatched.value.toStringAsFixed(1), Icons.timer_outlined, Colors.blue),
          _buildStatCard("درس مكتمل", controller.completedLessons.value.toString(), Icons.check_circle_outline, Colors.green),
          _buildStatCard("شهادة", controller.earnedCertificates.value.toString(), Icons.workspace_premium_outlined, Colors.amber),
        ],
      )),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildContinueLearning(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
          child: Text(
            "تابع التعلم",
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return _buildShimmerCarousel();
          }
          if (controller.continueLearning.isEmpty) {
            return _buildEmptyState("ابدأ رحلتك التعليمية الآن!", Icons.play_circle_fill_rounded);
          }
          return SizedBox(
            height: 180.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
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
        Get.find<AuthController>().triggerHaptic(AppHapticFeedback.light);
        // Navigate to player
      },
      child: Container(
        width: 240.w,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.circular(20.r),
          image: DecorationImage(
            image: NetworkImage(item['course_thumbnail'] ?? ""),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['lesson_title'] ?? "بدون عنوان",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
                  minHeight: 4.h,
                ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "الخطوات التالية الموصى بها (AI)",
                style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            ],
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return _buildShimmerList();
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: controller.recommendations.length,
            itemBuilder: (context, index) {
              final rec = controller.recommendations[index];
              return _buildRecommendationTile(rec);
            },
          );
        }),
      ],
    );
  }

  Widget _buildRecommendationTile(Map<String, dynamic> rec) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppColors.accentTeal),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec['lesson_title'] ?? "", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                SizedBox(height: 4.h),
                Text(rec['course_title'] ?? "", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildShimmerCarousel() {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 240.w,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            color: AppColors.secondaryNavy,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.white10,
            highlightColor: Colors.white24,
            child: Container(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 70.h,
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white10,
          highlightColor: Colors.white24,
          child: Container(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Icon(icon, size: 60, color: Colors.white10),
            SizedBox(height: 16.h),
            Text(msg, style: TextStyle(color: Colors.white24, fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }
}
