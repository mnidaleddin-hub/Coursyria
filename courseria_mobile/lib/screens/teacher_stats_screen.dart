import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class TeacherStatsScreen extends StatelessWidget {
  const TeacherStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("إحصائيات المعلم", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            SizedBox(height: 32.h),
            Text("نمو الطلاب", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _buildBarChart(),
            SizedBox(height: 32.h),
            Text("تقييمات الكورسات", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _buildRatingList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatBox("إجمالي الطلاب", "1,250", PhosphorIcons.users(), AppColors.accentTeal),
        SizedBox(width: 16.w),
        _buildStatBox("نسبة الإكمال", "85%", PhosphorIcons.checkCircle(), Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30.sp),
            SizedBox(height: 12.h),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 200.h,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: AppColors.accentTeal)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: AppColors.accentTeal)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: AppColors.accentTeal)]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: AppColors.accentTeal)]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: AppColors.accentTeal)]),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingList() {
    return Column(
      children: [
        _buildRatingItem("كورس الرياضيات", 4.8, "250 تقييم"),
        _buildRatingItem("كورس الفيزياء", 4.5, "180 تقييم"),
      ],
    );
  }

  Widget _buildRatingItem(String title, double rating, String count) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 18.sp),
              SizedBox(width: 4.w),
              Text(rating.toString(), style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
              SizedBox(width: 8.w),
              Text(count, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
            ],
          ),
        ],
      ),
    );
  }
}
