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

    return ListView(
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
          title: "سمة الألوان والمظهر",
          subtitle: themeController.selectedThemeName.value,
          onTap: () => _showThemeSelectionSheet(context, themeController),
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
          icon: Icons.help_outline_rounded,
          title: "الأسئلة الشائعة",
          onTap: () => Get.toNamed('/faqs'),
        ),
        _buildSettingTile(
            icon: Icons.info_outline_rounded,
            title: "عن التطبيق",
            onTap: () => Get.toNamed('/app-info'),
          ),
          _buildSettingTile(
            icon: Icons.support_agent_rounded,
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

  void _showThemeSelectionSheet(BuildContext context, ThemeController themeController) {
    final themes = [
      {'name': 'Original', 'label': 'كورسيريا الأصلي', 'desc': 'ألوان الهوية الرسمية', 'color': AppTheme.themeColors['Navy']},
      {'name': 'Academia', 'label': 'أكاديميا هادئ', 'desc': 'مريح للعين بلمسات عشبية', 'color': AppTheme.themeColors['Sage']},
      {'name': 'DarkPro', 'label': 'الوضع الاحترافي', 'desc': 'أسود مطلق موفر للطاقة (OLED)', 'color': AppTheme.themeColors['ElectricBlue']},
      {'name': 'Vibrant', 'label': 'تعلم حيوي', 'desc': 'ألوان مشرقة وتدرجات عصرية', 'color': Colors.deepPurpleAccent},
      {'name': 'Minimal', 'label': 'بساطة مطلقة', 'desc': 'أبيض ناصع وتصميم مينيمال', 'color': Colors.black},
      {'name': 'Midnight', 'label': 'منتصف الليل', 'desc': 'بنفسجي داكن للتركيز العميق', 'color': AppTheme.themeColors['MidnightPurple']},
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 20.h),
            Text("اختر مظهرك المفضل", style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
            SizedBox(height: 20.h),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final t = themes[index];
                  final isSelected = themeController.selectedThemeName.value == t['name'];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: t['color'] as Color),
                    title: Text(t['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(t['desc'] as String),
                    trailing: isSelected ? Icon(Icons.check_circle_rounded, color: t['color'] as Color) : null,
                    onTap: () {
                      themeController.changeThemeColor(t['name'] as String);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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
