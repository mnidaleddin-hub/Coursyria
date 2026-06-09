import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/exam_simulator_controller.dart';
import '../core/constants/constants.dart';

class ExamSimulatorScreen extends GetView<ExamSimulatorController> {
  const ExamSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.handleAppExitAttempt();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        appBar: _buildAppBar(),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
          }
          if (controller.questions.isEmpty) {
            return const Center(child: Text("لا توجد أسئلة", style: TextStyle(color: Colors.white)));
          }
          return _buildBody();
        }),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.secondaryNavy,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(controller.currentQuiz.value?.title ?? "امتحان", 
            style: TextStyle(fontSize: 16.sp, color: Colors.white)),
          Obx(() => Text(
            "السؤال ${controller.currentQuestionIndex.value + 1} من ${controller.questions.length}",
            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
          )),
        ],
      ),
      actions: [
        _buildTimer(),
        SizedBox(width: 10.w),
      ],
    );
  }

  Widget _buildTimer() {
    return Obx(() {
      final seconds = controller.remainingSeconds.value;
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final s = seconds % 60;
      
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: controller.timerColor.value.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: controller.timerColor.value),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, size: 16.sp, color: controller.timerColor.value),
            SizedBox(width: 6.w),
            Text(
              "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}",
              style: TextStyle(
                color: controller.timerColor.value,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBody() {
    final question = controller.questions[controller.currentQuestionIndex.value];
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty & Skill Badge
          Row(
            children: [
              _buildBadge(question.difficulty, Colors.amber),
              SizedBox(width: 8.w),
              _buildBadge(question.skillType, Colors.blue),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Question Text
          Text(
            question.questionText,
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600, height: 1.5),
          ),
          SizedBox(height: 30.h),
          
          // Options
          ...question.options.asMap().entries.map((entry) {
            final option = entry.value;
            return _buildOption(option);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.sp)),
    );
  }

  Widget _buildOption(String option) {
    final questionId = controller.questions[controller.currentQuestionIndex.value].id;
    return Obx(() {
      final isSelected = controller.userAnswers[questionId] == option;
      return GestureDetector(
        onTap: () => controller.userAnswers[questionId] = option,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentTeal : AppColors.secondaryNavy,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white10,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            option,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.all(20.w),
      color: AppColors.secondaryNavy,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => controller.currentQuestionIndex.value > 0
            ? TextButton(
                onPressed: controller.prevQuestion,
                child: const Text("السابق", style: TextStyle(color: Colors.white70)),
              )
            : const SizedBox(width: 80)),
          
          Obx(() => controller.currentQuestionIndex.value == controller.questions.length - 1
            ? ElevatedButton(
                onPressed: controller.submitExam,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("إنهاء الامتحان", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : ElevatedButton(
                onPressed: controller.nextQuestion,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
                child: const Text("التالي", style: TextStyle(color: Colors.white)),
              )),
        ],
      ),
    );
  }
}
