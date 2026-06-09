import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/exam_simulator_controller.dart';
import '../core/constants/constants.dart';

class ExamResultScreen extends GetView<ExamSimulatorController> {
  const ExamResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final percentage = (score / controller.questions.length) * 100;
    
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: const Text("نتائج الامتحان", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryNavy,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildScoreCircle(percentage),
            SizedBox(height: 30.h),
            _buildStatisticsRow(score),
            SizedBox(height: 30.h),
            _buildSkillChart(),
            SizedBox(height: 30.h),
            _buildAiFeedback(percentage),
            SizedBox(height: 40.h),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  int _calculateScore() {
    int score = 0;
    for (var q in controller.questions) {
      if (controller.userAnswers[q.id] == q.correctAnswer) {
        score++;
      }
    }
    return score;
  }

  Widget _buildScoreCircle(double percentage) {
    final color = percentage >= 60 ? Colors.green : Colors.red;
    return Column(
      children: [
        SizedBox(
          height: 150.r,
          width: 150.r,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: percentage,
                  color: color,
                  radius: 15.r,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - percentage,
                  color: Colors.white10,
                  radius: 15.r,
                  showTitle: false,
                ),
              ],
              centerSpaceRadius: 50.r,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -95),
          child: Column(
            children: [
              Text("${percentage.toInt()}%", style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
              Text(percentage >= 60 ? "ناجح" : "راسب", style: TextStyle(color: color, fontSize: 14.sp)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsRow(int score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("الصح", score.toString(), Colors.green),
        _buildStatItem("الخطأ", (controller.questions.length - score).toString(), Colors.red),
        _buildStatItem("الوقت", "45 د", Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildSkillChart() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: AppColors.secondaryNavy, borderRadius: BorderRadius.circular(20.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("توزيع الأداء حسب المهارة", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 20.h),
          SizedBox(
            height: 150.h,
            child: BarChart(
              BarChartData(
                barGroups: [
                  _makeGroupData(0, 70, Colors.blue), // فهم
                  _makeGroupData(1, 40, Colors.green), // تطبيق
                  _makeGroupData(2, 20, Colors.orange), // تحليل
                  _makeGroupData(3, 10, Colors.purple), // تركيب
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const titles = ['فهم', 'تطبيق', 'تحليل', 'تركيب'];
                        return Text(titles[val.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: color, width: 15.w, borderRadius: BorderRadius.circular(4.r))],
    );
  }

  Widget _buildAiFeedback(double percentage) {
    String msg = percentage >= 90 
      ? "أداء مذهل! أنت مستعد تماماً للامتحان الرسمي."
      : percentage >= 60 
        ? "أداء جيد، ولكن تحتاج للتركيز أكثر على مهارات التحليل."
        : "لا تقلق، هذا الامتحان للتعلم. ركز على مراجعة الأخطاء الموضحة أدناه.";

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined, color: AppColors.accentTeal, size: 40),
          SizedBox(width: 16.w),
          Expanded(child: Text(msg, style: TextStyle(color: Colors.white, fontSize: 14.sp))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55.h,
          child: ElevatedButton(
            onPressed: () => Get.toNamed('/exam-error-review'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
            child: const Text("مراجعة الأخطاء وتصحيح المسار", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: () => Get.offAllNamed('/home'),
          child: const Text("العودة للرئيسية", style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
