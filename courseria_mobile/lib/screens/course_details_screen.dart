import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/auth_controller.dart';
import '../controllers/course_controller.dart';
// ...
import '../controllers/lesson_controller.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';
import '../widgets/shimmer_loading.dart';
import '../controllers/quiz_controller.dart';
import '../core/utils/offline_video_manager.dart';
import 'quiz_play_screen.dart';
import 'video_player_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Course course;
  final CourseController _courseController = Get.find<CourseController>();
  final LessonController _lessonController = Get.put(LessonController());
  final AuthController _authController = Get.find<AuthController>();

  CourseDetailsScreen({super.key, required this.course}) {
    _lessonController.fetchLessons(course.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvasStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgCanvasStart, AppColors.bgCanvasEnd],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium App Bar with Glassmorphism Image Container
            SliverAppBar(
              expandedHeight: 250.h,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.primaryNavy,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: () {
                    Share.share("تحقق من هذا الكورس الرائع على كورسيريا: ${course.title}");
                  },
                ),
                SizedBox(width: 10.w),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      course.coverUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return ShimmerLoading.rectangular(height: 250.h);
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryNavy.withOpacity(0.1),
                        child: const Icon(Icons.book,
                            color: AppColors.primaryNavy, size: 50),
                      ),
                    ),
                    // Gradient Overlay for better text visibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.primaryNavy.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Course Info & Lessons
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: AppTextStyles.header.copyWith(
                                fontSize: 24.sp, color: AppColors.primaryNavy),
                          ),
                        ),
                        _buildRatingBadge(),
                      ],
                    ),
                    Obx(() {
                      if (_courseController.allCourses.firstWhere((c) => c.id == course.id).isPurchased) {
                        return _buildFinalQuizAction();
                      }
                      return const SizedBox.shrink();
                    }),
                    SizedBox(height: 12.h),

                    // Instructor & Subject Chip
                    Row(
                      children: [
                        _buildInfoChip(
                            Icons.person_pin_rounded, course.instructor),
                        SizedBox(width: 12.w),
                        _buildInfoChip(Icons.category_rounded, course.subject),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // Luxury Description Card
                    _buildSectionHeader("نظرة عامة", null),
                    SizedBox(height: 12.h),
                    Text(
                      course.description.isNotEmpty
                          ? course.description
                          : "هذا الكورس يمثل رحلة تعليمية متكاملة في مادة ${course.subject}. تم تصميمه بمعايير عالمية ليناسب احتياجات طلابنا، مع التركيز على المفاهيم الأساسية والتقنيات الامتحانية المتقدمة.",
                      style: AppTextStyles.body.copyWith(
                          fontSize: 15.sp,
                          color: AppColors.textMain.withOpacity(0.8),
                          height: 1.8),
                    ),
                    SizedBox(height: 40.h),

                    // Lessons Timeline Header
                    _buildSectionHeader(
                        "محتوى الدورة", "${course.lessons.length} حصة تدريبية"),
                    SizedBox(height: 20.h),

                    // Lesson List with Animated Transitions
                    _buildLessonList(),

                    SizedBox(height: 120.h), // Space for bottom action bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 4.w),
          Text(
            course.rating.toString(),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryNavy,
                fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: AppColors.primaryNavy.withOpacity(0.6)),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primaryNavy.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
        if (subtitle != null)
          Text(subtitle,
              style: AppTextStyles.muted
                  .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLessonList() {
    return Obx(() {
      if (_lessonController.isLoading.value) {
        return Column(
          children: List.generate(
              3, (index) => ShimmerLoading.rectangular(height: 80.h)),
        );
      }

      if (_lessonController.hasError.value) {
        return Center(
          child: Column(
            children: [
              Text(_lessonController.errorMessage.value),
              TextButton(
                onPressed: () => _lessonController.fetchLessons(course.id),
                child: const Text("إعادة المحاولة"),
              ),
            ],
          ),
        );
      }

      if (_lessonController.lessons.isEmpty) {
        return const Center(child: Text("لا توجد دروس متاحة حالياً"));
      }

      return ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _lessonController.lessons.length,
        itemBuilder: (context, index) {
          final lesson = _lessonController.lessons[index];
          return TweenAnimationBuilder(
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildLessonItem(
                lesson, index, _lessonController.isSubscribed.value),
          );
        },
      );
    });
  }

  Widget _buildLessonItem(Lesson lesson, int index, bool isPurchased) {
    bool isDeveloperMode = _authController.token.value == "developer_token";
    bool isFirstLesson = index == 0;
    bool isPreviewAvailable = isFirstLesson && !isPurchased;

    bool isLocked = !isDeveloperMode &&
        !lesson.isFree &&
        !isPurchased &&
        !isPreviewAvailable;
    final storage = GetStorage();
    final Map<String, dynamic> progressMap =
        storage.read('playback_progress') ?? {};
    final int progressSeconds = progressMap[lesson.id] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryNavy.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
        border: Border.all(
          color: isLocked
              ? Colors.transparent
              : AppColors.accentTeal.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          leading: _buildLessonLeading(isLocked, index + 1),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: AppTextStyles.header.copyWith(
                    fontSize: 15.sp,
                    color: isLocked ? AppColors.statusLocked : AppColors.primaryNavy,
                  ),
                ),
              ),
              if (!isLocked && lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
                _buildDownloadIcon(lesson),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.duration ?? "مدة غير محددة",
                style: AppTextStyles.muted.copyWith(fontSize: 12.sp),
              ),
              if (progressSeconds > 0 && !isLocked)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: LinearProgressIndicator(
                      value: 0.3, // Mock value, in real app calculate ratio
                      backgroundColor: AppColors.accentTeal.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentTeal),
                      minHeight: 3.h,
                    ),
                  ),
                ),
            ],
          ),
          trailing: isLocked
              ? Icon(Icons.lock_person_rounded,
                  size: 22.r, color: AppColors.statusLocked)
              : Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.accentTeal),
                ),
          children: [
            if (!isLocked) ...[
              _buildAssetSection("أوراق العمل والمصادر", lesson.worksheets),
              _buildAssetSection("الاختبارات والتقييم",
                  [...lesson.solvedTests, ...lesson.unsolvedTests]),
              _buildAssetSection("المراجعات الامتحانية", lesson.examReviews),
              if (lesson.quizQuestions.isNotEmpty) _buildQuizAction(lesson),
              _buildLessonAction(lesson),
            ] else
              _buildLockedOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadIcon(Lesson lesson) {
    return Obx(() {
      final status = _lessonController.downloadStatuses[lesson.id] ?? DownloadStatus.pending;
      final progress = _lessonController.downloadProgresses[lesson.id] ?? 0.0;

      if (status == DownloadStatus.downloading) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: AppColors.accentTeal,
              ),
            ),
            Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 8.sp, color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
          ],
        );
      }

      if (status == DownloadStatus.completed) {
        return Icon(Icons.offline_pin_rounded, color: AppColors.accentTeal, size: 22.r);
      }

      return IconButton(
        icon: const Icon(Icons.cloud_download_outlined, color: Colors.grey, size: 22),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () => _lessonController.downloadLesson(lesson, lesson.videoUrl!),
      );
    });
  }

  Widget _buildLessonLeading(bool isLocked, int order) {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.statusLocked.withOpacity(0.1)
            : AppColors.accentTeal.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isLocked
            ? Icon(Icons.lock_outline_rounded,
                size: 18.r, color: AppColors.statusLocked)
            : Text(
                order.toString().padLeft(2, '0'),
                style: TextStyle(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.sp),
              ),
      ),
    );
  }

  Widget _buildLessonAction(Lesson lesson) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: ElevatedButton.icon(
        onPressed: () {
          if (lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
            Get.snackbar(
              "تنبيه",
              "المحتوى قيد الرفع",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primaryNavy.withOpacity(0.8),
              colorText: Colors.white,
            );
          } else {
            Get.to(() => VideoPlayerScreen(
                  lesson: lesson,
                  videoUrl: lesson.videoUrl!,
                ));
          }
        },
        icon: const Icon(Icons.play_circle_filled_rounded, color: Colors.white),
        label: Text("مشاهدة الدرس الآن",
            style: TextStyle(
                fontSize: 14.sp, color: Colors.white, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          minimumSize: Size(double.infinity, 48.h),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildQuizAction(Lesson lesson) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: OutlinedButton.icon(
        onPressed: () {
          final quizController = Get.put(QuizController());
          quizController.startQuiz(
            type: 'lesson',
            topicName: lesson.title,
            cId: course.id,
            lId: lesson.id,
          );
          Get.to(() => QuizPlayScreen());
        },
        icon: const Icon(Icons.quiz_rounded, color: AppColors.accentTeal),
        label: Text("ابدأ الاختبار الذكي (AI)",
            style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.accentTeal,
                fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.accentTeal, width: 2),
          minimumSize: Size(double.infinity, 48.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      ),
    );
  }

  Widget _buildFinalQuizAction() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentTeal, AppColors.primaryNavy],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            final quizController = Get.put(QuizController());
            quizController.startQuiz(
              type: 'final',
              topicName: course.title,
              cId: course.id,
            );
            Get.to(() => QuizPlayScreen());
          },
          icon: const Icon(Icons.emoji_events_rounded, color: Colors.white),
          label: Text("اختبار التخرج النهائي (AI Quiz)",
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: Size(double.infinity, 54.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: AppColors.bgCanvasStart.withOpacity(0.5),
      child: Column(
        children: [
          Icon(Icons.lock_clock_rounded,
              color: AppColors.statusLocked, size: 32.r),
          SizedBox(height: 12.h),
          Text(
            "هذا المحتوى مخصص للمشتركين فقط",
            style: AppTextStyles.muted
                .copyWith(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
          Text(
            "قم بشراء الكورس لفتح كافة الدروس والمرفقات",
            style: AppTextStyles.muted.copyWith(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetSection(String title, List<LessonAsset> assets) {
    if (assets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                  width: 4.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                      color: AppColors.accentTeal,
                      borderRadius: BorderRadius.circular(2))),
              SizedBox(width: 8.w),
              Text(title,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy)),
            ],
          ),
        ),
        ...assets.map((asset) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.insert_drive_file_rounded,
                    color: AppColors.accentTeal.withOpacity(0.7), size: 20),
                title: Text(asset.title,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_circle_down_rounded,
                    color: AppColors.accentTeal, size: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                tileColor: AppColors.bgCanvasStart,
                onTap: () => _courseController.downloadAsset(asset),
              ),
            )),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Obx(() {
      final currentCourse =
          _courseController.allCourses.firstWhere((c) => c.id == course.id);

      return Container(
        padding: EdgeInsets.fromLTRB(
            24.w, 20.h, 24.w, 24.h + Get.context!.mediaQueryPadding.bottom),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryNavy.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, -10))
          ],
        ),
        child: Row(
          children: [
            if (!currentCourse.isPurchased)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("قيمة الاستثمار",
                        style: AppTextStyles.muted.copyWith(
                            fontSize: 12.sp, fontWeight: FontWeight.w600)),
                    Text(
                      "${currentCourse.price.toStringAsFixed(0)} ليرة سورية جديدة",
                      style: TextStyle(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w900,
                          fontSize: 18.sp),
                    ),
                  ],
                ),
              ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (currentCourse.isPurchased) {
                    if (_lessonController.lessons.isNotEmpty) {
                      Get.to(() => VideoPlayerScreen(
                            lesson: _lessonController.lessons.first,
                            videoUrl: _lessonController.lessons.first.videoUrl ?? '',
                          ));
                    } else {
                      Get.snackbar("تنبيه", "لا توجد دروس متاحة حالياً لهذا الكورس.", snackPosition: SnackPosition.BOTTOM);
                    }
                  } else {
                    _courseController.purchaseCourse(currentCourse);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r)),
                ),
                child: Text(
                  currentCourse.isPurchased
                      ? "متابعة التعلم"
                      : "امتلاك الكورس الآن",
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
