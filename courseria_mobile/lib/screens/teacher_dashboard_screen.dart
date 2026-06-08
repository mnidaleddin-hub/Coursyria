import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/constants/constants.dart';
import '../controllers/teacher_controller.dart';
import '../controllers/ai_controller.dart';
import '../models/course_model.dart';
import 'create_course_screen.dart';
import 'upload_video_screen.dart';
import '../widgets/custom_loading.dart';
import '../widgets/pressable_scale.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherController = Get.find<TeacherController>();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("لوحة تحكم المعلم"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => teacherController.refreshDashboard(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => teacherController.refreshDashboard(),
        color: context.theme.primaryColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Stats Grid
              _buildStatsGrid(teacherController),
              SizedBox(height: 30.h),

              // 2. Action Buttons
              _buildActionButtons(),
              SizedBox(height: 30.h),

              // 2.5 AI Tools Section
              _buildAITeacherTools(),
              SizedBox(height: 30.h),

              // 3. Courses List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("كورساتي", style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
                  Obx(() => Text("${teacherController.teacherCourses.length} كورس",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp))),
                ],
              ),
              SizedBox(height: 16.h),

              // 4. Courses List
              Obx(() => Skeletonizer(
                    enabled: teacherController.isLoading.value,
                    child: teacherController.teacherCourses.isEmpty
                        ? _buildEmptyCourses()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: teacherController.teacherCourses.length,
                            itemBuilder: (context, index) {
                              final course = teacherController.teacherCourses[index];
                              return _buildCourseItem(context, course);
                            },
                          ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(TeacherController controller) {
    return Obx(() {
      final stats = controller.teacherStats;
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 15.h,
        crossAxisSpacing: 15.w,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard("الطلاب", stats['student_count'].toString(), PhosphorIcons.users(), Colors.blue),
          _buildStatCard("الكورسات", stats['course_count'].toString(), PhosphorIcons.bookOpen(), Colors.purple),
          _buildStatCard("المبيعات", stats['sales_count'].toString(), PhosphorIcons.shoppingCart(), Colors.orange),
          _buildStatCard("الأرباح",
          "${(stats['total_earnings'] ?? 0).toInt()} ل.س",
          PhosphorIcons.money(), Colors.green),
        ],
      );
    });
  }

  Widget _buildAITeacherTools() {
    final aiController = Get.find<AIController>();
    final teacherController = Get.find<TeacherController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accentTeal, size: 20),
            SizedBox(width: 8.w),
            Text("أدوات الذكاء الاصطناعي للمدرب", style: AppTextStyles.header.copyWith(fontSize: 16.sp)),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 110.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAIToolCard(
                "مساعد ذكي",
                Icons.support_agent_rounded,
                Colors.blue,
                () => _showTeacherAssistantChat(),
              ),
              _buildAIToolCard(
                "تحليل الفصل",
                Icons.analytics_rounded,
                Colors.purple,
                () => aiController.analyzeClass([teacherController.teacherStats]),
                isLoading: aiController.isAnalyzingClass,
              ),
              _buildAIToolCard(
                "أسئلة متوقعة",
                Icons.quiz_rounded,
                Colors.orange,
                () => _showExpectedQuestionsDialog(aiController),
                isLoading: aiController.isGeneratingQuestions,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIToolCard(String title, IconData icon, Color color, VoidCallback onTap, {RxBool? isLoading}) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(left: 12.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => (isLoading?.value ?? false)
                ? SizedBox(height: 24.r, width: 24.r, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 28.r)),
            SizedBox(height: 10.h),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showTeacherAssistantChat() {
    Get.toNamed('/community'); // Or a dedicated assistant chat screen
    Get.snackbar("المساعد الذكي", "يمكنك الآن طرح أي سؤال تعليمي في شات الدعم الفني المطور بالذكاء الاصطناعي");
  }

  void _showExpectedQuestionsDialog(AIController aiController) {
    final subjectController = TextEditingController();
    final gradeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("توليد أسئلة متوقعة"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: "المادة (مثلاً: رياضيات)")),
            TextField(controller: gradeController, decoration: const InputDecoration(labelText: "الصف (مثلاً: بكالوريا)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              aiController.getExpectedQuestions(subjectController.text, gradeController.text);
            },
            child: const Text("توليد"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.r),
              SizedBox(width: 8.w),
              Text(title, style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 8.h),
          FittedBox(
            child: Text(value,
                style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildMainAction(
            "إضافة كورس",
            Icons.add_box_rounded,
            Colors.indigoAccent,
            () => Get.to(() => const CreateCourseScreen()),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: _buildMainAction(
            "رفع درس",
            Icons.video_call_rounded,
            AppColors.accentTeal,
            () => Get.to(() => const UploadVideoScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildMainAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.r),
            SizedBox(height: 8.h),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, Course course) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: CachedNetworkImage(
              imageUrl: course.coverUrl,
              width: 80.r,
              height: 80.r,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.white10),
              errorWidget: (context, url, error) => Container(color: Colors.white10, child: const Icon(Icons.book)),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.white)),
                SizedBox(height: 4.h),
                Text("${course.lessons.length} دروس • ${course.price.toInt()} ل.س",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildEmptyCourses() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Icon(PhosphorIcons.folderOpen(), size: 60.r, color: Colors.white10),
          SizedBox(height: 16.h),
          Text("لا توجد كورسات بعد. ابدأ بإضافة أول كورس لك!",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp)),
        ],
      ),
    );
  }
}
