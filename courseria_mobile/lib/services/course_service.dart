import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/constants.dart';

class CourseService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
  ));
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all courses
  Future<List<dynamic>> getAllCourses() async {
    try {
      final List<Map<String, dynamic>> response =
          await _supabase.from('courses').select();
      return response;
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching courses from Supabase: $e");
      rethrow;
    }
  }

  // Check if user is subscribed
  Future<bool> checkSubscription(String userId, String courseId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Buy a course
  Future<bool> purchaseCourse(
      String userId, String courseId, double price) async {
    try {
      // In a real scenario, this should be a transaction on the backend
      // 1. Check balance
      // 2. Deduct balance
      // 3. Add subscription

      // For now, we simulate success via Supabase
      await _supabase.from('subscriptions').insert({
        'user_id': userId,
        'course_id': courseId,
        'purchased_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint("Purchase error: $e");
      return false;
    }
  }

  // Get Video Stream Data (URL & AES Key)
  Future<Map<String, dynamic>> getVideoData(
      String courseId, String videoId, String token) async {
    if (courseId == "mock_test_1") {
      return {
        "video_url":
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "decryption_key": "TEST_KEY_NOT_NEEDED",
        "expiry": DateTime.now().add(const Duration(hours: 1)).toIso8601String()
      };
    }
    try {
      final response = await _dio.get(
        '/courses/$courseId/video/$videoId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw "فشل جلب بيانات الفيديو";
    }
  }
}
