import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_service.dart';
import '../core/constants/constants.dart';
import '../widgets/app_loading_indicator.dart';

class AIChatScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const AIChatScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final RxList<Map<String, String>> _messages = <Map<String, String>>[].obs;
  final RxBool _isTyping = false.obs;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'role': 'assistant',
      'content': 'أهلاً بك يا بطل! أنا مساعدك الذكي لدرس "${widget.lessonTitle}". كيف يمكنني مساعدتك في فهم المحتوى اليوم؟'
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping.value) return;

    _messageController.clear();
    _messages.add({'role': 'user', 'content': text});
    _scrollToBottom();

    _isTyping.value = true;

    try {
      final response = await _aiService.chatWithAI(
        lessonId: widget.lessonId,
        userMessage: text,
        chatHistory: _messages.take(_messages.length - 1).toList(),
      );

      if (response.success) {
        _messages.add({'role': 'assistant', 'content': response.content});
      } else {
        _messages.add({'role': 'assistant', 'content': 'عذراً، واجهت مشكلة في الاتصال. يرجى المحاولة مرة أخرى.'});
      }
    } catch (e) {
      _messages.add({'role': 'assistant', 'content': 'حدث خطأ غير متوقع. يرجى التحقق من اتصالك بالإنترنت.'});
    } finally {
      _isTyping.value = false;
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("المساعد الذكي", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            Text(widget.lessonTitle, style: TextStyle(fontSize: 10.sp, color: Colors.white70), overflow: TextOverflow.ellipsis),
          ],
        ),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(20.r),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg['content']!, msg['role'] == 'user');
              },
            )),
          ),
          Obx(() => _isTyping.value ? _buildTypingIndicator() : const SizedBox.shrink()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h, left: isUser ? 40.w : 0, right: isUser ? 0 : 40.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentTeal : AppColors.secondaryNavy,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
        ),
        child: MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          Text("الذكاء الاصطناعي يفكر...", style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
          SizedBox(width: 8.w),
          SizedBox(width: 15.w, height: 15.w, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: const BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "اسأل أي شيء عن الدرس...",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: const BoxDecoration(color: AppColors.accentTeal, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
