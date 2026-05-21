import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/constants.dart';
import '../services/notification_service.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSending = false;

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      Get.snackbar("تنبيه", "يرجى كتابة العنوان ونص الرسالة");
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Save to Supabase notifications table (assuming it exists for broadcasting)
      await _supabase.from('notifications').insert({
        'title': _titleController.text,
        'content': _bodyController.text,
        'type': 'broadcast',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Simulate Push via Local Notification for the admin too
      LocalNotificationService.showNotification(
        _titleController.text,
        _bodyController.text,
      );

      Get.snackbar("نجاح", "تم إرسال الإشعار لكافة الطلاب بنجاح 🚀", 
          backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال الإشعار: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: const Text("بث إشعارات إدارية", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("أرسل رسالة فورية لكافة مستخدمي المنصة", style: TextStyle(color: Colors.white54)),
            SizedBox(height: 25.h),
            _buildTextField(_titleController, "عنوان الإشعار", Icons.title_rounded),
            SizedBox(height: 15.h),
            _buildTextField(_bodyController, "نص الرسالة", Icons.message_rounded, maxLines: 5),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendBroadcast,
                icon: _isSending ? const SizedBox.shrink() : const Icon(Icons.send_rounded, color: Colors.white),
                label: _isSending 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("إرسال الآن", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.accentTeal),
        filled: true,
        fillColor: AppColors.secondaryNavy,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentTeal)),
      ),
    );
  }
}
