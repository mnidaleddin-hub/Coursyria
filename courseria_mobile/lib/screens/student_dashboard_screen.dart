import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/dashboard_controller.dart';
import '../core/constants/constants.dart';
import '../widgets/animated_counter.dart';
import '../controllers/ai_controller.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/app_loading_indicator.dart';
import '../services/ai_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => controller.fetchDashboardData(),
        color: AppColors.accentTeal,
        backgroundColor: AppColors.secondaryNavy,
        child: Obx(() => Skeletonizer(
          enabled: controller.isLoading.value,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Section
              SliverToBoxAdapter(child: _buildHeader(controller)),

              // 2. Global Search Bar
              SliverToBoxAdapter(child: _buildSearchBar()),

              // 3. Animated Stats Grid
              SliverToBoxAdapter(child: _buildQuickStats(controller)),

              // 4. Weekly Report Card
              SliverToBoxAdapter(child: _buildWeeklyReport(controller)),

              // AI Performance Insights & Prediction
              SliverToBoxAdapter(child: _buildAIInsights(controller)),

              // 5. Horizontal Learning Path
              SliverToBoxAdapter(child: _buildContinueLearning(controller)),

              // 6. AI Powered Recommendations (GridView)
              SliverToBoxAdapter(child: _buildRecommendations(controller)),

              // 7. Weekly Challenges (Horizontal)
              SliverToBoxAdapter(child: _buildWeeklyChallenges(controller)),

              // 8. Recent Achievements (Horizontal)
              SliverToBoxAdapter(child: _buildRecentAchievements(controller)),

              SliverToBoxAdapter(child: SizedBox(height: 100.h)),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "ابحث عن كورس، مدرس، أو موضوع...",
          hintStyle: TextStyle(color: Colors.white24, fontSize: 14.sp),
          prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: AppColors.accentTeal),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w), // Better internal padding
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: const BorderSide(color: AppColors.accentTeal),
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Get.toNamed('/catalog', arguments: {'search': value});
          }
        },
      ),
    );
  }

  Widget _buildHeader(DashboardController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  "مرحباً، ${controller.studentName.value}",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                  ),
                )),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), color: AppColors.accentTeal, size: 14.sp),
                    SizedBox(width: 4.w),
                    Obx(() => Text(
                      "${controller.totalPoints.value} نقطة تميز",
                      style: TextStyle(color: AppColors.accentTeal, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    )),
                  ],
                ),
              ],
            ),
          ),
          _buildProfileAvatar(controller),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(DashboardController controller) {
    return GestureDetector(
      onTap: () => Get.toNamed('/achievements'),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: authController.userData['avatar_url'] != null && authController.userData['avatar_url'].toString().isNotEmpty
                ? NetworkImage(authController.userData['avatar_url'])
                : null,
            child: authController.userData['avatar_url'] == null || authController.userData['avatar_url'].toString().isEmpty
                ? Text(
                    authController.userData['name']?[0]?.toUpperCase() ?? "U",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.sp),
                  )
                : null,
          ),
          Obx(() => controller.studyStreak.value > 0 
            ? Container(
                padding: EdgeInsets.all(5.r),
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                child: Icon(PhosphorIcons.fire(PhosphorIconsStyle.fill), color: Colors.white, size: 12.sp),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
            : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DashboardController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard("ساعة تعلم", controller.hoursWatched.value, PhosphorIcons.clock(), Colors.blueAccent, precision: 1),
              _buildStatCard("دروس", controller.completedLessons.value.toDouble(), PhosphorIcons.checkCircle(), Colors.greenAccent),
              _buildStatCard("شهادات", controller.earnedCertificates.value.toDouble(), PhosphorIcons.certificate(), Colors.amberAccent),
            ],
          )),
        );
      }
    );
  }

  Widget _buildStatCard(String label, double value, IconData icon, Color color, {int precision = 0}) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 8.h),
            AnimatedCounter(
              begin: 0,
              end: value,
              precision: precision,
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: Colors.white38, fontSize: 10.sp),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWeeklyReport(DashboardController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Container(
        width: 327.w, // Fixed width for horizontal scroll item consistency
        padding: EdgeInsets.all(20.r),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy.withOpacity(0.1), AppColors.secondaryNavy.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "تقرير الأسبوع 📊",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                Icon(PhosphorIcons.chartLineUp(), color: AppColors.accentTeal, size: 20.sp),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeeklyStatItem("ساعة", "12.5", PhosphorIcons.timer()),
                _buildWeeklyStatItem("درس", "8", PhosphorIcons.bookOpen()),
                _buildWeeklyStatItem("نقطة", "+250", PhosphorIcons.sparkle()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white24, size: 18.sp),
        SizedBox(height: 6.h),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white38, fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildAIInsights(DashboardController controller) {
    final aiController = Get.find<AIController>();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAIInsightCard(
                  title: "تقرير الأداء الذكي",
                  icon: Icons.auto_awesome_rounded,
                  color: Colors.amber,
                  onTap: () => _showAIReport(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildAIInsightCard(
                  title: "توقع الدرجة القادمة",
                  icon: Icons.query_stats_rounded,
                  color: AppColors.accentTeal,
                  onTap: () => _showAIPrediction(),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(() => _buildFullWidthAIAction(
                "توليد خطة دراسية ذكية مخصصة",
                Icons.calendar_today_rounded,
                Colors.indigoAccent,
                () => _showStudyPlanDialog(aiController),
                isLoading: aiController.isGeneratingStudyPlan,
              )),
        ],
      ),
    );
  }

  Widget _buildFullWidthAIAction(String title, IconData icon, Color color, VoidCallback onTap, {required RxBool isLoading}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading.value
                ? SizedBox(height: 20.r, width: 20.r, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 22.sp),
            SizedBox(width: 12.w),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showStudyPlanDialog(AIController aiController) {
    final goalController = TextEditingController();
    final hoursPerDay = 2.0.obs;
    final selectedDays = <String>{'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'}.obs;
    final allDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    Get.dialog(
      AlertDialog(
        title: const Text("خطة دراسية ذكية"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ما هو هدفك الدراسي للأسبوع القادم؟"),
              SizedBox(height: 8.h),
              TextField(
                controller: goalController,
                decoration: const InputDecoration(
                  hintText: "مثلاً: إنهاء وحدة التفاضل",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 20.h),
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الساعات المتاحة يومياً: ${hoursPerDay.value.toInt()} ساعة"),
                      Slider(
                        value: hoursPerDay.value,
                        min: 1,
                        max: 8,
                        divisions: 7,
                        onChanged: (val) => hoursPerDay.value = val,
                        activeColor: AppColors.accentTeal,
                      ),
                    ],
                  )),
              SizedBox(height: 10.h),
              const Text("الأيام المتاحة:"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                children: allDays.map((day) {
                  return Obx(() {
                    final isSelected = selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day, style: TextStyle(fontSize: 10.sp, color: isSelected ? Colors.white : Colors.white60)),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      },
                      selectedColor: AppColors.accentTeal,
                      backgroundColor: Colors.white10,
                    );
                  });
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              aiController.createStudyPlan({
                'goal': goalController.text,
                'hours_per_day': hoursPerDay.value.toInt(),
                'available_days': selectedDays.toList(),
                'current_progress': controller.completedLessons.value
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
            child: const Text("توليد الخطة"),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 8.h),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAIReport() {
    Get.dialog(const Center(child: AppLoadingIndicator()), barrierDismissible: false);
    final aiService = AIService();
    final stats = {
      'hours': controller.hoursWatched.value,
      'lessons': controller.completedLessons.value,
      'points': controller.totalPoints.value,
    };

    aiService.generatePerformanceReport(stats).then((report) {
      Get.back();
      _showAIResultBottomSheet("تقرير أدائك الأسبوعي (AI)", report);
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل توليد التقرير");
    });
  }

  void _showAIPrediction() {
    Get.dialog(const Center(child: AppLoadingIndicator()), barrierDismissible: false);
    final aiService = AIService();
    aiService.callAIGateway(
      feature: 'weakness_analysis',
      lessonId: 'global',
      userPrompt: "بناءً على نشاطي: ${controller.hoursWatched.value} ساعة، ${controller.completedLessons.value} درس، و ${controller.totalPoints.value} نقطة، توقع درجتي في الاختبار القادم وقدم نصيحة ذهبية واحدة.",
    ).then((res) {
      Get.back();
      _showAIResultBottomSheet("توقع الدرجة القادمة 🎯", res.content);
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل تحليل التوقعات");
    });
  }

  void _showAIResultBottomSheet(String title, String content) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: EdgeInsets.all(24.r),
        decoration: const BoxDecoration(color: AppColors.secondaryNavy, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(p: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildContinueLearning(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("تابع التعلم", () => Get.toNamed('/catalog')),
        if (controller.continueLearning.isEmpty && !controller.isLoading.value) 
          const SizedBox.shrink()
        else
          SizedBox(
            height: 180.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              physics: const BouncingScrollPhysics(),
              itemCount: controller.isLoading.value ? 3 : controller.continueLearning.length,
              itemBuilder: (context, index) => _buildContinueCard(
                controller.isLoading.value 
                  ? {'course_title': 'Loading Course Title', 'progress_percent': 50} 
                  : controller.continueLearning[index]
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContinueCard(Map<String, dynamic> item) {
    final progress = (item['progress_percent'] ?? 0.0) / 100.0;
    final courseId = item['course_id']?.toString() ?? "";
    return GestureDetector(
      onTap: () => Get.toNamed('/course-details', arguments: {'id': item['course_id']}),
      child: Container(
        width: 280.w,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                child: Hero(
                  tag: 'course_thumb_$courseId',
                  child: CachedNetworkImage(
                    imageUrl: item['course_thumbnail'] ?? "",
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white10),
                    errorWidget: (context, url, error) => Container(color: Colors.white10),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['course_title'] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
                              minHeight: 4.h,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text("${(progress * 100).toInt()}%", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
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

  Widget _buildRecommendations(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("كورسات موصى بها", () => Get.toNamed('/catalog')),
        if (controller.recommendations.isEmpty && !controller.isLoading.value)
          const SizedBox.shrink()
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
              ),
              itemCount: controller.isLoading.value ? 4 : controller.recommendations.length.clamp(0, 4),
              itemBuilder: (context, index) => _buildRecommendationCard(
                controller.isLoading.value 
                  ? {'title': 'Course Title Placeholder', 'instructor': 'Instructor Name', 'id': ''} 
                  : controller.recommendations[index].toJson()
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> course) {
    final courseId = course['id']?.toString() ?? "";
    return GestureDetector(
      onTap: () => Get.toNamed('/course-details', arguments: {'id': courseId}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'course_rec_$courseId',
                child: CachedNetworkImage(
                  imageUrl: course['cover_url'] ?? "",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(color: Colors.white10),
                  errorWidget: (context, url, error) => Container(color: Colors.white10),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.r),
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
                  Row(
                    children: [
                      Icon(PhosphorIcons.user(), color: Colors.white38, size: 10.sp),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          course['instructor'] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white38, fontSize: 10.sp),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChallenges(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("التحديات الأسبوعية", () => Get.toNamed('/weekly-challenges')),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            physics: const BouncingScrollPhysics(),
            itemCount: 3, // Mock challenges
            itemBuilder: (context, index) => _buildChallengeCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(int index) {
    final titles = ["تحدي الـ 5 دروس", "ملك الكيمياء", "ماراثون التعلم"];
    final colors = [Colors.purpleAccent, Colors.orangeAccent, Colors.blueAccent];
    return Container(
      width: 160.w,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: colors[index].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors[index].withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.trophy(), color: colors[index], size: 24.sp),
          SizedBox(height: 12.h),
          Text(titles[index], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
          SizedBox(height: 4.h),
          Text("اربح 100 نقطة", style: TextStyle(color: colors[index], fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("الإنجازات الأخيرة", () => Get.toNamed('/achievements')),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            physics: const BouncingScrollPhysics(),
            itemCount: 4, // Mock achievements
            itemBuilder: (context, index) => _buildAchievementIcon(index),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementIcon(int index) {
    return Container(
      width: 80.w,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Icon(PhosphorIcons.medal(PhosphorIconsStyle.fill), color: Colors.amber, size: 32.sp),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 32.h, 16.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text("عرض الكل", style: TextStyle(color: AppColors.accentTeal, fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }
}


class WavePainter extends CustomPainter {
  final double value;
  final Color color;
  WavePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, size.height - 20 + 10 * (1 + 0.5 * (1 + value)).abs() * (1 + math.sin(value + i / 50)));
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
