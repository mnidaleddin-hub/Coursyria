import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controllers/quiz_controller.dart';
import '../core/constants/constants.dart';
import '../models/quiz_model.dart';

class QuizPlayScreen extends StatelessWidget {
  final QuizController _controller = Get.put(QuizController());

  QuizPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Obx(() {
        if (_controller.isLoading.value) {
          return _buildLoadingState();
        }
        
        if (_controller.questions.isEmpty) {
          return _buildEmptyState();
        }

        bool isFinished = _controller.isAnswered.value && 
                         _controller.currentIndex.value == _controller.questions.length - 1 &&
                         _controller.selectedIndex.value != -1;
        
        // Logic to show result screen if all questions answered
        if (_controller.currentIndex.value == _controller.questions.length - 1 && _controller.isAnswered.value) {
           // We'll show the last question result first, then user clicks next to see final result.
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                _buildHeader(),
                SizedBox(height: 40.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildQuestionCard(_controller.questions[_controller.currentIndex.value]),
                        SizedBox(height: 30.h),
                        _buildOptionsList(_controller.questions[_controller.currentIndex.value]),
                        if (_controller.isAnswered.value) _buildExplanationBox(_controller.questions[_controller.currentIndex.value]),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accentTeal),
          SizedBox(height: 24.h),
          Text(
            "جاري توليد الاختبار بالذكاء الاصطناعي...",
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "نجهز لك أسئلة فريدة لتحدي مهاراتك 🚀",
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("فشل في تحميل الأسئلة. حاول مرة أخرى.", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildHeader() {
    double progress = (_controller.currentIndex.value + 1) / _controller.questions.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.amber, size: 18),
                  SizedBox(width: 8.w),
                  Text(
                    "${_controller.timerSeconds.value} ثانية",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Text(
              "السؤال ${_controller.currentIndex.value + 1}/${_controller.questions.length}",
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
            minHeight: 8.h,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        question.question,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600, height: 1.5),
      ),
    );
  }

  Widget _buildOptionsList(QuizQuestion question) {
    return Column(
      children: List.generate(question.options.length, (index) {
        bool isSelected = _controller.selectedIndex.value == index;
        bool isCorrect = index == question.correctIndex;
        bool isAnswered = _controller.isAnswered.value;

        Color borderColor = Colors.white.withOpacity(0.1);
        Color bgColor = AppColors.secondaryNavy;
        Widget? suffixIcon;

        if (isAnswered) {
          if (isCorrect) {
            borderColor = Colors.green;
            bgColor = Colors.green.withOpacity(0.1);
            suffixIcon = const Icon(Icons.check_circle, color: Colors.green);
          } else if (isSelected) {
            borderColor = Colors.red;
            bgColor = Colors.red.withOpacity(0.1);
            suffixIcon = const Icon(Icons.cancel, color: Colors.red);
          }
        } else if (isSelected) {
          borderColor = AppColors.accentTeal;
        }

        return GestureDetector(
          onTap: () => _controller.submitAnswer(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 30.r,
                  height: 30.r,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentTeal : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Text(
                    question.options[index],
                    style: TextStyle(color: Colors.white, fontSize: 15.sp),
                  ),
                ),
                if (suffixIcon != null) suffixIcon,
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildExplanationBox(QuizQuestion question) {
    bool isCorrect = _controller.selectedIndex.value == question.correctIndex;
    if (isCorrect) return const SizedBox.shrink();

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              margin: EdgeInsets.only(top: 20.h),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8.w),
                      Text("التوضيح العلمي", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    question.explanation,
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction() {
    if (!_controller.isAnswered.value) return const SizedBox.shrink();

    bool isLast = _controller.currentIndex.value == _controller.questions.length - 1;

    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: () {
          if (isLast) {
            _showResultDialog();
          } else {
            _controller.nextQuestion();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          isLast ? "عرض النتيجة النهائية" : "السؤال التالي",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
      ),
    );
  }

  void _showResultDialog() {
    double percentage = (_controller.correctAnswers.value / _controller.questions.length) * 100;
    bool isPassed = percentage >= 75;

    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppColors.secondaryNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                  size: 80.r,
                  color: isPassed ? Colors.amber : Colors.redAccent,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                isPassed ? "تهانينا يا بطل! 🎉" : "حاول مرة أخرى! 💪",
                style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              Text(
                "لقد أجبت على ${_controller.correctAnswers.value} من أصل ${_controller.questions.length}",
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                "${percentage.toInt()}%",
                style: TextStyle(
                  color: isPassed ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isPassed) 
                Text(
                  "لقد ربحت 100 نقطة إضافية! 💎",
                  style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        _controller.startQuiz(
                          type: _controller.quizType,
                          topicName: _controller.topic,
                          cId: _controller.courseId,
                          lId: _controller.lessonId,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accentTeal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("إعادة بأسئلة جديدة", style: TextStyle(color: AppColors.accentTeal)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close dialog
                        Get.back(); // Return to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("إنهاء", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
