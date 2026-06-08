import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/constants.dart';
import '../controllers/teacher_controller.dart';
import '../widgets/custom_loading.dart';
import '../widgets/pressable_scale.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teacherController = Get.find<TeacherController>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedSubject = "الرياضيات";
  String _selectedGrade = "الثالث الثانوي";
  File? _imageFile;

  final List<String> _subjects = ["الرياضيات", "الفيزياء", "الكيمياء", "اللغة العربية", "اللغة الإنجليزية", "العلوم"];
  final List<String> _grades = ["الأول الثانوي", "الثاني الثانوي", "الثالث الثانوي"];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _teacherController.createCourse(
        title: _titleController.text.trim(),
        subject: _selectedSubject,
        gradeLevel: _selectedGrade,
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descriptionController.text.trim(),
        imageFile: _imageFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("إنشاء كورس جديد")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              _buildImagePicker(),
              SizedBox(height: 30.h),

              // Title
              _buildTextField("عنوان الكورس", _titleController, "مثال: مكثفة الفيزياء 2024", Icons.title_rounded),
              SizedBox(height: 20.h),

              // Description
              _buildTextField("وصف الكورس", _descriptionController, "تحدث عن محتوى الكورس وما سيستفيده الطالب...", Icons.description_rounded, maxLines: 4),
              SizedBox(height: 20.h),

              // Dropdowns Row
              Row(
                children: [
                  Expanded(child: _buildDropdown("المادة", _selectedSubject, _subjects, (val) => setState(() => _selectedSubject = val!))),
                  SizedBox(width: 15.w),
                  Expanded(child: _buildDropdown("الصف", _selectedGrade, _grades, (val) => setState(() => _selectedGrade = val!))),
                ],
              ),
              SizedBox(height: 20.h),

              // Price
              _buildTextField("السعر (ل.س)", _priceController, "0", Icons.payments_rounded, keyboardType: TextInputType.number),
              SizedBox(height: 40.h),

              // Submit Button
              Obx(() => PressableScale(
                onTap: _teacherController.isLoading.value ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 55.h,
                  decoration: BoxDecoration(
                    color: context.theme.primaryColor,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  alignment: Alignment.center,
                  child: _teacherController.isLoading.value
                      ? const CustomLoadingIndicator(color: Colors.white, size: 24)
                      : Text("نشر الكورس", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              )),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white10),
          image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
        ),
        child: _imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded, color: context.theme.primaryColor, size: 40.r),
                  SizedBox(height: 12.h),
                  Text("إضافة صورة غلاف", style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp)),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.darkSurface,
              style: const TextStyle(color: Colors.white),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
