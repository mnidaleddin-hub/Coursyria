import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/constants.dart';
import '../controllers/teacher_controller.dart';
import '../widgets/custom_loading.dart';
import '../widgets/pressable_scale.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teacherController = Get.find<TeacherController>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    if (_teacherController.teacherCourses.isNotEmpty) {
      _selectedCourseId = _teacherController.teacherCourses.first.id;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedCourseId != null) {
      _teacherController.uploadLesson(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        courseId: _selectedCourseId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("رفع درس جديد")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Video Selector
              _buildVideoPicker(),
              SizedBox(height: 30.h),

              // 2. Select Course
              _buildCourseDropdown(),
              SizedBox(height: 20.h),

              // 3. Lesson Title
              _buildTextField("عنوان الدرس", _titleController, "مثال: مقدمة في التكامل", Icons.title_rounded),
              SizedBox(height: 20.h),

              // 4. Lesson Description
              _buildTextField("وصف الدرس", _descriptionController, "ماذا سيتعلم الطالب في هذا الدرس؟", Icons.description_rounded, maxLines: 3),
              SizedBox(height: 40.h),

              // 5. Submit Button
              Obx(() => PressableScale(
                onTap: _teacherController.isLoading.value ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 55.h,
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  alignment: Alignment.center,
                  child: _teacherController.isLoading.value
                      ? const CustomLoadingIndicator(color: Colors.white, size: 24)
                      : Text("بدء الرفع", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              )),
              
              if (_teacherController.isLoading.value)
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Center(child: Text("يرجى الانتظار، جاري معالجة الفيديو...", style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPicker() {
    return Obx(() {
      final file = _teacherController.selectedFile.value;
      return GestureDetector(
        onTap: () => _teacherController.pickVideo(),
        child: Container(
          height: 150.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: file != null ? AppColors.accentTeal.withOpacity(0.5) : Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                file != null ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : Icons.video_call_rounded,
                color: file != null ? AppColors.accentTeal : context.theme.primaryColor,
                size: 48.r,
              ),
              SizedBox(height: 12.h),
              Text(
                file != null ? "تم اختيار: ${file.path.split('/').last}" : "اضغط لاختيار ملف الفيديو",
                textAlign: TextAlign.center,
                style: TextStyle(color: file != null ? Colors.white : AppColors.textMuted, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCourseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("اختر الكورس", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCourseId,
              isExpanded: true,
              dropdownColor: AppColors.darkSurface,
              style: const TextStyle(color: Colors.white),
              hint: const Text("اختر الكورس المناسب", style: TextStyle(color: Colors.white24)),
              items: _teacherController.teacherCourses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
              onChanged: (val) => setState(() => _selectedCourseId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: context.theme.primaryColor, size: 20.r),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? "هذا الحقل مطلوب" : null,
        ),
      ],
    );
  }
}
