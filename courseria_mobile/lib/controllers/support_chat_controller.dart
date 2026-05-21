import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import 'auth_controller.dart';

class SupportChatController extends GetxController {
  final AIService _aiService = AIService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var messages = <Map<String, String>>[].obs;
  var isLoading = false.obs;
  var isTyping = false.obs;
  var ticketId = "".obs;
  var ticketStatus = "open".obs;

  @override
  void onInit() {
    super.onInit();
    _initializeTicket();
  }

  Future<void> _initializeTicket() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check for active ticket or create new one
      final existingTicket = await _supabase
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .neq('status', 'closed')
          .maybeSingle();

      if (existingTicket != null) {
        ticketId.value = existingTicket['id'].toString();
        ticketStatus.value = existingTicket['status'];
        _loadMessages();
      } else {
        final newTicket = await _supabase.from('support_tickets').insert({
          'user_id': userId,
          'status': 'open',
          'subject': 'General Support',
        }).select().single();
        ticketId.value = newTicket['id'].toString();
      }
      
      // Add welcome message if empty
      if (messages.isEmpty) {
        messages.add({
          "role": "assistant",
          "content": "أهلاً بك يا بطل في دعم كورسيريا الفني! أنا مهندس الدعم الذكي، كيف يمكنني مساعدتك اليوم؟"
        });
      }
    } catch (e) {
      print("Error initializing ticket: $e");
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('ticket_messages')
          .select()
          .eq('ticket_id', ticketId.value)
          .order('created_at', ascending: true);
      
      final loadedMessages = (response as List).map((m) => {
        "role": m['sender_type'] == 'ai' ? 'assistant' : 'user',
        "content": m['content'].toString(),
      }).toList();

      if (loadedMessages.isNotEmpty) {
        messages.assignAll(loadedMessages);
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = {"role": "user", "content": content};
    messages.add(userMessage);
    
    // Save user message to Supabase
    await _saveMessage(content, 'user');

    // Check for escalation keywords
    if (content.contains("أريد التحدث مع موظف") || content.contains("مشكلة في الحساب")) {
      // Logic handled in UI via button or auto-escalate
    }

    // Get AI Response
    isTyping.value = true;
    final aiResponse = await _aiService.generateSupportResponse(messages.toList());
    isTyping.value = false;

    messages.add({"role": "assistant", "content": aiResponse});
    
    // Save AI response to Supabase
    await _saveMessage(aiResponse, 'ai');
  }

  Future<void> _saveMessage(String content, String senderType) async {
    try {
      await _supabase.from('ticket_messages').insert({
        'ticket_id': ticketId.value,
        'content': content,
        'sender_type': senderType,
        'sender_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      print("Error saving message: $e");
    }
  }

  Future<void> escalateToHuman() async {
    try {
      isLoading.value = true;
      await _supabase
          .from('support_tickets')
          .update({'status': 'pending_human'})
          .eq('id', ticketId.value);
      
      ticketStatus.value = 'pending_human';
      
      final msg = "تم تحويل طلبك لوكيل بشري بنجاح. سيتواصل معك أحد مهندسينا في أقرب وقت ممكن. يمكنك الاستمرار في الدردشة معي هنا في هذه الأثناء.";
      messages.add({"role": "assistant", "content": msg});
      await _saveMessage(msg, 'ai');
      
      isLoading.value = false;
      Get.snackbar("تم التحويل", "طلبك الآن قيد المراجعة من قبل فريق الدعم البشري",
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      isLoading.value = false;
      print("Error escalating ticket: $e");
    }
  }
}
