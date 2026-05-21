import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import '../models/course_model.dart';

class InteractiveQuizSheet extends StatefulWidget {
  final Lesson lesson;
  final List<QuizQuestion> questions;

  const InteractiveQuizSheet({
    super.key,
    required this.lesson,
    required this.questions,
  });

  @override
  State<InteractiveQuizSheet> createState() => _InteractiveQuizSheetState();

  static void show(Lesson lesson) {
    if (lesson.quizQuestions.isEmpty) {
      Get.snackbar("تنبيه", "لا يوجد اختبار متوفر لهذا الدرس حالياً", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.bottomSheet(
      InteractiveQuizSheet(lesson: lesson, questions: lesson.quizQuestions),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _InteractiveQuizSheetState extends State<InteractiveQuizSheet> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  bool _isFinished = false;

  void _handleOptionSelect(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedOption = index;
      _isAnswered = true;
      if (index == widget.questions[_currentIndex].correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.85.sh,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Expanded(
            child: _isFinished ? _buildResultView() : _buildQuizView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildQuizView() {
    final question = widget.questions[_currentIndex];
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "السؤال ${_currentIndex + 1} من ${widget.questions.length}",
                style: AppTextStyles.muted.copyWith(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(color: AppColors.accentTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
                child: Text("النتيجة: $_score", style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: AppColors.bgCanvasEnd,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            question.questionText,
            style: AppTextStyles.header.copyWith(fontSize: 18.sp),
          ),
          SizedBox(height: 24.h),
          ...List.generate(question.options.length, (index) => _buildOptionCard(index, question.options[index])),
          const Spacer(),
          if (_isAnswered) _buildExplanation(question.explanation),
          SizedBox(height: 20.h),
          if (_isAnswered)
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                minimumSize: Size(double.infinity, 52.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text(_currentIndex == widget.questions.length - 1 ? "إنهاء الاختبار" : "السؤال التالي", style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, String text) {
    bool isSelected = _selectedOption == index;
    bool isCorrect = index == widget.questions[_currentIndex].correctOptionIndex;
    
    Color bgColor = Colors.white;
    Color borderColor = AppColors.bgCanvasEnd;
    
    if (_isAnswered) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
      } else if (isSelected) {
        bgColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      borderColor = AppColors.accentTeal;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _handleOptionSelect(index),
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade400),
                  color: isSelected ? (isCorrect && _isAnswered ? Colors.green : (_isAnswered ? Colors.red : AppColors.accentTeal)) : Colors.transparent,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              ),
              SizedBox(width: 12.w),
              Expanded(child: Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryNavy.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.accentTeal, size: 20),
              SizedBox(width: 8.w),
              Text("شرح الحل:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.primaryNavy)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(text, style: TextStyle(fontSize: 12.sp, color: AppColors.textMain, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    double percentage = (_score / widget.questions.length) * 100;
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            percentage >= 50 ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
            size: 80.r,
            color: percentage >= 50 ? Colors.amber : Colors.grey,
          ),
          SizedBox(height: 24.h),
          Text(
            percentage >= 50 ? "عمل رائع!" : "حاول مرة أخرى",
            style: AppTextStyles.header.copyWith(fontSize: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            "لقد أجبت على $_score أسئلة بشكل صحيح من أصل ${widget.questions.length}",
            textAlign: TextAlign.center,
            style: AppTextStyles.muted.copyWith(fontSize: 16.sp),
          ),
          SizedBox(height: 40.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.bgCanvasStart,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("النسبة", "${percentage.toStringAsFixed(0)}%"),
                _buildStatItem("الدرجة", "$_score/${widget.questions.length}"),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              minimumSize: Size(double.infinity, 52.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: const Text("العودة للدرس", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.muted.copyWith(fontSize: 12.sp)),
        SizedBox(height: 4.h),
        Text(value, style: AppTextStyles.header.copyWith(fontSize: 20.sp, color: AppColors.primaryNavy)),
      ],
    );
  }
}
