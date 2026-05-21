import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart'; // We will create this model next

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
      final List<dynamic> response = await _supabase
          .from('notifications')
          .select('*, course:courses(title)') // Assuming a 'courses' table with 'title'
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
