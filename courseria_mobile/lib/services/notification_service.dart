import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService extends GetxService {
  // Skeleton for Firebase Cloud Messaging (FCM)
  
  Future<NotificationService> init() async {
    debugPrint("Initializing Notification Service...");
    // 1. Request permissions
    // 2. Get FCM Token
    // 3. Listen to foreground/background messages
    return this;
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint("Subscribing to topic: $topic");
    // await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  void handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == 'new_course') {
      Get.toNamed('/catalog', arguments: {'course_id': data['id']});
    } else if (type == 'achievement') {
      Get.toNamed('/achievements');
    }
  }

  // Local notification display (Mock)
  void showLocalNotification(String title, String body) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF3F51B5),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.notifications_active, color: Colors.white),
    );
  }
}
