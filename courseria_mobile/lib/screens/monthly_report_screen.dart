import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("التقرير الشهري", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            SizedBox(height: 32.h),
            Text("ساعات التعلم", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _buildLineChart(),
            SizedBox(height: 32.h),
            Text("توزيع النقاط", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _buildPieChart(),
            SizedBox(height: 40.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(PhosphorIcons.shareNetwork(), size: 20.sp),
                label: const Text("مشاركة التقرير"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        _buildStatItem("إجمالي الساعات", "45", PhosphorIcons.clock(), Colors.blueAccent),
        SizedBox(width: 16.w),
        _buildStatItem("إجمالي النقاط", "2,450", PhosphorIcons.sparkle(), Colors.amber),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 12.h),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 200.h,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 3),
                const FlSpot(1, 1),
                const FlSpot(2, 4),
                const FlSpot(3, 2),
                const FlSpot(4, 5),
                const FlSpot(5, 3),
                const FlSpot(6, 4),
              ],
              isCurved: true,
              color: AppColors.accentTeal,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.accentTeal.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 200.h,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(color: Colors.blueAccent, value: 40, title: 'مشاهدة', radius: 50, titleStyle: TextStyle(color: Colors.white, fontSize: 10.sp)),
            PieChartSectionData(color: Colors.greenAccent, value: 30, title: 'تمارين', radius: 50, titleStyle: TextStyle(color: Colors.white, fontSize: 10.sp)),
            PieChartSectionData(color: Colors.amber, value: 30, title: 'تحديات', radius: 50, titleStyle: TextStyle(color: Colors.white, fontSize: 10.sp)),
          ],
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
