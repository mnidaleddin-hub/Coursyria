import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class StudyHabitsScreen extends StatefulWidget {
  const StudyHabitsScreen({super.key});

  @override
  State<StudyHabitsScreen> createState() => _StudyHabitsScreenState();
}

class _StudyHabitsScreenState extends State<StudyHabitsScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("العادات الدراسية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeatmapCard(),
            SizedBox(height: 32.h),
            Text("أوقات الذروة", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _buildPeakTimesList(),
            SizedBox(height: 32.h),
            _buildAITip(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white54),
          todayDecoration: BoxDecoration(color: AppColors.accentTeal.withOpacity(0.3), shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(color: AppColors.accentTeal, shape: BoxShape.circle),
        ),
        headerStyle: HeaderStyle(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          formatButtonVisible: false,
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPeakTimesList() {
    final List<Map<String, String>> peaks = [
      {'time': '09:00 PM - 11:00 PM', 'label': 'الأكثر نشاطاً', 'color': 'accentTeal'},
      {'time': '03:00 PM - 05:00 PM', 'label': 'نشاط متوسط', 'color': 'blueAccent'},
    ];

    return Column(
      children: peaks.map((peak) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peak['time']!, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  Text(peak['label']!, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                ],
              ),
              Icon(PhosphorIcons.chartBar(), color: peak['color'] == 'accentTeal' ? AppColors.accentTeal : Colors.blueAccent),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAITip() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryNavy.withOpacity(0.2), AppColors.accentTeal.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.brain(), color: AppColors.accentTeal, size: 30.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("نصيحة كورسيريا الذكية 💡", style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 4.h),
                Text(
                  "نلاحظ أن استيعابك يكون في أعلى مستوياته مساءً. ننصحك بدراسة المواد العلمية الصعبة بين 9 و 11 مساءً.",
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
