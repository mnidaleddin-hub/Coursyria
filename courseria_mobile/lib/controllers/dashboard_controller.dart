import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  
  var isLoading = true.obs;
  var studentName = "".obs;
  var studyStreak = 0.obs;
  var hoursWatched = 0.0.obs;
  var completedLessons = 0.obs;
  var earnedCertificates = 0.obs;
  
  var activeCourses = <Map<String, dynamic>>[].obs;
  var continueLearning = <Map<String, dynamic>>[].obs;
  var recommendations = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch Profile Data & Streak
      final profile = await _supabase
          .from('user_profiles')
          .select('full_name, study_streak, total_points')
          .eq('id', user.id)
          .single();
      
      studentName.value = profile['full_name'] ?? "طالب كورسيريا";
      studyStreak.value = profile['study_streak'] ?? 0;

      // 2. Fetch Stats
      final stats = await _supabase.rpc('get_student_stats', params: {'user_id_param': user.id});
      if (stats != null) {
        hoursWatched.value = (stats['total_seconds_watched'] ?? 0) / 3600.0;
        completedLessons.value = stats['completed_lessons_count'] ?? 0;
        earnedCertificates.value = stats['certificates_count'] ?? 0;
      }

      // 3. Fetch Active Courses with Progress
      final progressData = await _supabase
          .from('student_progress_view')
          .select()
          .eq('user_id', user.id)
          .order('last_watched_at', ascending: false);
      
      activeCourses.assignAll(List<Map<String, dynamic>>.from(progressData));

      // 4. "Continue Learning" (Last 5 played lessons)
      continueLearning.assignAll(activeCourses.take(5).toList());

      // 5. Smart Recommendations (Based on enrolled courses)
      await _fetchRecommendations(user.id);

    } catch (e) {
      _logger.e("Error fetching dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchRecommendations(String userId) async {
    try {
      // Mocking logic: Recommend next lessons in active courses
      final response = await _supabase.rpc('get_recommended_lessons', params: {'user_id_param': userId});
      recommendations.assignAll(List<Map<String, dynamic>>.from(response ?? []));
    } catch (e) {
      _logger.e("Error fetching recommendations: $e");
    }
  }

  Future<void> refreshDashboard() async {
    await fetchDashboardData();
    Get.find<AuthController>().triggerHaptic(AppHapticFeedback.light);
  }
}
