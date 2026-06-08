import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';
import '../widgets/custom_loading.dart';
import '../widgets/confetti_overlay.dart';
import '../core/utils/confetti_utils.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    _isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1)); // Mock loading
    _isLoading.value = false;
    // Delay to play confetti after skeleton is gone
    Future.delayed(const Duration(milliseconds: 500), () {
       if (mounted) ConfettiUtils.playConfetti();
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'title': 'أول درس', 'desc': 'أكملت أول درس لك في المنصة', 'icon': PhosphorIcons.star(), 'progress': 1.0, 'isLocked': false, 'points': 50},
      {'title': 'طالب مجتهد', 'desc': 'أكملت 5 كورسات تعليمية', 'icon': PhosphorIcons.student(), 'progress': 0.6, 'isLocked': false, 'points': 200},
      {'title': 'شعلة التعلم', 'desc': 'تسجيل دخول لمدة 7 أيام متتالية', 'icon': PhosphorIcons.fire(), 'progress': 0.4, 'isLocked': false, 'points': 150},
      {'title': 'المحفظة الذهبية', 'desc': 'شحن رصيد بقيمة 50,000 ل.س', 'icon': PhosphorIcons.wallet(), 'progress': 0.0, 'isLocked': true, 'points': 500},
      {'title': 'خبير كورسيريا', 'desc': 'الحصول على 10 شهادات', 'icon': PhosphorIcons.certificate(), 'progress': 0.0, 'isLocked': true, 'points': 1000},
    ];

    return ConfettiOverlay(
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        body: Obx(() => Skeletonizer(
          enabled: _isLoading.value,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildPointsHeader()),
              if (_isLoading.value)
                SliverPadding(
                  padding: EdgeInsets.all(24.r),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildFakeAchievementCard(),
                      childCount: 4,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(24.r),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAchievementCard(achievements[index], index),
                      childCount: achievements.length,
                    ),
                  ),
                ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildFakeAchievementCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 30.r, backgroundColor: Colors.grey),
          SizedBox(height: 12.h),
          Container(width: 80, height: 14, color: Colors.grey),
          SizedBox(height: 8.h),
          Container(width: double.infinity, height: 10, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.h,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text("الإنجازات والميداليات", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
    );
  }

  Widget _buildPointsHeader() {
    final authController = Get.find<AuthController>();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Get.theme.primaryColor, Get.theme.primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Get.theme.primaryColor.withOpacity(0.3), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("رصيد النقاط الكلي", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              SizedBox(height: 8.h),
              Obx(() => Text(
                authController.totalPoints.value.toString(),
                style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w900),
              )),
            ],
          ),
          Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill), color: Colors.white, size: 48.sp),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement, int index) {
    final isLocked = achievement['isLocked'] as bool;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isLocked ? Colors.white10 : Get.theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildProgressCircle(achievement),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement['title'] as String, style: TextStyle(color: isLocked ? Colors.white38 : Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 4.h),
                Text(achievement['desc'] as String, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                if (!isLocked) ...[
                  SizedBox(height: 8.h),
                  Text("+${achievement['points']} نقطة", style: TextStyle(color: Get.theme.primaryColor, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
          Icon(isLocked ? PhosphorIcons.lock() : PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: isLocked ? Colors.white10 : Get.theme.primaryColor, size: 24.sp),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideX(begin: 0.1, end: 0);
  }

  Widget _buildProgressCircle(Map<String, dynamic> achievement) {
    final isLocked = achievement['isLocked'] as bool;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 60.r,
          height: 60.r,
          child: CircularProgressIndicator(
            value: achievement['progress'] as double,
            strokeWidth: 4,
            color: Get.theme.primaryColor,
            backgroundColor: Colors.white10,
          ),
        ),
        Icon(achievement['icon'] as IconData, color: isLocked ? Colors.white10 : Get.theme.primaryColor, size: 28.r),
      ],
    );
  }
}
