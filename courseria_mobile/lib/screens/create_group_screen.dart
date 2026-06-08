import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../controllers/group_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final GroupController _groupController = Get.find<GroupController>();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isPrivate = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _groupController.createGroup(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _isPrivate,
        coverImage: _selectedImage,
      ).then((_) => Get.back());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("إنشاء مجموعة جديدة", style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 18.sp)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.cameraPlus(), color: AppColors.accentTeal, size: 40.r),
                            SizedBox(height: 10.h),
                            Text("إضافة صورة غلاف", style: AppTextStyles.body.copyWith(color: Colors.white70)),
                          ],
                        )
                      : null,
                ),
              ),
              SizedBox(height: 30.h),
              
              // Group Name
              Text("اسم المجموعة", style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 16.sp)),
              SizedBox(height: 10.h),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration("مثال: مبرمجي فلاتر العرب"),
                validator: (value) => value == null || value.isEmpty ? "يرجى إدخال اسم المجموعة" : null,
              ),
              SizedBox(height: 20.h),
              
              // Description
              Text("وصف المجموعة", style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 16.sp)),
              SizedBox(height: 10.h),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _buildInputDecoration("تحدث قليلاً عن هدف المجموعة..."),
                validator: (value) => value == null || value.isEmpty ? "يرجى إدخال وصف للمجموعة" : null,
              ),
              SizedBox(height: 20.h),
              
              // Privacy Toggle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPrivate ? PhosphorIcons.lockSimple() : PhosphorIcons.globeHemisphereWest(),
                      color: _isPrivate ? Colors.orangeAccent : AppColors.accentTeal,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("مجموعة خاصة", style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 14.sp)),
                          Text(
                            _isPrivate ? "الانضمام عبر كود دعوة فقط" : "يمكن لأي شخص الانضمام",
                            style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPrivate,
                      onChanged: (val) => setState(() => _isPrivate = val),
                      activeColor: AppColors.accentTeal,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              
              // Submit Button
              Obx(() => ElevatedButton(
                onPressed: _groupController.isLoadingGroups.value ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  minimumSize: Size(double.infinity, 55.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  elevation: 5,
                ),
                child: _groupController.isLoadingGroups.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("إنشاء المجموعة", style: AppTextStyles.button.copyWith(fontSize: 18.sp, color: Colors.white)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: Colors.white38),
      filled: true,
      fillColor: AppColors.primaryNavy.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: AppColors.accentTeal),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
    );
  }
}
