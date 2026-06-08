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
                  Text(widget.course.title, style: AppTextStyles.header.copyWith(fontSize: 24.sp)),
                  SizedBox(height: 8.h),
                  Text(widget.course.description, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                  SizedBox(height: 24.h),
                  _buildContentList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
          return ListTile(
            leading: CircleAvatar(child: Text("${index + 1}")),
            title: Text(lesson.title),
            subtitle: Text("${lesson.durationSeconds ~/ 60} دقيقة"),
            onTap: () => Get.to(() => VideoPlayerScreen(lesson: lesson, videoUrl: lesson.videoUrl ?? "")),
          );
        },
      );
    });
  }
}
