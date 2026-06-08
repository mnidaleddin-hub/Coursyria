import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animations/animations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../controllers/auth_controller.dart';
import '../controllers/course_controller.dart';
import '../controllers/lesson_controller.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/custom_loading.dart';
import '../controllers/quiz_controller.dart';
import '../models/quiz_model.dart';
import '../services/ai_service.dart';
import 'quiz_screen.dart';
import 'quiz_result_screen.dart';
import 'video_player_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Course course;
  final CourseController _courseController = Get.find<CourseController>();
  final LessonController _lessonController = Get.put(LessonController());
  final AuthController _authController = Get.find<AuthController>();
  final QuizController _quizController = Get.put(QuizController());
  final AIService _aiService = AIService();

  CourseDetailsScreen({super.key, required this.course}) {
    _lessonController.fetchLessons(course.id);
    _quizController.fetchQuizzesForCourse(course.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium App Bar with Glassmorphism Image Container
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            stretch: true,
            backgroundColor: context.theme.primaryColor,
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
                  Hero(
                    tag: 'course_${course.id}',
                    child: CachedNetworkImage(
                      imageUrl: course.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, error, stackTrace) => Container(
                        color: context.theme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.book, color: Colors.white, size: 50),
                      ),
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
                          Colors.black.withOpacity(0.8),
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
                              fontSize: 24, color: context.theme.primaryColor),
                        ),
                      ),
                      _buildRatingBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // AI Summary Action
                  _buildAISummaryAction(),
                  
                  // AI Quiz Action
                  _buildAIQuizAction(),

                  // AI Flashcards & FAQ Actions
                  Row(
                    children: [
                      Expanded(child: _buildSmallAIAction(
                        title: "بطاقات مراجعة", 
                        icon: Icons.style_rounded, 
                        color: Colors.purple,
                        onTap: () => _generateFlashcards(),
                      )),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildSmallAIAction(
                        title: "أسئلة شائعة", 
                        icon: Icons.question_answer_rounded, 
                        color: Colors.orange,
                        onTap: () => _generateFAQs(),
                      )),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  
                  Obx(() {
                    final c = _courseController.allCourses.firstWhereOrNull((c) => c.id == course.id);
                    if (c != null && c.isPurchased) {
                      return _buildFinalQuizAction();
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 12),

                  // Instructor & Subject Chip
                  Row(
                    children: [
                      _buildInfoChip(
                          Icons.person_pin_rounded, course.instructorName),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.category_rounded, course.category ?? "تعليم"),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Luxury Description Card
                  _buildSectionHeader("نظرة عامة", null),
                  const SizedBox(height: 12),
                  Text(
                    course.description.isNotEmpty
                        ? course.description
                        : "هذا الكورس يمثل رحلة تعليمية متكاملة. تم تصميمه بمعايير عالمية ليناسب احتياجات طلابنا، مع التركيز على المفاهيم الأساسية والتقنيات الامتحانية المتقدمة.",
                    style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        color: Get.isDarkMode ? Colors.white70 : AppColors.textMain.withOpacity(0.8),
                        height: 1.8),
                  ),
                  const SizedBox(height: 40),

                  // Lessons Timeline Header
                  _buildSectionHeader(
                      "محتوى الدورة", "${course.lessonsCount} حصة تدريبية"),
                  const SizedBox(height: 20),

                  // Lesson List with Skeletonizer
                  Obx(() => Skeletonizer(
                    enabled: _lessonController.isLoading.value,
                    child: _buildLessonList(),
                  )),

                  const SizedBox(height: 40),
                  
                  // Quizzes Section
                  _buildQuizzesSection(),

                  const SizedBox(height: 40),
                  _buildReviewsSection(),

                  const SizedBox(height: 120), // Space for bottom action bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(context),
    );
  }

  Widget _buildAISummaryAction() {
    return GestureDetector(
      onTap: () {
        if (_lessonController.lessons.isEmpty) {
          Get.snackbar("تنبيه", "لا توجد دروس لتلخيصها حالياً");
          return;
        }
        _showAISummaryDialog();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Get.theme.primaryColor.withOpacity(0.15), Colors.white.withOpacity(0.05)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Get.theme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Get.theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: Get.theme.primaryColor, size: 20),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("الملخص الذكي للكورس (AI)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Get.theme.primaryColor)),
                  Text("احصل على أهم النقاط والملخصات بضغطة واحدة", style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Get.theme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAIQuizAction() {
    return GestureDetector(
      onTap: () {
        if (_lessonController.lessons.isEmpty) {
          Get.snackbar("تنبيه", "لا توجد دروس لتوليد اختبار منها حالياً");
          return;
        }
        _showAIQuizDialog();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentTeal.withOpacity(0.15), Colors.white.withOpacity(0.05)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.accentTeal, size: 20),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("توليد اختبار ذكي (AI Quiz)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.accentTeal)),
                  Text("اختبر معلوماتك بأسئلة مولدة خصيصاً لك", style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAIAction({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: 8.w),
            Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  void _generateFlashcards() {
    Get.dialog(const Center(child: AppLoadingIndicator()), barrierDismissible: false);
    _aiService.generateFlashcards(course.id, "${course.title}\n${course.description}").then((cards) {
      Get.back();
      _showFlashcardsDialog(cards);
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل توليد البطاقات: $e");
    });
  }

  void _showFlashcardsDialog(List<Map<String, String>> cards) {
    final PageController cardController = PageController();
    final RxInt currentIndex = 0.obs;
    final RxBool isFlipped = false.obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r))),
        child: Column(
          children: [
            Text("بطاقات المراجعة الذكية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Expanded(
              child: PageView.builder(
                controller: cardController,
                itemCount: cards.length,
                onPageChanged: (i) {
                  currentIndex.value = i;
                  isFlipped.value = false;
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => isFlipped.toggle(),
                    child: Obx(() => Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: isFlipped.value ? AppColors.accentTeal.withOpacity(0.1) : Get.theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: isFlipped.value ? AppColors.accentTeal : Get.theme.primaryColor),
                      ),
                      child: Text(
                        isFlipped.value ? cards[index]['back']! : cards[index]['front']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                      ),
                    )),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
            Obx(() => Text("${currentIndex.value + 1} / ${cards.length}", style: const TextStyle(color: AppColors.textMuted))),
            SizedBox(height: 20.h),
            Text("اضغط على البطاقة لقلبها", style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _generateFAQs() {
    Get.dialog(const Center(child: AppLoadingIndicator()), barrierDismissible: false);
    _aiService.generateFAQs(course.title, course.description).then((faq) {
      Get.back();
      _showTextResultDialog("الأسئلة الشائعة المتوقعة", faq);
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل توليد الأسئلة: $e");
    });
  }

  void _showTextResultDialog(String title, String content) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r))),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(p: TextStyle(fontSize: 14.sp, height: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAISummaryDialog() {
    final summaryText = "".obs;
    final isLoading = true.obs;
    final firstLesson = _lessonController.lessons.first;

    _aiService.summarizeLessonViaGateway(
      lessonId: firstLesson.id,
      title: course.title,
      description: course.description,
    ).then((res) {
      summaryText.value = res;
      isLoading.value = false;
    });

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            SizedBox(height: 24.h),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Get.theme.primaryColor),
                SizedBox(width: 12.w),
                Text("الملخص الذكي", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Get.theme.primaryColor)),
              ],
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() => isLoading.value 
                  ? Column(
                      children: [
                        SizedBox(height: 40.h),
                        const AppLoadingIndicator(),
                        SizedBox(height: 16.h),
                        Text("جاري تحليل محتوى الكورس وتوليد الملخص...", style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp)),
                      ],
                    )
                  : Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(color: Get.isDarkMode ? Colors.white10 : AppColors.bgCanvasStart, borderRadius: BorderRadius.circular(16.r)),
                      child: MarkdownBody(
                        data: summaryText.value,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: Get.isDarkMode ? Colors.white70 : AppColors.textMain, height: 1.6, fontSize: 14.sp),
                        ),
                      ),
                    )),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(backgroundColor: Get.theme.primaryColor, padding: EdgeInsets.symmetric(vertical: 14.h)),
                child: const Text("حسناً، فهمت", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enterBottomSheetDuration: const Duration(milliseconds: 400),
    );
  }

  void _showAIQuizDialog() {
    final isLoading = true.obs;
    final firstLesson = _lessonController.lessons.first;

    _aiService.generateQuizViaGateway(
      lessonId: firstLesson.id,
      topic: course.title,
      context: course.description,
    ).then((questions) {
      _quizController.loadAIQuestions(questions);
      final aiQuiz = Quiz(
        id: "ai_temp_${DateTime.now().millisecondsSinceEpoch}",
        courseId: course.id,
        title: "اختبار ذكي: ${course.title}",
        description: "اختبار مولد بواسطة الذكاء الاصطناعي لمراجعة مفاهيم الكورس",
        questionsCount: questions.length,
        passingScore: 60,
        timeLimit: 10,
        isPublished: true,
        createdAt: DateTime.now(),
      );
      Get.back(); // Close loading sheet
      Get.to(() => QuizScreen(quiz: aiQuiz));
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل توليد الاختبار: $e", backgroundColor: AppColors.errorRed, colorText: Colors.white);
    });

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            SizedBox(height: 24.h),
            const Icon(Icons.psychology_rounded, color: AppColors.accentTeal, size: 50),
            SizedBox(height: 16.h),
            Text("جاري بناء اختبارك الخاص...", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.accentTeal)),
            SizedBox(height: 12.h),
            Text("نقوم بتحليل محتوى الكورس لتوليد أسئلة دقيقة ومناسبة لمستواك", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp)),
            SizedBox(height: 30.h),
            const AppLoadingIndicator(),
            SizedBox(height: 40.h),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("آراء الطلاب ⭐", style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
            TextButton(
              onPressed: () => _showAddReviewSheet(),
              child: Text("أضف تقييمك", style: TextStyle(color: Get.theme.primaryColor)),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Obx(() {
          if (_courseController.courseReviews.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text("لا توجد مراجعات حالياً. كن أول من يقيم!", style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp)),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _courseController.courseReviews.length,
            itemBuilder: (context, index) {
              final review = _courseController.courseReviews[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Get.theme.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(review['user'] ?? "طالب كورسيريا", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Get.theme.primaryColor)),
                        Row(
                          children: List.generate(5, (i) => Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: i < (review['rating'] ?? 0) ? Colors.amber : Colors.grey[300],
                          )),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(review['comment'] ?? "", style: TextStyle(color: Get.isDarkMode ? Colors.white70 : AppColors.textMain.withOpacity(0.7), fontSize: 12.sp, height: 1.4)),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _showAddReviewSheet() {
    final commentController = TextEditingController();
    var selectedRating = 5.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            SizedBox(height: 24.h),
            Text("كيف تقيم تجربتك؟", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Get.theme.primaryColor)),
            SizedBox(height: 20.h),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                icon: Icon(
                  index < selectedRating.value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 40,
                  color: Colors.amber,
                ),
                onPressed: () => selectedRating.value = index + 1,
              )),
            )),
            SizedBox(height: 20.h),
            TextField(
              controller: commentController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "اكتب رأيك هنا...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _courseController.submitReview(course.id, selectedRating.value.toDouble(), commentController.text);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.theme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: const Text("إرسال التقييم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
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
                color: Get.theme.primaryColor,
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
        color: Get.theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: Get.theme.primaryColor.withOpacity(0.6)),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: Get.theme.primaryColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.header.copyWith(fontSize: 18.sp),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.muted.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  Widget _buildLessonList() {
    if (_lessonController.lessons.isEmpty && !_lessonController.isLoading.value) {
      return const Center(child: Text("لا توجد دروس متاحة حالياً"));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lessonController.isLoading.value ? 5 : _lessonController.lessons.length,
      itemBuilder: (context, index) {
        if (_lessonController.isLoading.value) {
          return _buildFakeLessonTile();
        }
        final lesson = _lessonController.lessons[index];
        return _buildLessonTile(lesson);
      },
    );
  }

  Widget _buildFakeLessonTile() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      height: 80.h,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16.r)),
    );
  }

  Widget _buildLessonTile(dynamic lesson) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => Get.to(() => VideoPlayerScreen(lesson: lesson, videoUrl: lesson.videoUrl ?? "")),
        leading: Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(color: Get.theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.play_arrow_rounded, color: Get.theme.primaryColor),
        ),
        title: Text(lesson.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
        subtitle: Text("${lesson.duration} دقيقة", style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Get.theme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: const Text("اشترك الآن", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("الاختبارات التقويمية", null),
        SizedBox(height: 16.h),
        Obx(() {
          if (_quizController.isLoading.value) {
            return const CustomLoadingIndicator();
          }
          if (_quizController.quizzes.isEmpty) {
            return Text("لا توجد اختبارات متاحة حالياً لهذا الكورس.", style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp));
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quizController.quizzes.length,
            itemBuilder: (context, index) {
              final quiz = _quizController.quizzes[index];
              final result = _quizController.quizResults[quiz.id];
              return _buildQuizTile(quiz, result);
            },
          );
        }),
      ],
    );
  }

  Widget _buildQuizTile(Quiz quiz, dynamic result) {
    final bool isCompleted = result != null;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isCompleted ? (result.isPassed ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)) : Colors.transparent),
      ),
      child: ListTile(
        onTap: () {
          if (isCompleted) {
            Get.to(() => QuizResultScreen(result: result));
          } else {
            Get.to(() => QuizScreen(quiz: quiz));
          }
        },
        leading: Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: isCompleted 
                ? (result.isPassed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                : Get.theme.primaryColor.withOpacity(0.1), 
            shape: BoxShape.circle
          ),
          child: Icon(
            isCompleted ? (result.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded) : Icons.quiz_rounded, 
            color: isCompleted ? (result.isPassed ? Colors.green : Colors.red) : Get.theme.primaryColor
          ),
        ),
        title: Text(quiz.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
        subtitle: Text(
          isCompleted ? "النتيجة: ${result.percentage.toInt()}%" : "${quiz.questionsCount} سؤال • ${quiz.timeLimit ?? 'بدون وقت'}", 
          style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)
        ),
        trailing: Text(
          isCompleted ? "عرض النتيجة" : "ابدأ الآن", 
          style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12.sp)
        ),
      ),
    );
  }

  Widget _buildFinalQuizAction() {
    return const SizedBox.shrink(); // Simplified for now
  }
}
