import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:countup/countup.dart'; // Import for AnimatedCounter
import '../controllers/auth_controller.dart';
import '../screens/wallet_screen.dart'; // Import WalletScreen
// Import the new screen
import '../controllers/wallet_controller.dart';
import '../controllers/course_controller.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';
import '../widgets/shimmer_loading.dart';
import 'wallet_screen.dart';
import 'course_details_screen.dart';
import '../controllers/dashboard_controller.dart';
import '../models/ai_models.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final AuthController _authController = Get.find<AuthController>();
  final WalletController _walletController = Get.find<WalletController>();
  final CourseController _courseController = Get.find<CourseController>();
  final DashboardController _dashboardController = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: () async {
                await _courseController.fetchCoursesFromApi();
                await _authController.fetchUserProfile();
                await _walletController.fetchWalletBalance();
              },
              child: CustomScrollView(
                slivers: [
                  // Top Header & Balance
                  SliverToBoxAdapter(child: _buildHeader()),

                  // Learning Path Advisor Card
                  SliverToBoxAdapter(child: _buildLearningAdvisorCard()),

                  // AI Recommendations Section
                  SliverToBoxAdapter(child: _buildAIRecommendations()),

                  // Smart Tools Grid
                  SliverToBoxAdapter(child: _buildSmartToolsGrid()),

                  // Subject Categories
                  SliverToBoxAdapter(child: _buildSubjectCategories()),

                  // Course List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 15.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "الكورسات المتاحة",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack),
                          ),
                          Obx(() => Text(
                                "${_courseController.filteredCourses.length} كورس",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14.sp, color: AppColors.textGrey),
                              )),
                        ],
                      ),
                    ),
                  ),

                  // Course List or Loading/Empty State
                  Obx(() {
                    if (_courseController.isLoading.value) {
                      return SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Skeletonizer(
                              enabled: true,
                              child: _buildCourseCard(Course(
                                id: 'loading',
                                title: 'Loading Course Name',
                                instructor: 'Instructor Name',
                                price: 25000,
                                rating: 0.0,
                                subject: 'Subject',
                                gradeLevel: 'Level',
                                coverUrl: '',
                                description: '',
                                status: 'approved',
                                lessons: [],
                              )),
                            ),
                            childCount: 3,
                          ),
                        ),
                      );
                    }

                    if (_courseController.hasError.value) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 64.sp, color: Colors.redAccent),
                              SizedBox(height: 16.h),
                              Text(_courseController.errorMessage.value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 24.h),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _courseController.fetchCoursesFromApi(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text("إعادة المحاولة"),
                              )
                            ],
                          ),
                        ),
                      );
                    }

                    if (_courseController.filteredCourses.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_outlined,
                                  size: 64.sp, color: AppColors.textGrey),
                              SizedBox(height: 16.h),
                              Text("لا يوجد كورسات متاحة حالياً",
                                  style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 16.sp)),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final course =
                                _courseController.filteredCourses[index];
                            return _buildCourseCard(course);
                          },
                          childCount: _courseController.filteredCourses.length,
                        ),
                      ),
                    );
                  }),

                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("طموحك يبدأ هنا،",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp)),
                  Text(
                    "طالب كورسيريا المتميز",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5),
                  ),
                  SizedBox(height: 5.h),
                  Obx(() => GestureDetector(
                        onTap: () => Get.to(() => WalletScreen()),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 5.w),
                            Obx(() => Countup(
                                  begin: 0,
                                  end: _authController.userProfile.value?.walletBalance ?? 0.0,
                                  duration: const Duration(milliseconds: 1000),
                                  separator: ',',
                                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                                )),
                            Text(
                              " SYP",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: 10.h),
                  Obx(() => Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                          SizedBox(width: 5.w),
                          Text(
                            "${_authController.currentStreak.value} أيام متتالية",
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 12.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )),
                ],
              ),
              Row(
                children: [
                  Obx(() {
                    if (_authController.isTeacher) {
                      return Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.school_rounded,
                              color: Colors.white),
                          onPressed: () => Get.toNamed('/teacher_panel'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.grid_view_rounded,
                          color: Colors.white),
                      onPressed: () => Get.toNamed('/catalog'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.leaderboard_rounded,
                          color: Colors.amber),
                      onPressed: () => Get.toNamed('/leaderboard'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Colors.white),
                      onPressed: () => Get.toNamed('/notification-center'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                      onPressed: () => Get.toNamed('/settings'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Colors.white),
                      onPressed: () => Get.toNamed('/notifications'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.card_giftcard_rounded,
                          color: AppColors.accentTeal),
                      onPressed: () => Get.toNamed('/referral'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 30.h),
          // Search Bar
          TextField(
            controller: _courseController.searchController,
            onChanged: (value) => _courseController.searchCourses(value),
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: "ابحث عن كورسات...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon:
                  Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 25.h),
          GestureDetector(
            onTap: () => Get.to(() => WalletScreen()),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05)
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                            color: AppColors.accentTeal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.accentTeal),
                      ),
                      SizedBox(width: 12.w),
                      Text("رصيدك الاستثماري",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      Obx(() => Text(
                            "${_walletController.balance.value} ليرة سورية جديدة",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16.sp),
                          )),
                      SizedBox(width: 10.w),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Get.toNamed('/wallet_recharge'),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.accentTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            ),
                            child: const Text("شحن رصيد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 10.w),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningAdvisorCard() {
    return GestureDetector(
      onTap: () => Get.toNamed('/learning-path'),
      child: Container(
        margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(color: AppColors.primaryNavy.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primaryNavy, size: 30.sp),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("مستشارك التعليمي الذكي", style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  Text("اضغط لعرض مسار تعلمك الشخصي المخصص لك.", style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryNavy, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendations() {
    return Obx(() {
      if (_dashboardController.aiRecommendations.isEmpty && !_dashboardController.isAiLoading.value) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.fromLTRB(20.w, 25.h, 20.w, 5.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8.w),
                    Text("موصى لك (AI)", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                  ],
                ),
                if (_dashboardController.isAiLoading.value)
                  SizedBox(width: 15.r, height: 15.r, child: CircularProgressIndicator(strokeWidth: 2, color: Get.theme.primaryColor)),
              ],
            ),
            SizedBox(height: 15.h),
            SizedBox(
              height: 180.h,
              child: _dashboardController.isAiLoading.value && _dashboardController.aiRecommendations.isEmpty
                ? _buildRecommendationSkeleton()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dashboardController.aiRecommendations.length,
                    itemBuilder: (context, index) {
                      final rec = _dashboardController.aiRecommendations[index];
                      final course = _courseController.allCourses.firstWhereOrNull((c) => c.id == rec.courseId);
                      if (course == null) return const SizedBox.shrink();
                      return _buildRecommendationCard(course, rec.reason);
                    },
                  ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRecommendationSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 2,
      itemBuilder: (context, index) => Container(
        width: 280.w,
        margin: EdgeInsets.only(right: 15.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
      ),
    );
  }

  Widget _buildRecommendationCard(Course course, String reason) {
    return GestureDetector(
      onTap: () => Get.to(() => CourseDetailsScreen(course: course)),
      child: Container(
        width: 300.w,
        margin: EdgeInsets.only(right: 15.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: AppColors.accentTeal.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.r),
              child: Image.network(course.coverUrl, width: 80.w, height: 80.w, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  SizedBox(height: 4.h),
                  Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textGrey, fontSize: 11.sp, height: 1.3)),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(color: AppColors.accentTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(5.r)),
                    child: Text("ترشيح ذكي", style: TextStyle(color: AppColors.accentTeal, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartToolsGrid() {
    final List<Map<String, dynamic>> tools = [
      {'title': 'مراجعة', 'icon': Icons.psychology_rounded, 'route': '/smart-review', 'color': Colors.orange},
      {'title': 'ملخصات', 'icon': Icons.audio_file_rounded, 'route': '/audio-summaries', 'color': Colors.blue},
      {'title': 'جلسات', 'icon': Icons.groups_rounded, 'route': '/group-sessions', 'color': Colors.green},
      {'title': 'تقارير', 'icon': Icons.analytics_rounded, 'route': '/monthly-report', 'color': Colors.purple},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("الأدوات الذكية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
          SizedBox(height: 15.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10.w,
              crossAxisSpacing: 10.w,
              childAspectRatio: 0.8,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return GestureDetector(
                onTap: () => Get.toNamed(tool['route']),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: tool['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Icon(tool['icon'], color: tool['color'], size: 24.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(tool['title'], style: TextStyle(color: AppColors.textBlack, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCategories() {
    return Container(
      margin: EdgeInsets.only(top: 24.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Row(
          children: _courseController.subjects.map((subject) {
            return Obx(() {
              final isSelected =
                  _courseController.selectedSubject.value == subject;
              return GestureDetector(
                onTap: () => _courseController.filterCoursesBySubject(subject),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.accentTeal : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: isSelected
                                    ? AppColors.accentTeal.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6))
                          ],
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentTeal
                                : AppColors.primaryNavy.withOpacity(0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _getSubjectIcon(subject),
                          color:
                              isSelected ? Colors.white : AppColors.primaryNavy,
                          size: 26.r,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        subject,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12.sp,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.accentTeal
                              : AppColors.textMain.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }).toList(),
        ),
      ),
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
            Stack(
              children: [
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
                if (course.isPurchased)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
              ],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r)),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 16),
                              SizedBox(width: 4.w),
                              Text(course.rating.toString(),
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryNavy)),
                            ],
                          ),
                        ),
                        Text(
                          course.isPurchased
                              ? "تم التملك"
                              : "${course.price.toStringAsFixed(0)} ليرة سورية جديدة",
                          style: TextStyle(
                            color: course.isPurchased
                                ? Colors.green
                                : AppColors.accentTeal,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.sp,
                          ),
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

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case "رياضيات":
        return Icons.calculate_outlined;
      case "فيزياء":
        return Icons.science_outlined;
      case "كيمياء":
        return Icons.biotech_outlined;
      case "إنجليزي":
        return Icons.language_outlined;
      case "فرنسي":
        return Icons.translate_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }
}
