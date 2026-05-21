import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import '../controllers/auth_controller.dart';

class JoinTeamScreen extends StatelessWidget {
  JoinTeamScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvasStart,
      appBar: AppBar(
        title: Text("انضم إلى فريقنا",
            style: AppTextStyles.header.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 32.h),
              _buildTextField(
                  "الاسم الكامل", _nameController, Icons.person_outlined),
              SizedBox(height: 16.h),
              _buildTextField("التخصص (معلم، مصور، مدير محتوى)",
                  _specController, Icons.work_outlined),
              SizedBox(height: 16.h),
              _buildTextField(
                  "المدينة", _cityController, Icons.location_on_outlined),
              SizedBox(height: 16.h),
              _buildTextField("نبذة تعريفية عن خبراتك", _bioController,
                  Icons.description_outlined,
                  maxLines: 4),
              SizedBox(height: 40.h),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
              color: AppColors.primaryNavy.withOpacity(0.05),
              shape: BoxShape.circle),
          child: Icon(Icons.group_add_rounded,
              size: 50.r, color: AppColors.accentTeal),
        ),
        SizedBox(height: 20.h),
        Text(
          "كن جزءاً من رحلة النجاح",
          style: AppTextStyles.header.copyWith(fontSize: 22.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Text(
          "نبحث دائماً عن المبدعين والمتحمسين لتطوير التعليم في سوريا. املأ النموذج وسيتواصل معك فريقنا.",
          style: AppTextStyles.body
              .copyWith(fontSize: 14.sp, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryNavy.withOpacity(0.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "هذا الحقل مطلوب" : null,
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => ElevatedButton(
          onPressed:
              _authController.isLoading.value ? null : _submitApplication,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
          ),
          child: _authController.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("إرسال طلب الانضمام",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
        ));
  }

  void _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      try {
        _authController.isLoading.value = true;
        final response = await _authController.dio
            .post('/admin/team-application', queryParameters: {
          "full_name": _nameController.text,
          "specialization": _specController.text,
          "city": _cityController.text,
          "bio": _bioController.text,
        });

        Get.back();
        Get.snackbar("تم بنجاح", response.data['message'],
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1));
      } catch (e) {
        Get.snackbar("خطأ", "فشل إرسال الطلب، يرجى المحاولة لاحقاً");
      } finally {
        _authController.isLoading.value = false;
      }
    }
  }
}
