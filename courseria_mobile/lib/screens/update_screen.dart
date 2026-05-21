import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
// import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/constants.dart';

class UpdateScreen extends StatefulWidget {
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;

  const UpdateScreen({
    super.key,
    required this.downloadUrl,
    required this.releaseNotes,
    this.isMandatory = false,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  var progress = "0".obs;
  var status = "جاري التحقق...".obs;
  var isDownloading = false.obs;

  Future<void> _startUpdate() async {
    try {
      // 1. Request Storage Permission (for Android < 13) or Install Permission
      var perm = await Permission.requestInstallPackages.request();
      if (!perm.isGranted) {
        Get.snackbar("خطأ", "يجب منح صلاحية التثبيت للمتابعة",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      isDownloading.value = true;
      status.value = "جاري تحميل التحديث...";

      /*
      OtaUpdate().execute(widget.downloadUrl).listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              progress.value = event.value ?? "0";
              break;
            case OtaStatus.INSTALLING:
              status.value = "جاري التثبيت...";
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              status.value = "التحديث قيد التنفيذ بالفعل";
              break;
            case OtaStatus.PERMISSION_NOT_ALLOWED_ERROR:
              status.value = "خطأ: لم يتم منح الصلاحيات";
              break;
            default:
              status.value = "حدث خطأ أثناء التحديث";
              isDownloading.value = false;
          }
        },
      );
      */
      status.value = "التحديث غير مدعوم على الويب";
      isDownloading.value = false;
    } catch (e) {
      status.value = "فشل التحديث: $e";
      isDownloading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Force update
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        body: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.system_update_rounded,
                  size: 80.r, color: AppColors.accentTeal),
              SizedBox(height: 32.h),
              Text(
                "تحديث جديد متوفر",
                style: AppTextStyles.header
                    .copyWith(color: Colors.white, fontSize: 24.sp),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ما الجديد:",
                        style: TextStyle(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    Text(
                      widget.releaseNotes,
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),
              Obx(() => isDownloading.value
                  ? _buildDownloadProgress()
                  : _buildUpdateButton()),
              SizedBox(height: 24.h),
              Obx(() => Text(
                    status.value,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    double progVal = double.tryParse(progress.value) ?? 0;
    return Column(
      children: [
        LinearProgressIndicator(
          value: progVal / 100,
          backgroundColor: Colors.white10,
          color: AppColors.accentTeal,
          minHeight: 8.h,
        ),
        SizedBox(height: 12.h),
        Text(
          "${progress.value}%",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _startUpdate,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentTeal,
        minimumSize: Size(double.infinity, 56.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
      child: const Text(
        "تحديث الآن",
        style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 16),
      ),
    );
  }
}
