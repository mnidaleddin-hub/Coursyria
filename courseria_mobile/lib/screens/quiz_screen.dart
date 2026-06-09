import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/ai_controller.dart';
import '../models/quiz_model.dart';
import '../core/constants/constants.dart';
import '../widgets/custom_loading.dart';
import '../widgets/pressable_scale.dart';

import '../services/ai_service.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizController _quizController = Get.find<QuizController>();
  final AIController _aiController = Get.find<AIController>();
  final TextEditingController _essayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.quiz.id.startsWith('ai_temp_')) {
      // Questions are already loaded via loadAIQuestions in CourseDetailsScreen
      _quizController.startQuizSession(widget.quiz);
    } else {
      _quizController.fetchQuizQuestions(widget.quiz.id).then((_) {
        _quizController.startQuizSession(widget.quiz);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          Obx(() => Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    _formatTime(_quizController.timerSeconds.value),
                    style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'monospace'),
                  ),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (_quizController.isLoading.value) {
          return const CustomLoadingIndicator();
        }

        if (_quizController.currentQuizQuestions.isEmpty) {
          return const Center(child: Text("لا توجد أسئلة لهذا الاختبار حالياً."));
        }

        final currentIndex = _quizController.currentQuestionIndex.value;
        final question = _quizController.currentQuizQuestions[currentIndex];
        final totalQuestions = _quizController.currentQuizQuestions.length;

        return Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (currentIndex + 1) / totalQuestions,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(context.theme.primaryColor),
              minHeight: 6.h,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "سؤال ${currentIndex + 1} من $totalQuestions",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            question.questionText,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _quizController.isStarred(question.id) ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: _quizController.isStarred(question.id) ? Colors.amber : Colors.white24,
                              ),
                              onPressed: () => _quizController.toggleStar(question.id),
                              tooltip: "تمييز السؤال",
                            ),
                            IconButton(
                              icon: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber),
                              onPressed: () => _showAIHint(question.questionText, question.options),
                              tooltip: "تلميحة ذكية (AI)",
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    
                    // Options or Essay Input
                    if (question.questionType == 'essay')
                      _buildEssayInput(question)
                    else
                      ...question.options.map((option) => _buildOptionCard(option, question.id)).toList(),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            _buildNavigationRow(totalQuestions),
          ],
        );
      }),
    );
  }

  Widget _buildEssayInput(dynamic question) {
    return Column(
      children: [
        TextField(
          controller: _essayController,
          maxLines: 8,
          style: const TextStyle(color: Colors.white),
          onChanged: (val) => _quizController.saveAnswer(question.id, val),
          decoration: InputDecoration(
            hintText: "اكتب إجابتك هنا بالتفصيل...",
            hintStyle: TextStyle(color: Colors.white30, fontSize: 14.sp),
            fillColor: Colors.white.withOpacity(0.05),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
          ),
        ),
        SizedBox(height: 20.h),
        Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aiController.isGradingEssay.value
                    ? null
                    : () => _aiController.gradeEssayAnswer(question.questionText, _essayController.text),
                icon: _aiController.isGradingEssay.value
                    ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: const Text("تصحيح ذكي فوري"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildOptionCard(String option, String questionId) {
    return Obx(() {
      final isSelected = _quizController.userAnswers[questionId] == option;
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: PressableScale(
          onTap: () => _quizController.saveAnswer(questionId, option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isSelected ? context.theme.primaryColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? context.theme.primaryColor : Colors.white10,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? context.theme.primaryColor : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(child: Container(width: 12.r, height: 12.r, decoration: BoxDecoration(shape: BoxShape.circle, color: context.theme.primaryColor)))
                      : null,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavigationRow(int totalQuestions) {
    final currentIndex = _quizController.currentQuestionIndex.value;
    final isLast = currentIndex == totalQuestions - 1;

    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _quizController.currentQuestionIndex.value--,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: context.theme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text("السابق"),
              ),
            ),
          if (currentIndex > 0) SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  _showConfirmSubmitDialog();
                } else {
                  _quizController.currentQuestionIndex.value++;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(isLast ? "إنهاء الاختبار" : "التالي"),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmSubmitDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.theme.cardColor,
        title: const Text("إنهاء الاختبار"),
        content: const Text("هل أنت متأكد من رغبتك في تسليم الإجابات وإنهاء الاختبار الآن؟"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _quizController.submitQuiz(widget.quiz.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.theme.primaryColor),
            child: const Text("تسليم"),
          ),
        ],
      ),
    );
  }

  void _showAIHint(String question, List<String> options) {
    Get.dialog(const Center(child: CustomLoadingIndicator(color: Colors.amber)), barrierDismissible: false);
    final aiService = AIService();
    aiService.getQuizHint(question, options).then((hint) {
      Get.back();
      Get.bottomSheet(
        Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(color: context.theme.cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Colors.amber),
                  SizedBox(width: 12.w),
                  Text("تلميحة ذكية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
              SizedBox(height: 16.h),
              Text(hint, style: TextStyle(fontSize: 14.sp, height: 1.5, color: Colors.white70)),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text("شكراً، فهمت", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل الحصول على التلميحة");
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }
}
