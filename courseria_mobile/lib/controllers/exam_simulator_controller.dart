import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../services/auth_service.dart';

class ExamSimulatorController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _player = AudioPlayer();

  var currentQuiz = Rxn<Quiz>();
  var questions = <QuizQuestion>[].obs;
  var currentQuestionIndex = 0.obs;
  var userAnswers = <String, String>{}.obs; // questionId -> selectedOption
  
  // Timer
  var remainingSeconds = 0.obs;
  Timer? _timer;
  var timerColor = Colors.white.obs;
  
  // Anti-cheat (Feature 56)
  var exitAttempts = 0.obs;
  var isExamFailed = false.obs;

  // Silent Mode (Feature 66)
  var isSilentMode = false.obs;
  var selectedAmbientSound = "none".obs; // papers, pens, clock, rain

  Future<void> toggleSilentMode(bool value) async {
    isSilentMode.value = value;
    if (value) {
      await _playAmbientSound();
    } else {
      await _player.stop();
    }
  }

  Future<void> _playAmbientSound() async {
    if (selectedAmbientSound.value == "none") return;
    
    // In a real app, these would be local assets
    String assetPath = "animations/ambient_${selectedAmbientSound.value}.mp3";
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Error playing ambient sound: $e");
    }
  }

  void startExam(Quiz quiz, List<QuizQuestion> qList) {
    currentQuiz.value = quiz;
    questions.assignAll(qList);
    currentQuestionIndex.value = 0;
    userAnswers.clear();
    exitAttempts.value = 0;
    isExamFailed.value = false;
    
    remainingSeconds.value = (quiz.timeLimit ?? 120) * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        _updateTimerColor();
        _checkTimerWarnings();
      } else {
        _timer?.cancel();
        submitExam();
      }
    });
  }

  void _updateTimerColor() {
    if (remainingSeconds.value <= 60) {
      timerColor.value = Colors.red; // Feature 55: Last minute red
    } else if (remainingSeconds.value <= 300) {
      timerColor.value = Colors.orange; // Feature 55: Last 5 mins orange
    } else {
      timerColor.value = Colors.white;
    }
  }

  void _checkTimerWarnings() {
    if (remainingSeconds.value == 300) {
      Get.snackbar(
        "تنبيه", 
        "بقي 5 دقائق على نهاية الامتحان", 
        backgroundColor: Colors.orange,
        colorText: Colors.white
      );
    }
  }

  void handleAppExitAttempt() {
    if (isExamFailed.value) return;
    
    exitAttempts.value++;
    if (exitAttempts.value == 1) {
      Get.dialog(
        AlertDialog(
          title: const Text("تحذير غش"),
          content: const Text("محاولة الخروج من التطبيق ستؤدي إلى إلغاء الامتحان في المرة القادمة."),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("فهمت"))
          ],
        ),
        barrierDismissible: false
      );
    } else {
      failExam("تم إلغاء الامتحان بسبب محاولة الخروج المتكررة.");
    }
  }

  void failExam(String reason) {
    isExamFailed.value = true;
    _timer?.cancel();
    Get.offAllNamed('/exam-failed', arguments: reason);
  }

  void submitExam() {
    _timer?.cancel();
    // Logic to calculate score and show Feature 57 result screen
    Get.toNamed('/exam-results');
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
    }
  }

  void prevQuestion() {
    if (currentQuestionIndex.value > 0) {
      currentQuestionIndex.value--;
    }
  }

  Future<void> startQuickQuiz(String subject) async {
    try {
      isLoading.value = true;
      // Feature 72: Fetch 5 questions for a quick quiz
      // Simulating API call
      await Future.delayed(const Duration(seconds: 1));
      
      final mockQuestions = List.generate(5, (index) => QuizQuestion(
        id: "quick_$index",
        quizId: "quick",
        questionText: "سؤال سريع رقم ${index + 1} عن مادة $subject",
        questionType: "multiple_choice",
        options: ["خيار 1", "خيار 2", "خيار 3", "خيار 4"],
        correctAnswer: "خيار 1",
        points: 10,
        orderIndex: index,
      ));

      final quickQuiz = Quiz(
        id: "quick_quiz",
        title: "اختبار سريع: $subject",
        description: "5 أسئلة لاختبار فهمك السريع",
        passingScore: 60,
        questionsCount: 5,
        isPublished: true,
        createdAt: DateTime.now(),
        quizType: "quick_quiz",
      );

      startExam(quickQuiz, mockQuestions);
      Get.toNamed('/exam-simulator');
    } catch (e) {
      Get.snackbar("خطأ", "فشل بدء الاختبار السريع");
    } finally {
      isLoading.value = false;
    }
  }
  @override
  void onClose() {
    _timer?.cancel();
    _player.dispose();
    super.onClose();
  }
}
