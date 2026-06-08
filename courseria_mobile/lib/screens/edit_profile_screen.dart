import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();
  String? _selectedGradeLevel;

  final List<String> _gradeLevels = [
    "ابتدائي",
    "إعدادي",
    "ثانوي (علمي)",
    "ثانوي (أدبي)",
    "جامعي",
    "دراسات عليا",
    "أخرى",
  ];

  @override
  void initState() {
    super.initState();
    // Load current user data into controllers
    final userProfile = _authController.userProfile.value;
    _fullNameController.text = _authController.userData['name'] ?? '';
    if (userProfile != null) {
      _bioController.text = userProfile.bio ?? '';
      _interestsController.text = userProfile.interests?.join(', ') ?? '';
      _selectedGradeLevel = userProfile.gradeLevel;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final Map<String, dynamic> data = {
      'full_name': _fullNameController.text.trim(),
      'bio': _bioController.text.trim(),
      'grade_level': _selectedGradeLevel,
      'interests': _interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };

    await _authController.updateUserProfile(data);
    Get.back(); // Go back to profile screen after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "تعديل الملف الشخصي",
          style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 20.sp),
        ),
        backgroundColor: AppColors.primaryNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgCanvasStart, AppColors.bgCanvasEnd],
          ),
        ),
        child: Obx(() {
          final userProfile = _authController.userProfile.value;
          if (userProfile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentTeal),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _fullNameController,
                  labelText: "الاسم الكامل",
                  hintText: "أدخل اسمك الكامل",
                  icon: Icons.person_rounded,
                ),
                SizedBox(height: 20.h),
                _buildDropdownField(
                  labelText: "المرحلة الدراسية",
                  icon: Icons.school_rounded,
                  value: _selectedGradeLevel,
                  items: _gradeLevels.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGradeLevel = newValue;
                    });
                  },
                ),
                SizedBox(height: 20.h),
                _buildTextField(
                  controller: _bioController,
                  labelText: "السيرة الذاتية",
                  hintText: "اكتب نبذة عن نفسك...",
                  icon: Icons.info_outline_rounded,
                  maxLines: 5,
                ),
                SizedBox(height: 20.h),
                _buildTextField(
                  controller: _interestsController,
                  labelText: "الاهتمامات (بفواصل ,)",
                  hintText: "الرياضة، البرمجة، الفن...",
                  icon: Icons.interests_rounded,
                ),
                SizedBox(height: 40.h),
                ElevatedButton(
                  onPressed: _authController.isLoading.value ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r)),
                  ),
                  child: _authController.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "حفظ التغييرات",
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.body.copyWith(color: AppColors.textMain),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.primaryNavy),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildDropdownField<T>( {
    required String labelText,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.transparent), // To match TextField style
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryNavy, size: 24.r),
          style: AppTextStyles.body.copyWith(color: AppColors.textMain),
          hint: Text(labelText, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.surfaceWhite,
        ),
      ),
    );
  }
}
