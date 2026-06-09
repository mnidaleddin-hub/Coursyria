import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/quiz_result_model.dart';
import '../models/quiz_question_model.dart';
import '../controllers/quiz_controller.dart';
import '../core/constants/constants.dart';
import '../core/utils/confetti_utils.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_service.dart';
import '../controllers/ai_controller.dart';
import '../widgets/app_loading_indicator.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  const QuizResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final quizController = Get.find<QuizController>();
    final isPassed = result.isPassed;

    if (isPassed) {
      Future.delayed(500.ms, () => ConfettiUtils.playConfetti());
    }

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("نتيجة الاختبار"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            // Result Header Card
            _buildResultCard(context),
            SizedBox(height: 24.h),

            // AI Insights Actions
            _buildAIResultActions(context, quizController),
            SizedBox(height: 32.h),

            // Review Section
            Row(
              children: [
                Text("مراجعة الإجابات", style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
              ],
            ),
            SizedBox(height: 16.h),
            ...quizController.currentQuizQuestions.map((q) => _buildQuestionReview(context, q, quizController.userAnswers[q.id])).toList(),
            
            SizedBox(height: 40.h),
            
            // Retake Quiz Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final quiz = quizController.quizzes.firstWhereOrNull((q) => q.id == result.quizId);
                  if (quiz != null) {
                    Get.back();
                    Get.toNamed('/quiz', arguments: {'quiz': quiz});
                  } else if (result.quizId.startsWith('ai_temp_')) {
                    Get.back();
                    Get.snackbar("اختبار ذكي", "يرجى توليد اختبار ذكي جديد من شاشة الدرس.", backgroundColor: Colors.amber);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("إعادة محاولة الاختبار"),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: context.theme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Retake Quiz Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final quiz = quizController.quizzes.firstWhereOrNull((q) => q.id == result.quizId);
                  if (quiz != null) {
                    Get.back();
                    Get.toNamed('/quiz', arguments: {'quiz': quiz});
                  } else if (result.quizId.startsWith('ai_temp_')) {
                    Get.back();
                    Get.snackbar("اختبار ذكي", "يرجى توليد اختبار ذكي جديد من شاشة الدرس.", backgroundColor: Colors.amber);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("إعادة محاولة الاختبار"),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: context.theme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text("العودة للكورس"),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to review or scroll to it
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  side: BorderSide(color: context.theme.primaryColor),
                ),
                child: const Text("مراجعة الإجابات التفصيلية"),
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final isPassed = result.isPassed;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed 
              ? [AppColors.accentTeal, context.theme.primaryColor]
              : [AppColors.errorRed, Colors.redAccent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? AppColors.accentTeal : AppColors.errorRed).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
            color: Colors.white,
            size: 80.r,
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          SizedBox(height: 16.h),
          Text(
            isPassed ? "مبروك! لقد اجتزت" : "للأسف! لم تجتز",
            style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "${result.percentage.toInt()}%",
            style: TextStyle(color: Colors.white, fontSize: 48.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: Text(
              "النقاط: ${result.score} / ${result.totalPoints}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuestionReview(BuildContext context, QuizQuestion question, String? userAnswer) {
    final isCorrect = userAnswer == question.correctAnswer;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 12.h),
          _buildReviewRow(Icons.check_circle_outline, "الإجابة الصحيحة: ${question.correctAnswer}", Colors.green),
          if (!isCorrect)
            _buildReviewRow(Icons.cancel_outlined, "إجابتك: ${userAnswer ?? 'لم تتم الإجابة'}", Colors.red),
          if (question.explanation != null) ...[
            const Divider(color: Colors.white10, height: 24),
            Text(
              "التفسير: ${question.explanation}",
              style: TextStyle(fontSize: 13.sp, color: Colors.white60, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 14.sp))),
        ],
      ),
    );
  }

  Widget _buildAIResultActions(BuildContext context, QuizController controller) {
    final aiController = Get.find<AIController>();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallAIAction(
                context,
                title: "تحليل الأخطاء",
                icon: Icons.analytics_rounded,
                color: Colors.amber,
                onTap: () => _analyzeWeaknesses(controller),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildSmallAIAction(
                context,
                title: "خطة علاجية",
                icon: Icons.healing_rounded,
                color: AppColors.accentTeal,
                onTap: () => _generateRemedyPlan(controller),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: aiController.isGeneratingQuiz.value
                    ? null
                    : () {
                        final results = controller.currentQuizQuestions.map((q) => {
                              'question': q.questionText,
                              'isCorrect': controller.userAnswers[q.id] == q.correctAnswer,
                            }).toList();
                        aiController.generateSimilarQuiz(results);
                      },
                icon: aiController.isGeneratingQuiz.value
                    ? SizedBox(height: 18.h, width: 18.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.psychology_rounded),
                label: const Text("توليد اختبار مشابه لنفس المستوى"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSmallAIAction(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 8.h),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _analyzeWeaknesses(QuizController controller) {
    Get.dialog(const Center(child: AppLoadingIndicator()), barrierDismissible: false);
    final aiService = AIService();
    final results = controller.currentQuizQuestions.map((q) => {
      'question': q.questionText,
      'isCorrect': controller.userAnswers[q.id] == q.correctAnswer,
    }).toList();

    aiService.analyzeWeaknesses(results).then((analysis) {
      Get.back();
      _showAIResultSheet("تحليل نقاط الضعف (AI)", analysis);
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل تحليل الأخطاء");
    });
  }

  void _generateRemedyPlan(QuizController controller) {
    Get.dialog(const Center(child: AppLoadingIndicator()), barrierDismissible: false);
    final aiService = AIService();
    final results = controller.currentQuizQuestions.map((q) => {
      'question': q.questionText,
      'isCorrect': controller.userAnswers[q.id] == q.correctAnswer,
    }).toList();

    aiService.callAIGateway(
      feature: 'weakness_analysis',
      lessonId: 'global',
      userPrompt: "بناءً على هذه الأخطاء: ${jsonEncode(results)}، اقترح خطة دراسية علاجية دقيقة لتحسين المستوى.",
    ).then((res) {
      Get.back();
      _showAIResultSheet("خطة علاجية مقترحة 🎯", res.content);
    }).catchError((e) {
      Get.back();
      Get.snackbar("خطأ", "فشل توليد الخطة");
    });
  }

  void _showAIResultSheet(String title, String content) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
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
}
