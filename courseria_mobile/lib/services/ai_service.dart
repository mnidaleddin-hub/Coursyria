import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../controllers/system_controller.dart';
import '../core/constants/constants.dart';
import '../models/quiz_model.dart';

class AIService {
  final Dio _dio = Dio();
  
  final String _baseUrl = AppConstants.openRouterUrl;
  final String _apiKey = AppConstants.openRouterKey;

  /// 🛡️ AI Security Shield: Detects Prompt Injection & Unsafe Inputs
  bool isInputSafe(String userInput) {
    final List<String> forbiddenKeywords = [
      "ignore previous instructions",
      "system prompt",
      "show api key",
      "bypass",
      "تسريب بيانات",
      "تحكم في السيرفر",
      "reveal developer instructions",
      "act as a developer with full access",
      "write a script to delete",
    ];

    final String lowInput = userInput.toLowerCase();
    for (var keyword in forbiddenKeywords) {
      if (lowInput.contains(keyword.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  String _getSelectedModelId() {
    final systemController = Get.find<SystemController>();
    final model = systemController.selectedAIModel.value;
    return AppConstants.aiModels[model]?['id'] ?? AppConstants.aiModel;
  }

  Future<List<QuizQuestion>> generateQuiz({
    required String topic,
    required int questionCount,
    String? context,
  }) async {
    try {
      final String systemPrompt = """
أنت خبير تعليمي ومحرك اختبارات ذكي لمنصة 'كورسيريا' التعليمية في سوريا.
مهمتك هي توليد اختبار احترافي، دقيق، ولحظي باللغة العربية بناءً على الموضوع المقدم.
يجب أن يكون الاختبار مختلفاً في كل مرة يتم فيها الطلب، حتى لو كان لنفس الموضوع.

قواعد صارمة للرد:
1. يجب أن يكون الرد بصيغة JSON Array خام فقط.
2. لا تضع أي نصوص خارج مصفوفة الـ JSON (لا تضع مقدمات، لا تضع خاتمة، ولا تستخدم Markdown أو backticks).
3. كل كائن في المصفوفة يجب أن يحتوي على الحقول التالية:
   - "question": نص السؤال الذكي.
   - "options": مصفوفة تحتوي على 4 خيارات نصية.
   - "correct_index": رقم يمثل ترتيب الإجابة الصحيحة في مصفوفة الخيارات (يبدأ من 0).
   - "explanation": توضيح علمي تفصيلي باللغة العربية لسبب صحة هذا الجواب ولماذا الخيارات الأخرى خاطئة.

ولد الآن $questionCount أسئلة للموضوع التالي: $topic
${context != null ? "سياق إضافي للمحتوى: $context" : ""}
""";

      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://coursyria.com",
            "X-Title": "Coursyria LMS",
          },
        ),
        data: {
          "model": _getSelectedModelId(),
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": "ابدأ توليد الاختبار الآن بصيغة JSON Array خام."}
          ],
          "temperature": 0.8,
        },
      );

      if (response.statusCode == 200) {
        String rawContent = response.data['choices'][0]['message']['content'];
        rawContent = _cleanJsonResponse(rawContent);
        
        final List<dynamic> jsonList = jsonDecode(rawContent);
        return jsonList.map((json) => QuizQuestion.fromJson(json)).toList();
      } else {
        throw "فشل الاتصال بخدمة الذكاء الاصطناعي: ${response.statusCode}";
      }
    } catch (e) {
      if (kDebugMode) print("AI Generation Error: $e");
      rethrow;
    }
  }

  Future<String> generateSupportResponse(List<Map<String, String>> chatHistory) async {
    try {
      // Security Check for the last user message
      if (chatHistory.isNotEmpty && chatHistory.last['role'] == 'user') {
        if (!isInputSafe(chatHistory.last['content']!)) {
          return "عذراً، تم رصد محاولة تلاعب أمني. يرجى الالتزام بالأسئلة التعليمية والفنية لحماية حسابك 🛡️";
        }
      }

      const String systemPrompt = """
أنت 'مسؤول الدعم الفني الذكي لمنصة كورسيريا' برتبة مهندس. مهمتك هي مساعدة الطلاب السوريين وحل مشاكلهم التقنية والتعليمية بلغة عربية مهذبة، دافئة، وداعمة جداً.

قاعدتك المعرفية الصارمة:
1. طريقة الشحن: يتم نسخ معرف المحفظة من شاشة الشحن، ثم إرسال المبلغ عبر تطبيق 'شام كاش' بالـ 'ليرة سورية جديدة'، ثم إدخال رقم العملية في التطبيق وانتظار التفعيل الإداري.
2. استهلاك البيانات: نوفر جودات تبدأ من 144p لتقليل استهلاك الباقات السورية، وندعم التحميل أوفلاين المشفر لتوفير الإنترنت.
3. تجميد الـ Streak: للحفاظ على الـ Streak يجب فتح التطبيق ودراسة درس واحد يومياً على الأقل.
4. الهوية: نحن منصة كورسيريا، رائدة التعليم الرقمي في سوريا.

تعليمات الرد:
- كن ودوداً واستخدم كلمات مثل 'يا بطل'، 'أهلاً بك'، 'يسعدني مساعدتك'.
- إذا كانت المشكلة تتطلب تدخلاً بشرياً، اقترح على الطالب التحويل لوكيل بشري.
- استخدم مصطلح 'ليرة سورية جديدة' دائماً عند الحديث عن المبالغ المالية.
""";

      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://coursyria.com",
            "X-Title": "Coursyria LMS Support",
          },
        ),
        data: {
          "model": _getSelectedModelId(),
          "messages": [
            {"role": "system", "content": systemPrompt},
            ...chatHistory.map((msg) => {
              "role": msg['role'],
              "content": msg['content']
            }),
          ],
          "temperature": 0.7,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].toString().trim();
      } else {
        return "عذراً، واجهت مشكلة في الاتصال بالسيرفر. يرجى المحاولة لاحقاً.";
      }
    } catch (e) {
      if (kDebugMode) print("AI Support Error: $e");
      return "عذراً يا بطل، حدث خطأ تقني بسيط. يمكنك المحاولة مرة أخرى أو طلب وكيل بشري.";
    }
  }

  Future<String> summarizeLesson(String title, String description) async {
    try {
      final String prompt = "لخص لي هذا الدرس بشكل نقاط أساسية واحترافية باللغة العربية: العنوان: $title، الوصف: $description. اجعل الملخص مفيداً جداً للطالب السوري ومنسقاً بـ Markdown.";
      
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://coursyria.com",
            "X-Title": "Coursyria Summarizer",
          },
        ),
        data: {
          "model": _getSelectedModelId(),
          "messages": [
            {"role": "system", "content": "أنت خبير في تلخيص المحتوى التعليمي لمنصة كورسيريا."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.5,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].toString().trim();
      }
      return "فشل في توليد الملخص.";
    } catch (e) {
      return "حدث خطأ أثناء التلخيص: $e";
    }
  }

  Future<String> suggestSmartReply(String studentQuestion) async {
    try {
      if (!isInputSafe(studentQuestion)) {
        return "لا يمكن الرد على هذا السؤال نظراً لوجود محتوى غير آمن.";
      }
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://coursyria.com",
            "X-Title": "Coursyria Teacher Assistant",
          },
        ),
        data: {
          "model": _getSelectedModelId(),
          "messages": [
            {"role": "system", "content": "أنت مساعد ذكي للأستاذ في منصة كورسيريا. اقترح رداً علمياً دقيقاً ومهذباً باللغة العربية على سؤال الطالب التالي."},
            {"role": "user", "content": studentQuestion}
          ],
          "temperature": 0.6,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].toString().trim();
      }
      return "لم يتم التوصل لاقتراح.";
    } catch (e) {
      return "خطأ في الاقتراح الذكي.";
    }
  }

  Future<String> generateLearningRecommendations(List<Map<String, dynamic>> quizResults) async {
    try {
      if (quizResults.isEmpty) {
        return "أهلاً بك يا بطل! ابدأ بحل الاختبارات لنقوم بتحليل مستواك وتقديم نصائح مخصصة لك.";
      }

      final String prompt = "بناءً على نتائج الاختبارات التالية للطالب، قدم له نصيحة تعليمية دافئة ومخصصة باللغة العربية تشرح نقاط قوته وضعفه وماذا يجب أن يفعل لرفع ترتيبه: $quizResults";

      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            "Authorization": "Bearer $_apiKey",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://coursyria.com",
            "X-Title": "Coursyria Path Advisor",
          },
        ),
        data: {
          "model": _getSelectedModelId(),
          "messages": [
            {"role": "system", "content": "أنت 'مستشار المسار التعليمي الذكي' لمنصة كورسيريا. وظيفتك تحليل أداء الطلاب وتحفيزهم."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].toString().trim();
      }
      return "لم نتمكن من توليد نصيحة حالياً. استمر في الاجتهاد!";
    } catch (e) {
      return "استمر في التعلم يا بطل، أنت تبلي بلاءً حسناً!";
    }
  }

  String _cleanJsonResponse(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith("```json")) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith("```")) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith("```")) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
