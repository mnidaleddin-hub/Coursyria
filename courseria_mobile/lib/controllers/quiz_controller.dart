import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_result_model.dart';
import '../services/analytics_service.dart';
import '../services/ai_service.dart';
import 'auth_controller.dart';
import '../core/constants/constants.dart';

class QuizController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var quizzes = <Quiz>[].obs;
  var currentQuizQuestions = <QuizQuestion>[].obs;
  var quizResults = <String, QuizResult>{}.obs; // quizId -> result
  var isLoading = false.obs;

  // State for active quiz
  var currentQuestionIndex = 0.obs;
  var userAnswers = <String, String>{}.obs; // questionId -> answerText
  var timerSeconds = 0.obs;
  var starredQuestions = <String>{}.obs; // Set of starred question IDs
  Timer? _quizTimer;

  bool isStarred(String questionId) => starredQuestions.contains(questionId);

  void toggleStar(String questionId) {
    if (starredQuestions.contains(questionId)) {
      starredQuestions.remove(questionId);
    } else {
      starredQuestions.add(questionId);
    }
  }

  /// Fetches all quizzes for a specific course.
  Future<void> fetchQuizzesForCourse(String courseId) async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from('quizzes')
          .select()
          .eq('course_id', courseId)
          .eq('is_published', true);

      quizzes.assignAll((response as List).map((e) => Quiz.fromJson(e)).toList());
      
      // Also fetch results for these quizzes for the current user
      await fetchUserResultsForQuizzes(quizzes.map((q) => q.id).toList());
    } catch (e) {
      debugPrint("Error fetching quizzes: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches questions for a specific quiz.
  Future<void> fetchQuizQuestions(String quizId) async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from('quiz_questions')
          .select()
          .eq('quiz_id', quizId)
          .order('order_index', ascending: true);

      currentQuizQuestions.assignAll((response as List).map((e) => QuizQuestion.fromJson(e)).toList());
    } catch (e) {
      debugPrint("Error fetching quiz questions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads questions from an AI-generated source.
  void loadAIQuestions(List<QuizQuestion> questions) {
    currentQuizQuestions.assignAll(questions);
  }

  Future<void> generateAndStartAIQuiz({
    required String type,
    required String topicName,
    String? lessonId,
  }) async {
    isLoading.value = true;
    try {
      final aiService = Get.find<AIService>();
      final questions = await aiService.generateQuiz(
        topic: topicName,
        questionCount: 5,
        context: "اختبار سريع لدرس $topicName",
      );
      
      currentQuizQuestions.assignAll(questions);
      
      final tempQuiz = Quiz(
        id: 'ai_temp_${DateTime.now().millisecondsSinceEpoch}',
        title: "اختبار ذكي: $topicName",
        description: "اختبار مولد تلقائياً بواسطة الذكاء الاصطناعي",
        passingScore: 60,
        questionsCount: questions.length,
        isPublished: true,
        createdAt: DateTime.now(),
      );

      Get.toNamed('/quiz', arguments: {'quiz': tempQuiz});
    } catch (e) {
      debugPrint("Error generating AI quiz: $e");
      Get.snackbar("خطأ", "فشل توليد الاختبار الذكي: $e",
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Starts the quiz session.
  void startQuizSession(Quiz quiz) {
    currentQuestionIndex.value = 0;
    userAnswers.clear();
    if (quiz.timeLimit != null) {
      timerSeconds.value = quiz.timeLimit! * 60;
      _startTimer();
    } else {
      timerSeconds.value = 0;
    }
  }

  void _startTimer() {
    _quizTimer?.cancel();
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        _quizTimer?.cancel();
        submitQuiz(currentQuizQuestions.first.quizId); // Auto-submit on timeout
      }
    });
  }

  /// Saves a temporary answer.
  void saveAnswer(String questionId, String answer) {
    userAnswers[questionId] = answer;
  }

  /// Calculates the score and submits the quiz.
  Future<void> submitQuiz(String quizId) async {
    _quizTimer?.cancel();
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      int score = 0;
      int totalPoints = 0;

      for (var question in currentQuizQuestions) {
        totalPoints += question.points;
        if (userAnswers[question.id] == question.correctAnswer) {
          score += question.points;
        }
      }

      final double percentage = (score / totalPoints) * 100;
      
      // Handle AI Temp Quizzes (don't save to DB quiz_results to avoid FK errors)
      if (quizId.startsWith('ai_temp_')) {
        final result = QuizResult(
          id: "res_${quizId}",
          userId: userId,
          quizId: quizId,
          score: score,
          totalPoints: totalPoints,
          percentage: percentage,
          isPassed: percentage >= 60,
          timeSpent: 0,
          completedAt: DateTime.now(),
        );
        Get.offNamed('/quiz-result', arguments: result);
        return;
      }

      final quiz = quizzes.firstWhere((q) => q.id == quizId);
      final bool isPassed = percentage >= quiz.passingScore;

      final resultData = {
        'user_id': userId,
        'quiz_id': quizId,
        'score': score,
        'total_points': totalPoints,
        'percentage': percentage,
        'is_passed': isPassed,
        'time_spent': quiz.timeLimit != null ? (quiz.timeLimit! * 60 - timerSeconds.value) : 0,
        'completed_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.from('quiz_results').insert(resultData).select().single();
      final QuizResult result = QuizResult.fromJson(response);
      quizResults[quizId] = result;
      AnalyticsService.logQuizCompletion(quizId, score, isPassed);

      // Reward points and XP if passed
      if (isPassed) {
        final gamificationController = Get.find<GamificationController>();
        await gamificationController.addXP(200); // Higher reward for passing quiz
        Get.snackbar("بطل! 🏆", "لقد اجتزت الاختبار وحصلت على 200 XP!",
            backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      }

      Get.offNamed('/quiz-result', arguments: result);
    } catch (e) {
      debugPrint("Error submitting quiz: $e");
      Get.snackbar("خطأ", "فشل تسليم الاختبار: $e",
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches previous results for a list of quizzes.
  Future<void> fetchUserResultsForQuizzes(List<String> quizIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || quizIds.isEmpty) return;

    try {
      final response = await _supabase
          .from('quiz_results')
          .select()
          .eq('user_id', userId)
          .inFilter('quiz_id', quizIds);

      for (var item in (response as List)) {
        final result = QuizResult.fromJson(item);
        quizResults[result.quizId] = result;
      }
    } catch (e) {
      debugPrint("Error fetching user results: $e");
    }
  }

  @override
  void onClose() {
    _quizTimer?.cancel();
    super.onClose();
  }
}
