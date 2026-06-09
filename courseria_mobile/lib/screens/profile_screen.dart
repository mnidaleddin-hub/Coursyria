import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/gamification_controller.dart';
import '../../models/user_profile_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  final AuthController _authController = Get.find<AuthController>();
  final AIController _aiController = Get.find<AIController>();
  final GamificationController _gamificationController = Get.find<GamificationController>();

  ProfileScreen({super.key}) {
    _authController.fetchUserProfile(); // Fetch user profile when screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => Get.to(() => const EditProfileScreen()),
          ),
        ],
      ),
      body: Obx(() {
        final userProfile = _authController.userProfile.value;
        if (userProfile == null) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.bgCanvasStart, AppColors.bgCanvasEnd],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accentTeal),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgCanvasStart, AppColors.bgCanvasEnd],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    _buildProfileHeader(userProfile),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _buildProfileCards(userProfile),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(UserProfile userProfile) {
    return Container(
      height: 300.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: AppBar().preferredSize.height + 20.h), // Adjust for AppBar
            GestureDetector(
              onTap: () => _showPickImageBottomSheet(),
              child: Stack(
                children: [
                  Hero(
                    tag: 'user_avatar',
                    child: CircleAvatar(
                      radius: 60.r,
                      backgroundColor: AppColors.surfaceWhite.withOpacity(0.1),
                      child: userProfile.avatarUrl != null &&
                              userProfile.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: userProfile.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 120.r,
                                height: 120.r,
                                placeholder: (context, url) => const CircularProgressIndicator(
                                  color: AppColors.accentTeal,
                                  strokeWidth: 2,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person_rounded,
                                  size: 80.r,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 80.r,
                              color: AppColors.textMuted,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceWhite, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20.r,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              userProfile.fullName ?? "محمد نضال الدين",
              style: AppTextStyles.header.copyWith(
                  fontSize: 22.sp, color: Colors.white),
            ),
            Text(
              userProfile.username != null ? "@${userProfile.username}" : "+963930111876",
              style: AppTextStyles.body.copyWith(
                  fontSize: 14.sp, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCards(UserProfile userProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          "تواصل مع الدعم",
          "+963930111876",
          Icons.support_agent_rounded,
          onTap: () => _launchWhatsApp("+963930111876"),
        ),
        SizedBox(height: 16.h),
        _buildInfoCard(
          "المرحلة الدراسية",
          userProfile.gradeLevel ?? "لم يتم التحديد",
          Icons.school_rounded,
        ),
        SizedBox(height: 16.h),
        _buildInfoCard(
          "نبذة عني",
          userProfile.bio ?? "لا توجد نبذة شخصية بعد.",
          Icons.info_outline_rounded,
        ),
        SizedBox(height: 16.h),
        _buildInfoCard(
          "الاهتمامات",
          userProfile.interests?.join(', ') ?? "لا توجد اهتمامات محددة.",
          Icons.interests_rounded,
        ),
        SizedBox(height: 16.h),
        // Add more cards for other details like referral code, wallet, streak, points
        _buildInfoCard(
          "رصيد المحفظة",
          "${userProfile.walletBalance?.toStringAsFixed(2) ?? '0.00'} SYP",
          Icons.account_balance_wallet_rounded,
        ),
        SizedBox(height: 16.h),
        _buildInfoCard(
          "التعاقب اليومي",
          "${userProfile.currentStreak ?? 0} يوم",
          Icons.local_fire_department_rounded,
        ),
        SizedBox(height: 16.h),
        _buildInfoCard(
          "النقاط الكلية",
          "${userProfile.totalPoints ?? 0} نقطة",
          Icons.military_tech_rounded,
        ),
        SizedBox(height: 16.h),
        _buildPerformanceGraph(),
        SizedBox(height: 16.h),
        _buildStickersRow(),
        SizedBox(height: 16.h),
        _buildAchievementsRow(),
        SizedBox(height: 24.h),
        _buildAIAnalysisCard(userProfile),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildStickersRow() {
    return Obx(() {
      final ownedStickers = _gamificationController.stickers.where((s) => _gamificationController.userStickers.contains(s.id)).toList();
      if (ownedStickers.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ملصقاتي المميزة", style: AppTextStyles.header.copyWith(fontSize: 16.sp, color: Colors.white)),
          SizedBox(height: 12.h),
          SizedBox(
            height: 60.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ownedStickers.length,
              itemBuilder: (context, index) => Container(
                margin: EdgeInsets.only(left: 12.w),
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(ownedStickers[index].emoji, style: TextStyle(fontSize: 24.sp)),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAchievementsRow() {
    return Obx(() {
      final unlocked = _gamificationController.achievements.where((a) => a.isUnlocked).toList();
      if (unlocked.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("أوسمة الشرف", style: AppTextStyles.header.copyWith(fontSize: 16.sp, color: Colors.white)),
          SizedBox(height: 12.h),
          SizedBox(
            height: 50.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: unlocked.length,
              itemBuilder: (context, index) => Tooltip(
                message: unlocked[index].title,
                child: Container(
                  margin: EdgeInsets.only(left: 12.w),
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.goldAchievement.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldAchievement.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _getAchievementIcon(unlocked[index].iconName),
                    color: AppColors.goldAchievement,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'moon':
        return PhosphorIcons.moon();
      case 'calendarCheck':
        return PhosphorIcons.calendarCheck();
      case 'target':
        return PhosphorIcons.target();
      case 'usersThree':
        return PhosphorIcons.usersThree();
      default:
        return PhosphorIcons.medal();
    }
  }

  Widget _buildAIAnalysisCard(UserProfile userProfile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.accentTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "تحليل الشخصية التعليمية",
                      style: AppTextStyles.header.copyWith(fontSize: 16.sp, color: Colors.white),
                    ),
                    Text(
                      "اكتشف أسلوبك الدراسي الأمثل باستخدام الذكاء الاصطناعي",
                      style: AppTextStyles.body.copyWith(fontSize: 12.sp, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _aiController.isAnalyzingStyle.value
                      ? null
                      : () => _showLearningStyleQuestions(userProfile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: _aiController.isAnalyzingStyle.value
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
                        )
                      : const Text("ابدأ التحليل الآن", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }

  void _showLearningStyleQuestions(UserProfile userProfile) {
    final questions = [
      "أحب مشاهدة الفيديوهات أكثر من قراءة النصوص؟",
      "أفضل التعلم بالاستماع إلى المحاضرات؟",
      "أحب تدوين الملاحظات بيدي؟",
      "أتعلم بشكل أسرع عندما أمارس التمارين؟",
      "أحب الدراسة في مجموعات؟",
    ];
    final answers = <int, bool>{}.obs;

    Get.dialog(
      AlertDialog(
        title: const Text("أسئلة سريعة للتحليل"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: questions.length,
            itemBuilder: (context, index) => Obx(() => CheckboxListTile(
                  title: Text(questions[index], style: TextStyle(fontSize: 14.sp)),
                  value: answers[index] ?? false,
                  onChanged: (val) => answers[index] = val ?? false,
                  activeColor: AppColors.accentTeal,
                )),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              final resultList = questions.asMap().entries.map((e) => "${e.value}: ${answers[e.key] ?? false ? 'نعم' : 'لا'}").toList();
              Get.back();
              _aiController.analyzeMyLearningStyle(userProfile.toJson(), resultList);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
            child: const Text("تحليل الآن"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20.r),
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
            Row(
              children: [
                Icon(icon, color: AppColors.primaryNavy, size: 24.r),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: AppTextStyles.header.copyWith(
                      fontSize: 16.sp, color: AppColors.primaryNavy),
                ),
                if (onTap != null) ...[
                  const Spacer(),
                  const Icon(Icons.open_in_new_rounded, color: AppColors.accentTeal, size: 18),
                ],
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                  fontSize: 14.sp, color: AppColors.textMain),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final url = Uri.parse("https://wa.me/${phone.replaceAll('+', '')}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("خطأ", "تعذر فتح واتساب.");
    }
  }

  Widget _buildPerformanceGraph() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("مخطط الأداء الدراسي", style: AppTextStyles.header.copyWith(fontSize: 16.sp, color: AppColors.primaryNavy)),
          SizedBox(height: 16.h),
          AspectRatio(
            aspectRatio: 1.7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.4, "أسبوع 1"),
                _buildBar(0.7, "أسبوع 2"),
                _buildBar(0.5, "أسبوع 3"),
                _buildBar(0.9, "أسبوع 4"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30.w,
          height: 100.h * heightFactor,
          decoration: BoxDecoration(
            color: AppColors.accentTeal,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ).animate().scaleY(begin: 0, duration: const Duration(seconds: 1)),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted)),
      ],
    );
  }

  void _showPickImageBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            SizedBox(height: 24.h),
            Text("تغيير الصورة الشخصية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImageSourceButton(Icons.camera_alt_rounded, "الكاميرا", () {
                  Get.back();
                  _authController.pickAndUploadAvatar(isCamera: true);
                }),
                _buildImageSourceButton(Icons.photo_library_rounded, "المعرض", () {
                  Get.back();
                  _authController.pickAndUploadAvatar(isCamera: false);
                }),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          heroTag: label, // Unique tag for each FloatingActionButton
          backgroundColor: AppColors.primaryNavy,
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 8.h),
        Text(label, style: AppTextStyles.body.copyWith(fontSize: 12.sp, color: AppColors.primaryNavy)),
      ],
    );
  }
}
