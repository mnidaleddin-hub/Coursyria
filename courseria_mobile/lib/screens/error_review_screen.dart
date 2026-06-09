import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/exam_simulator_controller.dart';
import '../core/constants/constants.dart';

class ErrorReviewScreen extends GetView<ExamSimulatorController> {
  const ErrorReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incorrectQuestions = controller.questions.where((q) {
      return controller.userAnswers[q.id] != q.correctAnswer;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: const Text("مراجعة الأخطاء", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryNavy,
      ),
      body: incorrectQuestions.isEmpty
          ? const Center(child: Text("لا توجد أخطاء! أحسنت", style: TextStyle(color: Colors.white)))
          : ListView.builder(
              padding: EdgeInsets.all(20.w),
              itemCount: incorrectQuestions.length,
              itemBuilder: (context, index) {
                final question = incorrectQuestions[index];
                return _buildErrorCard(question, index + 1);
              },
            ),
    );
  }

  Widget _buildErrorCard(dynamic question, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("سؤال $index", style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
          SizedBox(height: 10.h),
          Text(question.questionText, style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          SizedBox(height: 20.h),
          
          _buildAnswerRow("إجابتك:", controller.userAnswers[question.id] ?? "لم يتم الحل", Colors.red, Icons.close),
          SizedBox(height: 10.h),
          _buildAnswerRow("الإجابة الصحيحة:", question.correctAnswer, Colors.green, Icons.check),
          
          if (question.explanation != null) ...[
            SizedBox(height: 20.h),
            Text("الشرح:", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
            Text(question.explanation!, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ],
          
          SizedBox(height: 20.h),
          Row(
            children: [
              if (question.videoExplanationUrl != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logic for Feature 60: Play short explanation
                    },
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text("فيديو شرح قصير"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  ),
                ),
              if (question.videoExplanationUrl != null) SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Logic for Feature 61: Go to specific timestamp in full video
                  },
                  icon: const Icon(Icons.link, color: AppColors.accentTeal),
                  label: const Text("شاهد الفقرة بالدرس", style: TextStyle(color: AppColors.accentTeal)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentTeal)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String label, String text, Color color, IconData icon) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        SizedBox(width: 10.w),
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 4.w),
        Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14.sp))),
      ],
    );
  }
}
