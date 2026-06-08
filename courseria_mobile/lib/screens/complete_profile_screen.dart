import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';
import '../controllers/auth_controller.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  int _currentStep = 0;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  String? _selectedGrade;
  String? _selectedBranch;

  final List<String> _grades = ["تاسع", "عاشر", "حادي عشر", "بكالوريا"];
  final List<String> _branches = ["علمي", "أدبي", "عام"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("إكمال الملف الشخصي", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: AppColors.darkBg,
          colorScheme: const ColorScheme.dark(primary: AppColors.accentTeal, secondary: AppColors.accentTeal),
        ),
        child: Stepper(
          physics: const BouncingScrollPhysics(),
          elevation: 0,
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _handleContinue,
          onStepCancel: () => _currentStep > 0 ? setState(() => _currentStep--) : null,
          controlsBuilder: _buildStepControls,
          steps: [
            _buildPersonalStep(),
            _buildAcademicStep(),
            _buildFinalStep(),
          ],
        ),
      ),
    );
  }

  Step _buildPersonalStep() {
    return Step(
      title: Text("المعلومات الأساسية", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey1,
        child: Column(
          children: [
            _buildInputField(
              label: "الاسم الثلاثي",
              controller: _authController.nameController,
              icon: PhosphorIcons.user(),
              validator: (v) => v!.length < 5 ? "يرجى إدخال اسمك الحقيقي" : null,
            ),
            SizedBox(height: 16.h),
            _buildInputField(
              label: "رقم هاتف ولي الأمر",
              controller: TextEditingController(), // Placeholder for now
              icon: PhosphorIcons.phoneCall(),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.editing,
    );
  }

  Step _buildAcademicStep() {
    return Step(
      title: Text("المرحلة الدراسية", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey2,
        child: Column(
          children: [
            _buildDropdownField("الصف الدراسي", _grades, _selectedGrade, (val) => setState(() => _selectedGrade = val)),
            SizedBox(height: 16.h),
            _buildDropdownField("الفرع", _branches, _selectedBranch, (val) => setState(() => _selectedBranch = val)),
          ],
        ),
      ),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : _currentStep == 1 ? StepState.editing : StepState.indexed,
    );
  }

  Step _buildFinalStep() {
    return Step(
      title: Text("تأكيد البيانات", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
      content: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Column(
              children: [
                _buildSummaryRow("الاسم:", _authController.nameController.text),
                _buildSummaryRow("الصف:", _selectedGrade ?? "لم يحدد"),
                _buildSummaryRow("الفرع:", _selectedBranch ?? "لم يحدد"),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "بضغطك على إتمام، أنت توافق على شروط وأحكام منصة كورسيريا التعليمية.",
            style: TextStyle(color: Colors.white38, fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      isActive: _currentStep >= 2,
      state: _currentStep == 2 ? StepState.editing : StepState.indexed,
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required IconData icon, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: AppColors.accentTeal),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.darkSurface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStepControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text(_currentStep == 2 ? "إتمام الملف" : "التالي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            ),
          ),
          if (_currentStep > 0) ...[
            SizedBox(width: 16.w),
            Expanded(
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text("السابق"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      if (_formKey1.currentState!.validate()) setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_formKey2.currentState!.validate()) {
        if (_selectedGrade == null) {
          Get.snackbar("تنبيه", "يرجى اختيار الصف الدراسي", backgroundColor: Colors.amber, colorText: Colors.black);
          return;
        }
        setState(() => _currentStep++);
      }
    } else {
      _finishProfile();
    }
  }

  Future<void> _finishProfile() async {
    // Call controller to update profile
    Get.offAllNamed('/home');
    Get.snackbar("مرحباً بك!", "تم إكمال ملفك الشخصي بنجاح", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
  }
}
