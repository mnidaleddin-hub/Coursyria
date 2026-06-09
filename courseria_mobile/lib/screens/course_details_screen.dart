import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../controllers/auth_controller.dart';
import '../controllers/course_controller.dart';
import '../controllers/lesson_controller.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';
import '../controllers/quiz_controller.dart';
import '../services/ai_service.dart';
import 'video_player_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final CourseController _courseController = Get.find<CourseController>();
  final LessonController _lessonController = Get.put(LessonController());
  final AuthController _authController = Get.find<AuthController>();
  final QuizController _quizController = Get.put(QuizController());
  final AIService _aiService = Get.find<AIService>();

  @override
  void initState() {
    super.initState();
    _courseController.fetchCourseLessons(widget.course.id);
    _lessonController.fetchLessons(widget.course.id);
    _quizController.fetchQuizzesForCourse(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            stretch: true,
            backgroundColor: context.theme.primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () {
                  Share.share("تحقق من هذا الكورس الرائع على كورسيريا: ${widget.course.title}");
                },
              ),
              SizedBox(width: 10.w),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'course_${widget.course.id}',
                    child: CachedNetworkImage(
                      imageUrl: widget.course.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) => Container(
                        color: context.theme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.book, color: Colors.white, size: 50),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.course.title, style: AppTextStyles.header.copyWith(fontSize: 24.sp))),
                      _buildCourseBadge(),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(widget.course.description, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                  SizedBox(height: 16.h),
                  _buildCourseStats(),
                  SizedBox(height: 24.h),
                  _buildProgressSection(),
                  _buildContentList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.accentTeal, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_pin_rounded, color: AppColors.accentTeal, size: 16.sp),
          SizedBox(width: 4.w),
          Text("جاهز للأوفلاين", style: TextStyle(color: AppColors.accentTeal, fontSize: 11.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCourseStats() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.play_circle_fill_rounded, "${widget.course.lessons.length} دروس"),
          _buildStatItem(Icons.timer_rounded, "${widget.course.duration ?? '10+'} س"),
          _buildStatItem(Icons.bar_chart_rounded, widget.course.level ?? "مبتدئ"),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentTeal, size: 20.sp),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildDownloadTrailing(Lesson lesson, DownloadStatus status, double progress) {
    if (status == DownloadStatus.completed) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.accentTeal);
    }
    if (status == DownloadStatus.downloading) {
      return SizedBox(
        width: 24.r,
        height: 24.r,
        child: CircularProgressIndicator(value: progress, strokeWidth: 3, color: AppColors.accentTeal),
      );
    }
    return IconButton(
      icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white24),
      onPressed: () => _lessonController.downloadLesson(lesson, lesson.videoUrl ?? ""),
    );
  }

  Widget _buildProgressSection() {
    return Obx(() {
      final lessons = widget.course.lessons;
      if (lessons.isEmpty) return const SizedBox.shrink();

      // Simple calculation: count lessons that are marked completed in student_progress table
      // (This needs proper progress tracking implementation)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("تقدمك في الكورس", style: AppTextStyles.header.copyWith(fontSize: 14.sp, color: Colors.white70)),
              Text("0%", style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: const LinearProgressIndicator(
              value: 0.0,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(AppColors.accentTeal),
              minHeight: 6,
            ),
          ),
          SizedBox(height: 24.h),
        ],
      );
    });
  }

  Widget _buildContentList() {
    return Obx(() {
      final lessons = widget.course.lessons;
      if (lessons.isEmpty) return const Center(child: Text("لا توجد دروس حالياً"));

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return Obx(() {
            final status = _lessonController.downloadStatuses[lesson.id] ?? DownloadStatus.pending;
            final progress = _lessonController.downloadProgresses[lesson.id] ?? 0.0;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: AppColors.secondaryNavy.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryNavy,
                  child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                ),
                title: Text(lesson.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("${lesson.durationSeconds ~/ 60} دقيقة", style: const TextStyle(color: Colors.white38)),
                trailing: _buildDownloadTrailing(lesson, status, progress),
                onTap: () => Get.to(() => VideoPlayerScreen(lesson: lesson, videoUrl: lesson.videoUrl ?? "")),
              ),
            );
          });
        },
      );
    });
  }
}
