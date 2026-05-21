import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/system_controller.dart';
import '../core/constants/constants.dart';
import 'ai_support_chat_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final SystemController _systemController = Get.find<SystemController>();

  late TextEditingController _nameController;
  late TextEditingController _parentPhoneController;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _authController.userData['name']);
    _parentPhoneController = TextEditingController(text: _authController.userData['parent_phone'] ?? "+963");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: const Text("الإعدادات الاحترافية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Section
            _buildSectionTitle("الملف الشخصي"),
            const SizedBox(height: 15),
            _buildTextField(_nameController, "الاسم الكامل", Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField(_parentPhoneController, "رقم ولي الأمر", Icons.family_restroom_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 15),
            _buildTextField(_passwordController, "كلمة المرور الجديدة (اختياري)", Icons.lock_outline, isPassword: true),
            const SizedBox(height: 20),
            _buildSaveButton(),
            
            const SizedBox(height: 40),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),

            // 2. Administrative Section
            _buildSectionTitle("إعدادات المنصة"),
            const SizedBox(height: 15),
            _buildSwitchTile(
              "السيرفر التجريبي", 
              "تفعيل السيرفر الخاص بالمطورين للتجربة", 
              _systemController.useTestServer, 
              (val) => _systemController.toggleTestServer(val)
            ),
            _buildSwitchTile(
              "التنزيل التلقائي", 
              "بدء تنزيل الدروس تلقائياً عند فتحها", 
              _systemController.autoDownload, 
              (val) => _systemController.toggleAutoDownload(val)
            ),
            
            const SizedBox(height: 20),
            _buildSectionTitle("تفضيلات الأوفلاين"),
            const SizedBox(height: 15),
            _buildDownloadsManagerTile(),
            _buildOfflinePreferenceSelector(),

            const SizedBox(height: 20),
            _buildSectionTitle("هوية التطبيق (الثيم)"),
            const SizedBox(height: 15),
            _buildThemeColorPicker(),

            const SizedBox(height: 30),
            _buildSectionTitle("محرك الذكاء الاصطناعي (AI Freedom)"),
            const SizedBox(height: 15),
            _buildAIModelSelector(),

            const SizedBox(height: 30),
            _buildSectionTitle("الدعم والمساعدة"),
            const SizedBox(height: 15),
            _buildSupportTile(),

            const SizedBox(height: 40),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: AppColors.accentTeal, fontSize: 16.sp, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDownloadsManagerTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: () => Get.toNamed('/downloads'),
        leading: const Icon(Icons.download_for_offline_rounded, color: AppColors.accentTeal),
        title: const Text("إدارة التنزيلات", style: TextStyle(color: Colors.white)),
        subtitle: const Text("عرض وإزالة الفيديوهات المحملة", style: TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.accentTeal, size: 20),
        filled: true,
        fillColor: AppColors.secondaryNavy,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentTeal)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _authController.isLoading.value ? null : () {
          _authController.updateProfile(
            name: _nameController.text,
            parentPhone: _parentPhoneController.text,
            newPassword: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _authController.isLoading.value 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("حفظ التغييرات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    ));
  }

  Widget _buildSwitchTile(String title, String subtitle, RxBool value, Function(bool) onChanged) {
    return Obx(() => SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      value: value.value,
      onChanged: onChanged,
      activeColor: AppColors.accentTeal,
      contentPadding: EdgeInsets.zero,
    ));
  }

  Widget _buildOfflinePreferenceSelector() {
    return Obx(() => Column(
      children: [
        RadioListTile<String>(
          title: const Text("جودة عالية", style: TextStyle(color: Colors.white, fontSize: 14)),
          value: 'high_quality',
          groupValue: _systemController.offlinePreference.value,
          onChanged: (val) => _systemController.setOfflinePreference(val!),
          activeColor: AppColors.accentTeal,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text("توفير البيانات", style: TextStyle(color: Colors.white, fontSize: 14)),
          value: 'data_saver',
          groupValue: _systemController.offlinePreference.value,
          onChanged: (val) => _systemController.setOfflinePreference(val!),
          activeColor: AppColors.accentTeal,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    ));
  }

  Widget _buildAIModelSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Obx(() => DropdownButtonHideUnderline(
        child: DropdownButton<AIModel>(
          value: _systemController.selectedAIModel.value,
          dropdownColor: AppColors.secondaryNavy,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentTeal),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: AIModel.values.map((model) {
            final details = AppConstants.aiModels[model]!;
            return DropdownMenuItem<AIModel>(
              value: model,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(details['name']!, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(details['description']!, style: TextStyle(fontSize: 10.sp, color: Colors.white54)),
                ],
              ),
            );
          }).toList(),
          onChanged: (model) {
            if (model != null) {
              _systemController.updateAIModel(model);
              Get.snackbar("تم التحديث", "تم تغيير محرك الذكاء الاصطناعي إلى ${AppConstants.aiModels[model]!['name']}",
                  backgroundColor: AppColors.accentTeal, colorText: Colors.white);
            }
          },
        ),
      )),
    );
  }

  Widget _buildSupportTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: () => Get.to(() => AISupportChatScreen()),
        leading: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.accentTeal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded, color: AppColors.accentTeal),
        ),
        title: const Text("الدعم الفني الذكي (AI Bot)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text("حل مشاكلك فوراً عبر مهندسنا الذكي", style: TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
      ),
    );
  }

  Widget _buildThemeColorPicker() {
    final List<Color> themeColors = [
      const Color(0xFF00B4D8), // Default Teal
      const Color(0xFFE63946), // Red
      const Color(0xFFFB8500), // Orange
      const Color(0xFF023E8A), // Deep Blue
      const Color(0xFF52B788), // Green
      const Color(0xFF7209B7), // Purple
    ];

    return Obx(() => SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: themeColors.length,
        itemBuilder: (context, index) {
          final color = themeColors[index];
          final isSelected = _systemController.selectedThemeColor.value.value == color.value;
          
          return GestureDetector(
            onTap: () => _systemController.updateThemeColor(color),
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
            ),
          );
        },
      ),
    ));
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _authController.logout(),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
