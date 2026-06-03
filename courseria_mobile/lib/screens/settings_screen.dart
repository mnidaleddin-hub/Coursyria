import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/constants.dart';
import '../core/theme/theme_controller.dart';
import '../controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("الإعدادات"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          _buildSectionTitle("المظهر واللغة"),
          _buildSettingTile(
            icon: Icons.dark_mode_rounded,
            title: "الوضع الليلي",
            trailing: Obx(() => Switch(
              value: themeController.isDarkMode.value,
              onChanged: (val) => themeController.toggleTheme(),
              activeColor: AppColors.accentTeal,
            )),
          ),
          _buildSettingTile(
            icon: Icons.language_rounded,
            title: "لغة التطبيق",
            subtitle: "العربية",
            onTap: () {
              // Handle language change
            },
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle("الحساب والأمان"),
          _buildSettingTile(
            icon: Icons.fingerprint_rounded,
            title: "بصمة الإصبع / الوجه",
            trailing: Switch(
              value: true,
              onChanged: (val) {
                // Toggle biometric
              },
              activeColor: AppColors.accentTeal,
            ),
          ),
          _buildSettingTile(
            icon: Icons.notifications_active_rounded,
            title: "الإشعارات",
            trailing: Switch(
              value: true,
              onChanged: (val) {
                // Toggle notifications
              },
              activeColor: AppColors.accentTeal,
            ),
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle("عن كورسيريا"),
          _buildSettingTile(
            icon: Icons.info_outline_rounded,
            title: "عن التطبيق",
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.star_outline_rounded,
            title: "تقييم التطبيق",
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.share_rounded,
            title: "مشاركة التطبيق",
            onTap: () {},
          ),
          SizedBox(height: 40.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ElevatedButton.icon(
              onPressed: () => authController.logout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text("تسجيل الخروج"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed.withOpacity(0.1),
                foregroundColor: AppColors.errorRed,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.accentTeal,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
