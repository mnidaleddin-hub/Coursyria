import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import '../controllers/wallet_controller.dart';

class CourseRequestScreen extends StatefulWidget {
  const CourseRequestScreen({super.key});

  @override
  State<CourseRequestScreen> createState() => _CourseRequestScreenState();
}

class _CourseRequestScreenState extends State<CourseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;
  final _walletController = Get.find<WalletController>();

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvasStart,
      appBar: AppBar(
        title: Text("طلب كورس مجاني",
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
                  "لماذا تطلب هذا الكورس مجاناً؟", _reasonController, Icons.help_outline,
                  maxLines: 6),
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
          child: Icon(Icons.volunteer_activism_rounded,
              size: 50.r, color: AppColors.accentTeal),
        ),
        SizedBox(height: 20.h),
        Text(
          "طلب كورس مسبب",
          style: AppTextStyles.header.copyWith(fontSize: 22.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Text(
          "نحن في كورسيريا نؤمن بحق الجميع في التعليم. إذا كنت طالباً متعففاً ولا تملك القدرة المالية، يرجى ذكر الأسباب بصدق وسيقوم فريقنا بمراجعة طلبك ومنحك الكورس مجاناً.",
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
        alignLabelWithHint: true,
        prefixIcon: Icon(icon, color: AppColors.primaryNavy.withOpacity(0.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "يرجى ذكر الأسباب" : null,
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: _walletController.isLoading.value ? null : () {
          if (_formKey.currentState!.validate()) {
            _walletController.submitCharityRequest(_reasonController.text);
            Get.back();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        ),
        child: _walletController.isLoading.value
            ? const CircularProgressIndicator(color: Colors.white)
            : Text("إرسال الطلب",
                style: AppTextStyles.button.copyWith(fontSize: 18.sp)),
      ),
    ));
  }
}
