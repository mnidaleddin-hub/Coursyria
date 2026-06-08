import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import '../models/ai_models.dart';
import 'auth_controller.dart';
import 'course_controller.dart';
import 'system_controller.dart';

class DashboardController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService();
  
  var isLoading = true.obs;
  var isAiLoading = false.obs;
  var studentName = "".obs;
  var studyStreak = 0.obs;
  var hoursWatched = 0.0.obs;
  var completedLessons = 0.obs;
  var earnedCertificates = 0.obs;
  var totalPoints = 0.obs;
  
  var activeCourses = <Map<String, dynamic>>[].obs;
  var continueLearning = <Map<String, dynamic>>[].obs;
  var aiRecommendations = <AIRecommendation>[].obs;
  
  List<AIRecommendation> get recommendations => aiRecommendations;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;

      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(seconds: 1));
        studentName.value = "طالب كورسيريا (تجربة)";
        studyStreak.value = 5;
        totalPoints.value = 1250;
        hoursWatched.value = 45.5;
        completedLessons.value = 24;
        earnedCertificates.value = 3;

        continueLearning.assignAll([
           {
             'course_id': '550e8400-e29b-41d4-a716-446655440000',
             'course_title': 'أساسيات الرياضيات - جبر',
             'course_thumbnail': 'https://images.unsplash.com/photo-1509228468518-180dd4864904?q=80&w=500',
             'progress_percent': 65.0,
           },
           {
             'course_id': '550e8400-e29b-41d4-a716-446655440001',
             'course_title': 'الفيزياء الحديثة',
             'course_thumbnail': 'https://images.unsplash.com/photo-1636466484362-533519c8430a?q=80&w=500',
             'progress_percent': 30.0,
           }
         ]);

         aiRecommendations.assignAll([
           AIRecommendation(
             courseId: '550e8400-e29b-41d4-a716-446655440002',
             reason: 'بناءً على اهتمامك باللغات، ننصحك بهذا الكورس المتميز.',
             score: 0.95,
           )
         ]);
        return;
      }

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
      totalPoints.value = profile['total_points'] ?? 0;

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

      // 5. Fetch existing recommendations from DB
      await _loadStoredRecommendations(user.id);

      // 6. Trigger AI refresh if no recommendations or old ones
      if (aiRecommendations.isEmpty) {
        fetchAIRecommendations();
      }

    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStoredRecommendations(String userId) async {
    try {
      final data = await _supabase
          .from('ai_recommendations')
          .select()
          .eq('user_id', userId)
          .order('score', ascending: false)
          .limit(3);
      
      aiRecommendations.assignAll((data as List).map((e) => AIRecommendation.fromJson(e)).toList());
    } catch (e) {
      debugPrint("Error loading stored recommendations: $e");
    }
  }

  Future<void> fetchAIRecommendations() async {
    try {
      isAiLoading.value = true;
      final authController = Get.find<AuthController>();
      final courseController = Get.find<CourseController>();
      
      // Get Interests (mocked for now, can be expanded)
      final interests = ["برمجة", "رياضيات", "علوم"]; 
      
      // Get Quiz Results
      final quizData = await _supabase.from('quiz_results').select().limit(10);
      
      // Get Available Courses
      final availableCourses = courseController.allCourses.map((c) => {
        'id': c.id,
        'title': c.title,
        'category': c.category,
      }).toList();

      final results = await _aiService.fetchRecommendations(
        interests: interests,
        quizResults: List<Map<String, dynamic>>.from(quizData),
        availableCourses: availableCourses,
      );

      if (results.isNotEmpty) {
        aiRecommendations.assignAll(results);
      }
    } catch (e) {
      debugPrint("AI Recommendation Error: $e");
    } finally {
      isAiLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await fetchDashboardData();
    Get.find<AuthController>().triggerHaptic(AppHapticFeedback.light);
  }
}
