import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'system_controller.dart';

class NotificationController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  var notifications = <NotificationModel>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        // Mock Data for Offline Mode
        await Future.delayed(const Duration(seconds: 1));
        final List<Map<String, dynamic>> mockData = [
          {
            'id': '1',
            'title': 'مرحباً بك في كورسيريا! 🎉',
            'message': 'استكشف عالم المعرفة مع أفضل المدرسين في سوريا.',
            'created_at': DateTime.now().toIso8601String(),
            'course': {'title': 'نظام المنصة'}
          },
          {
            'id': '2',
            'title': 'تحدي جديد بانتظارك 🏆',
            'message': 'تم إضافة تحدي أسبوعي جديد لمادة الرياضيات. هل أنت جاهز؟',
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'course': {'title': 'رياضيات'}
          },
          {
            'id': '3',
            'title': 'تحديث رصيدك 💰',
            'message': 'تم شحن محفظتك بمبلغ 50,000 ل.س بنجاح.',
            'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
            'course': {'title': 'المحفظة'}
          }
        ];
        notifications.assignAll(mockData.map((json) => NotificationModel.fromJson(json)).toList());
        return;
      }

      final List<dynamic> response = await _supabase
          .from('notifications')
          .select('*, course:courses(title)')
          .order('created_at', ascending: false);

      notifications.assignAll(response.map((json) => NotificationModel.fromJson(json)).toList());
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "فشل في جلب الإشعارات: $e";
      debugPrint("Error fetching notifications: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
