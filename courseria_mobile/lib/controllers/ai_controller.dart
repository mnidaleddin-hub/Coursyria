import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/ai_service.dart';
import '../core/constants/constants.dart';
import '../models/quiz_model.dart';

class AIController extends GetxController {
  final AIService _aiService = Get.find<AIService>();

  // Loading States
  var isAnalyzingStyle = false.obs;
  var isGeneratingQuiz = false.obs;
  var isGradingEssay = false.obs;
  var isAnalyzingClass = false.obs;
  var isGeneratingQuestions = false.obs;
  var isSummarizingDiscussions = false.obs;
  var isCorrectingContent = false.obs;
  var isGeneratingGroupQuestions = false.obs;
  var isSuggestingTasks = false.obs;
  var isGeneratingStudyPlan = false.obs;

  // Results
  var learningStyleResult = "".obs;
  var studyPlanResult = "".obs;
  var classAnalysisResult = "".obs;
  var expectedQuestionsResult = "".obs;
  var discussionSummaryResult = "".obs;

  // AI Usage Stats
  var totalRequests = 0.obs;
  var totalTokens = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsageStats();
  }

  Future<void> fetchUsageStats() async {
    try {
      final stats = await _aiService.getAIUsageStats();
      totalRequests.value = stats['total_requests'] ?? 0;
      totalTokens.value = stats['total_tokens'] ?? 0;
    } catch (e) {
      debugPrint("Error fetching AI stats: $e");
    }
  }

  Future<void> analyzeMyLearningStyle(Map<String, dynamic> userData, List<String> answers) async {
    isAnalyzingStyle.value = true;
    try {
      final combinedData = {
        ...userData,
        'quiz_answers': answers,
      };
      final result = await _aiService.analyzeLearningStyle(combinedData);
      learningStyleResult.value = result;
      _showResultDialog("تحليل الشخصية التعليمية", result);
    } catch (e) {
      _showErrorSnackbar("فشل تحليل الشخصية: $e");
    } finally {
      isAnalyzingStyle.value = false;
    }
  }

  Future<void> generateSimilarQuiz(List<Map<String, dynamic>> previousResults) async {
    isGeneratingQuiz.value = true;
    try {
      final questions = await _aiService.generateSimilarQuiz(previousResults);
      // Navigate to Quiz Screen with these questions
      Get.toNamed('/quiz', arguments: {'questions': questions, 'title': 'اختبار مخصص ذكي'});
    } catch (e) {
      _showErrorSnackbar("فشل توليد اختبار: $e");
    } finally {
      isGeneratingQuiz.value = false;
    }
  }

  Future<void> gradeEssayAnswer(String question, String answer) async {
    isGradingEssay.value = true;
    try {
      final result = await _aiService.gradeEssay(question: question, studentAnswer: answer);
      _showResultDialog("تقييم الإجابة المقالية", result);
    } catch (e) {
      _showErrorSnackbar("فشل التصحيح: $e");
    } finally {
      isGradingEssay.value = false;
    }
  }

  Future<void> analyzeClass(List<Map<String, dynamic>> studentsData) async {
    isAnalyzingClass.value = true;
    try {
      final result = await _aiService.analyzeClassProgress(studentsData);
      classAnalysisResult.value = result;
      _showResultDialog("تحليل تقدم الفصل", result);
    } catch (e) {
      _showErrorSnackbar("فشل التحليل: $e");
    } finally {
      isAnalyzingClass.value = false;
    }
  }

  Future<void> getExpectedQuestions(String subject, String grade) async {
    isGeneratingQuestions.value = true;
    try {
      final result = await _aiService.generateExpectedQuestions(subject, grade);
      expectedQuestionsResult.value = result;
      _showResultDialog("الأسئلة المتوقعة", result);
    } catch (e) {
      _showErrorSnackbar("فشل توليد الأسئلة: $e");
    } finally {
      isGeneratingQuestions.value = false;
    }
  }

  Future<void> summarizeCommunityDiscussions(List<String> comments) async {
    isSummarizingDiscussions.value = true;
    try {
      final result = await _aiService.summarizeDiscussions(comments);
      discussionSummaryResult.value = result;
      _showResultDialog("ملخص المناقشات", result);
    } catch (e) {
      _showErrorSnackbar("فشل التلخيص: $e");
    } finally {
      isSummarizingDiscussions.value = false;
    }
  }

  Future<void> correctComment(String content) async {
    isCorrectingContent.value = true;
    try {
      final result = await _aiService.correctContent(content);
      _showResultDialog("تدقيق المحتوى", result);
    } catch (e) {
      _showErrorSnackbar("فشل التدقيق: $e");
    } finally {
      isCorrectingContent.value = false;
    }
  }

  Future<void> getGroupQuestions(String topic, List<String> interests) async {
    isGeneratingGroupQuestions.value = true;
    try {
      final questions = await _aiService.generateGroupQuestions(topic, interests);
      // Show questions in a list or dialog
      _showListDialog("أسئلة نقاش للمجموعة", questions.map((e) => e['question'] ?? "").toList());
    } catch (e) {
      _showErrorSnackbar("فشل توليد الأسئلة: $e");
    } finally {
      isGeneratingGroupQuestions.value = false;
    }
  }

  Future<void> suggestTasks(List<String> members, String goal) async {
    isSuggestingTasks.value = true;
    try {
      final result = await _aiService.suggestTaskAssignment(members, goal);
      _showResultDialog("توزيع المهام المقترح", result);
    } catch (e) {
      _showErrorSnackbar("فشل اقتراح المهام: $e");
    } finally {
      isSuggestingTasks.value = false;
    }
  }

  var isGeneratingSummary = false.obs;
  var isGeneratingExam = false.obs;
  var isTranslating = false.obs;

  var isGeneratingFlashcards = false.obs;
  var isConvertingToTable = false.obs;
  var flashcards = <Map<String, String>>[].obs;

  Future<void> generateLessonFlashcards(String lessonId, String content) async {
    isGeneratingFlashcards.value = true;
    try {
      final result = await _aiService.generateFlashcards(lessonId, content);
      flashcards.assignAll(result);
      _showFlashcardsDialog();
    } catch (e) {
      _showErrorSnackbar("فشل توليد البطاقات: $e");
    } finally {
      isGeneratingFlashcards.value = false;
    }
  }

  Future<void> simplifyForKids(String concept) async {
    isGeneratingSummary.value = true;
    try {
      final result = await _aiService.explainLikeI5(concept);
      _showResultDialog("اشرح لي كأني طفل (5 سنوات)", result);
    } catch (e) {
      _showErrorSnackbar("فشل التبسيط: $e");
    } finally {
      isGeneratingSummary.value = false;
    }
  }

  Future<void> convertToTable(String notes) async {
    isConvertingToTable.value = true;
    try {
      final result = await _aiService.convertNotesToTable(notes);
      _showResultDialog("تحويل الملاحظات لجدول", result);
    } catch (e) {
      _showErrorSnackbar("فشل التحويل: $e");
    } finally {
      isConvertingToTable.value = false;
    }
  }

  void _showFlashcardsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("بطاقات الاستذكار الذكية (Flashcards)"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: flashcards.length,
            itemBuilder: (context, index) {
              final card = flashcards[index];
              return Card(
                child: ExpansionTile(
                  title: Text(card['front'] ?? ""),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Text(card['back'] ?? "", style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("حسناً")),
        ],
      ),
    );
  }

  Future<void> generatePracticeExam(String courseId, String title) async {
    isGeneratingExam.value = true;
    try {
      final exam = await _aiService.generateExam(courseId, title);
      _showResultDialog("امتحان تجريبي شامل", exam);
    } catch (e) {
      _showErrorSnackbar("فشل توليد الامتحان: $e");
    } finally {
      isGeneratingExam.value = false;
    }
  }

  Future<void> translateLesson(String text, String targetLang) async {
    isTranslating.value = true;
    try {
      final translated = await _aiService.translate(text, targetLang);
      _showResultDialog("الترجمة ($targetLang)", translated);
    } catch (e) {
      _showErrorSnackbar("فشل الترجمة: $e");
    } finally {
      isTranslating.value = false;
    }
  }

  void _showResultDialog(String title, String content) {
    Get.dialog(
      AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("حسناً")),
        ],
      ),
    );
  }

  void _showListDialog(String title, List<String> items) {
    Get.dialog(
      AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text("${index + 1}")),
              title: Text(items[index]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("حسناً")),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar("خطأ", message,
        backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }
}
