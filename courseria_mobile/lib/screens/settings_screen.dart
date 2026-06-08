import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/constants.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/system_controller.dart';
import '../controllers/ai_controller.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();
    final systemController = Get.find<SystemController>();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("الإعدادات"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          _buildSectionTitle("المظهر والسمات"),
          
          if (authController.userData['role'] == 'teacher')
            _buildSettingTile(
              icon: Icons.dashboard_customize_rounded,
              title: "لوحة تحكم المعلم",
              subtitle: "إدارة الكورسات، الطلاب، والأرباح",
              onTap: () => Get.toNamed('/teacher-dashboard'),
            ),

          // Theme Mode (Light/Dark/System)
          _buildSettingTile(
            icon: Icons.palette_rounded,
            title: "وضع التطبيق",
            subtitle: _getThemeModeName(themeController.themeMode.value),
            onTap: () => _showThemeModeSheet(context, themeController),
          ),

          // Theme Color Presets
          _buildSettingTile(
            icon: Icons.color_lens_rounded,
            title: "سمة الألوان",
            subtitle: themeController.selectedThemeName.value == 'Custom' ? "لون مخصص" : themeController.selectedThemeName.value,
            trailing: _buildCurrentColorPreview(themeController),
            onTap: () => _showThemeColorSheet(context, themeController),
          ),

          _buildSettingTile(
            icon: Icons.visibility_rounded,
            title: "حماية العين (الفلتر الأزرق)",
            trailing: Obx(() => Switch(
              value: systemController.isBlueLightFilterEnabled.value,
              onChanged: (val) => systemController.toggleBlueLightFilter(val),
              activeColor: themeController.currentPrimaryColor,
            )),
          ),

          SizedBox(height: 24.h),
          _buildSectionTitle("الذكاء الاصطناعي (AI)"),
          _buildAISettings(context, systemController),
          
          SizedBox(height: 24.h),
          _buildSectionTitle("اللغة"),
          _buildSettingTile(
            icon: Icons.language_rounded,
            title: "لغة التطبيق",
            subtitle: "العربية (Arabic)",
            onTap: () {
              Get.snackbar("اللغة", "التطبيق متوفر حالياً باللغة العربية فقط.");
            },
          ),

          SizedBox(height: 24.h),
          _buildSectionTitle("الحساب والأمان"),
          _buildSettingTile(
            icon: Icons.notifications_active_rounded,
            title: "الإشعارات",
            trailing: Switch(
              value: true,
              onChanged: (val) {},
              activeColor: themeController.currentPrimaryColor,
            ),
          ),
          
          SizedBox(height: 24.h),
          _buildSectionTitle("عن كورسيريا"),
          _buildSettingTile(
            icon: Icons.info_outline_rounded,
            title: "عن التطبيق",
            onTap: () => Get.toNamed('/app-info'),
          ),
          _buildSettingTile(
            icon: Icons.help_outline_rounded,
            title: "مركز المساعدة",
            onTap: () => Get.toNamed('/help'),
          ),

          SizedBox(height: 40.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(authController),
              icon: const Icon(Icons.logout_rounded),
              label: const Text("تسجيل الخروج"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed.withOpacity(0.1),
                foregroundColor: AppColors.errorRed,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildAISettings(BuildContext context, SystemController systemController) {
    final aiController = Get.find<AIController>();
    final aiService = Get.find<AIService>();

    return Column(
      children: [
        // Model Selection
        _buildSettingTile(
          icon: Icons.psychology_rounded,
          title: "محرك الذكاء الاصطناعي",
          subtitle: systemController.selectedAIModel.value.toString().split('.').last,
          onTap: () => _showAIModelSheet(context, systemController),
        ),

        // Usage Stats
        Obx(() => _buildSettingTile(
              icon: Icons.data_usage_rounded,
              title: "إحصاءات الاستهلاك",
              subtitle: "طلبات: ${aiController.totalRequests.value} | توكنز: ${aiController.totalTokens.value}\nالتكلفة التقديرية: \$${(aiController.totalTokens.value * 0.000002).toStringAsFixed(2)}",
              trailing: const Icon(Icons.info_outline_rounded, size: 16),
              onTap: () => aiController.fetchUsageStats(),
            )),

        // Clear Cache
        _buildSettingTile(
          icon: Icons.cleaning_services_rounded,
          title: "مسح ذاكرة AI المؤقتة",
          subtitle: "لتوفير المساحة وتحديث الردود",
          trailing: const Icon(Icons.delete_sweep_outlined, color: Colors.orangeAccent),
          onTap: () async {
            final msg = await aiService.clearAICache();
            Get.snackbar("الذاكرة المؤقتة", msg, backgroundColor: AppColors.accentTeal, colorText: Colors.white);
          },
        ),
      ],
    );
  }

  void _showAIModelSheet(BuildContext context, SystemController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("اختر نموذج الذكاء الاصطناعي", style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
            SizedBox(height: 20.h),
            ...AIModel.values.map((model) {
              return Obx(() {
                final isSelected = controller.selectedAIModel.value == model;
                return ListTile(
                  leading: Icon(Icons.bolt_rounded, color: isSelected ? AppColors.accentTeal : Colors.white38),
                  title: Text(model.toString().split('.').last, style: TextStyle(color: isSelected ? AppColors.accentTeal : null)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.accentTeal) : null,
                  onTap: () {
                    controller.updateAIModel(model);
                    Get.back();
                  },
                );
              });
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return "الوضع الفاتح";
      case ThemeMode.dark: return "الوضع الداكن";
      case ThemeMode.system: return "حسب إعدادات النظام";
    }
  }

  Widget _buildCurrentColorPreview(ThemeController controller) {
    return Obx(() => Container(
      width: 24.r,
      height: 24.r,
      decoration: BoxDecoration(
        color: controller.currentPrimaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
    ));
  }

  void _showThemeModeSheet(BuildContext context, ThemeController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("وضع التطبيق", style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
            SizedBox(height: 20.h),
            _buildModeOption(controller, ThemeMode.light, "الوضع الفاتح", Icons.light_mode_rounded),
            _buildModeOption(controller, ThemeMode.dark, "الوضع الداكن", Icons.dark_mode_rounded),
            _buildModeOption(controller, ThemeMode.system, "حسب النظام", Icons.settings_brightness_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(ThemeController controller, ThemeMode mode, String label, IconData icon) {
    return Obx(() {
      final isSelected = controller.themeMode.value == mode;
      return ListTile(
        leading: Icon(icon, color: isSelected ? controller.currentPrimaryColor : AppColors.textGrey),
        title: Text(label, style: TextStyle(color: isSelected ? controller.currentPrimaryColor : null, fontWeight: isSelected ? FontWeight.bold : null)),
        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: controller.currentPrimaryColor) : null,
        onTap: () {
          controller.changeThemeMode(mode);
          Get.back();
        },
      );
    });
  }

  void _showThemeColorSheet(BuildContext context, ThemeController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("سمة الألوان", style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
            SizedBox(height: 24.h),
            Wrap(
              spacing: 15.w,
              runSpacing: 15.h,
              alignment: WrapAlignment.center,
              children: [
                ...AppTheme.themeColors.entries.map((entry) {
                  return _buildColorCircle(controller, entry.key, entry.value);
                }),
                _buildCustomColorCircle(context, controller),
              ],
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(ThemeController controller, String name, Color color) {
    return Obx(() {
      final isSelected = controller.selectedThemeName.value == name;
      return GestureDetector(
        onTap: () => controller.changeThemeColor(name),
        child: Column(
          children: [
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: [
                  if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
            ),
            SizedBox(height: 8.h),
            Text(name, style: TextStyle(fontSize: 12.sp, color: isSelected ? color : AppColors.textGrey)),
          ],
        ),
      );
    });
  }

  Widget _buildCustomColorCircle(BuildContext context, ThemeController controller) {
    return Obx(() {
      final isSelected = controller.selectedThemeName.value == 'Custom';
      final color = controller.customPrimaryColor.value;
      return GestureDetector(
        onTap: () => _showColorPicker(context, controller),
        child: Column(
          children: [
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                gradient: const SweepGradient(colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red]),
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: [
                  if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: isSelected 
                ? const Icon(Icons.colorize_rounded, color: Colors.white) 
                : const Icon(Icons.add, color: Colors.white),
            ),
            SizedBox(height: 8.h),
            Text("مخصص", style: TextStyle(fontSize: 12.sp, color: isSelected ? color : AppColors.textGrey)),
          ],
        ),
      );
    });
  }

  void _showColorPicker(BuildContext context, ThemeController controller) {
    // Simple mock color picker using basic colors
    final colors = [Colors.red, Colors.pink, Colors.purple, Colors.deepPurple, Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange, Colors.brown];
    
    Get.dialog(
      AlertDialog(
        title: const Text("اختر لونك المفضل"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: colors.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                controller.setCustomColor(colors[index]);
                Get.back();
              },
              child: Container(decoration: BoxDecoration(color: colors[index], shape: BoxShape.circle)),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text("تسجيل الخروج"),
        content: const Text("هل أنت متأكد من رغبتك في تسجيل الخروج؟"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            child: const Text("خروج", style: TextStyle(color: Colors.redAccent)),
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
          color: Get.find<ThemeController>().currentPrimaryColor,
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
      elevation: 0,
      color: Get.context!.theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: ListTile(
        leading: Icon(icon, color: Get.find<ThemeController>().currentPrimaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
