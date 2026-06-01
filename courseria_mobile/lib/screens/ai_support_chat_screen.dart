import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controllers/support_chat_controller.dart';
import '../core/constants/constants.dart';

class AISupportChatScreen extends StatelessWidget {
  final SupportChatController _controller = Get.put(SupportChatController());
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AISupportChatScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("الدعم الفني الذكي", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            Obx(() => Text(
              _controller.ticketStatus.value == 'pending_human' ? "قيد المراجعة البشرية 👨‍💻" : "متصل الآن (AI) 🤖",
              style: TextStyle(color: AppColors.accentTeal, fontSize: 10.sp),
            )),
          ],
        ),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Obx(() => _controller.ticketStatus.value == 'open' 
            ? TextButton.icon(
                onPressed: () => _controller.escalateToHuman(),
                icon: const Icon(Icons.person_search_rounded, color: AppColors.accentTeal, size: 18),
                label: const Text("وكيل بشري", style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
              )
            : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              _scrollToBottom();
              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(20.w),
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  final message = _controller.messages[index];
                  final isUser = message['role'] == 'user';
                  return _buildMessageBubble(message['content']!, isUser);
                },
              );
            }),
          ),
          Obx(() => _controller.isTyping.value ? _buildTypingIndicator() : const SizedBox.shrink()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h, left: isUser ? 50.w : 0, right: isUser ? 0 : 50.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentTeal : AppColors.secondaryNavy,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.secondaryNavy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text("البوت يفكر", style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
                SizedBox(width: 8.w),
                SizedBox(
                  width: 20.w,
                  height: 10.h,
                  child: Lottie.network(
                    'https://assets5.lottiefiles.com/packages/lf20_6p8ovhvp.json', // Typing dots animation
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(20.w),
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
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "اكتب رسالتك هنا...",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  _controller.sendMessage(val);
                  _messageController.clear();
                },
              ),
            ),
          ),
          SizedBox(width: 15.w),
          GestureDetector(
            onTap: () {
              _controller.sendMessage(_messageController.text);
              _messageController.clear();
            },
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: const BoxDecoration(
                color: AppColors.accentTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
