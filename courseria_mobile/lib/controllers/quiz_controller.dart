import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_model.dart';
import '../services/ai_service.dart';
import 'auth_controller.dart';
import '../core/constants/constants.dart';
import '../services/certificate_service.dart';

class QuizController extends GetxController {
  final AIService _aiService = AIService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var questions = <QuizQuestion>[].obs;
  var currentIndex = 0.obs;
  var isLoading = false.obs;
  var selectedIndex = (-1).obs;
  var isAnswered = false.obs;
  var correctAnswers = 0.obs;
  var timerSeconds = 30.obs;
  Timer? _timer;

  // Quiz Type: 'lesson' or 'final'
  String quizType = 'lesson';
  String topic = '';
  String? courseId;
  String? lessonId;

  Future<void> startQuiz({
    required String type,
    required String topicName,
    String? cId,
    String? lId,
    String? contentContext,
  }) async {
    try {
      isLoading.value = true;
      quizType = type;
      topic = topicName;
      courseId = cId;
      lessonId = lId;
      currentIndex.value = 0;
      correctAnswers.value = 0;
      isAnswered.value = false;
      selectedIndex.value = -1;

      int count = type == 'final' ? 20 : 5;
      questions.value = await _aiService.generateQuiz(
        topic: topicName,
        questionCount: count,
        context: contentContext,
      );

      isLoading.value = false;
      _startTimer();
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("خطأ", "فشل توليد الاختبار الذكي: $e",
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    timerSeconds.value = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        submitAnswer(-1); // Timeout
      }
    });
  }

  void submitAnswer(int index) {
    if (isAnswered.value) return;
    
    _timer?.cancel();
    selectedIndex.value = index;
    isAnswered.value = true;

    if (index == questions[currentIndex.value].correctIndex) {
      correctAnswers.value++;
      // Haptic feedback or sound could be triggered here
    }
  }

  void nextQuestion() {
    if (currentIndex.value < questions.length - 1) {
      currentIndex.value++;
      selectedIndex.value = -1;
      isAnswered.value = false;
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    try {
      double percentage = (correctAnswers.value / questions.length) * 100;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Save result to Supabase
      await _supabase.from('student_quizzes').insert({
        'user_id': userId,
        'course_id': courseId,
        'lesson_id': lessonId,
        'type': quizType,
        'score': correctAnswers.value,
        'total_questions': questions.length,
        'percentage': percentage,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Reward points if score > 75%
      if (percentage >= 75) {
        await _authController.addPoints(100);
        Get.snackbar("بطل! 🏆", "لقد حصلت على 100 نقطة إضافية لتفوقك في الاختبار!",
            backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      }

      // 3. Trigger Certificate if Final Quiz Passed
      if (quizType == 'final' && percentage >= 75) {
        // We might need course title and teacher name here
        // For now, assuming they are available or fetched
        CertificateService.generateAndShare(
          studentName: _authController.userData['name'] ?? "طالب متميز",
          courseName: topic,
          teacherName: "مدرس كورسيريا", // Placeholder or fetch real
        );
      }

    } catch (e) {
      debugPrint("Error saving quiz result: $e");
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
