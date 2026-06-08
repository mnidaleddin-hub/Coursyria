import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import '../services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FAQScreen extends StatefulWidget {
  final String? courseId;
  const FAQScreen({super.key, this.courseId});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = Get.find<AIService>();
  
  var faqs = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var isGenerating = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchFAQs();
  }

  Future<void> _fetchFAQs() async {
    try {
      isLoading.value = true;
      var query = _supabase.from('faqs').select('*');
      if (widget.courseId != null) {
        query = query.eq('course_id', widget.courseId!);
      }
      
      final response = await query.order('created_at', ascending: false);
      faqs.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching FAQs: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _generateFAQ() async {
    if (widget.courseId == null) return;
    
    try {
      isGenerating.value = true;
      // Fetch course info to give context to AI
      final course = await _supabase.from('courses').select('title, description').eq('id', widget.courseId!).single();
      
      final result = await _aiService.callAIGateway(
        feature: 'chat', // Use chat or specific FAQ feature if available
        lessonId: 'global',
        userPrompt: "ولد قائمة بـ 5 أسئلة شائعة وإجاباتها حول كورس بعنوان '${course['title']}' ووصفه: '${course['description']}'. بصيغة JSON Array يحتوي على objects بها (question, answer).",
      );

      if (result.success) {
        // Parse and save to DB
        // For simplicity, we'll just show it or you can implement saving logic
        Get.snackbar("AI FAQ", "تم توليد الأسئلة بنجاح (سيتم حفظها في التحديث القادم)");
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل توليد الأسئلة");
    } finally {
      isGenerating.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("الأسئلة الشائعة"),
        actions: [
          if (widget.courseId != null)
            IconButton(
              onPressed: _generateFAQ,
              icon: const Icon(Icons.auto_awesome),
              tooltip: "توليد بالذكاء الاصطناعي",
            ),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) return const Center(child: CircularProgressIndicator());
        if (faqs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                const Text("لا توجد أسئلة شائعة بعد", style: TextStyle(color: Colors.white38)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return ExpansionTile(
              title: Text(faq['question'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(faq['answer'], style: const TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
