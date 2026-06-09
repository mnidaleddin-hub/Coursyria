import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../controllers/group_controller.dart';
import '../models/chat_message_model.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/offline_banner.dart';

class CourseChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const CourseChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<CourseChatScreen> createState() => _CourseChatScreenState();
}

class _CourseChatScreenState extends State<CourseChatScreen> {
  final GroupController _groupController = Get.find<GroupController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Rx<ChatMessage?> _replyToMessage = Rx<ChatMessage?>(null);

  @override
  void initState() {
    super.initState();
    _groupController.fetchGroupDetails(widget.groupId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const OfflineBanner(),
          _buildPinnedMessageHeader(),
          Expanded(
            child: Obx(() {
              if (_groupController.chatMessages.isEmpty && _groupController.isLoadingGroups.value) {
                return const Center(child: AppLoadingIndicator());
              }
              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                itemCount: _groupController.chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _groupController.chatMessages[index];
                  final isMe = message.userId == _groupController.supabase.auth.currentUser?.id;
                  return _buildMessageBubble(message, isMe);
                },
              );
            }),
          ),
          _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.secondaryNavy,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.groupName, style: AppTextStyles.header.copyWith(fontSize: 16.sp, color: Colors.white)),
          Obx(() {
            final onlineCount = _groupController.onlineMembers.length;
            return Text(
              "$onlineCount متصل الآن",
              style: AppTextStyles.body.copyWith(fontSize: 10.sp, color: AppColors.accentTeal),
            );
          }),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.magnifyingGlass(), color: Colors.white),
          onPressed: () {
            // TODO: Chat Search
          },
        ),
        IconButton(
          icon: Icon(PhosphorIcons.dotsThreeVertical(), color: Colors.white),
          onPressed: () {
            // TODO: Group Options
          },
        ),
      ],
    );
  }

  Widget _buildPinnedMessageHeader() {
    return Obx(() {
      if (_groupController.pinnedMessages.isEmpty) return const SizedBox.shrink();
      final pinned = _groupController.pinnedMessages.last;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.accentTeal.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: AppColors.accentTeal.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            Icon(PhosphorIcons.pushPin(PhosphorIconsStyle.fill), color: AppColors.accentTeal, size: 16.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                pinned.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white38, size: 16.r),
              onPressed: () {
                // TODO: Unpin or hide
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTypingIndicator() {
    return Obx(() {
      if (_groupController.typingUsers.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        alignment: Alignment.centerLeft,
        child: Text(
          "${_groupController.typingUsers.length} يكتبون...",
          style: TextStyle(color: AppColors.accentTeal, fontSize: 10.sp, fontStyle: FontStyle.italic),
        ),
      );
    });
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: EdgeInsets.only(left: 10.w, bottom: 4.h),
              child: Text(message.userName ?? "عضو", 
                style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            ),
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(12.r),
            constraints: BoxConstraints(maxWidth: Get.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.accentTeal : AppColors.secondaryNavy,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.r),
                topRight: Radius.circular(15.r),
                bottomLeft: isMe ? Radius.circular(15.r) : Radius.zero,
                bottomRight: isMe ? Radius.zero : Radius.circular(15.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.replyToId != null) _buildReplyPreview(message.replyToId!),
                if (message.imageUrl != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: CachedNetworkImage(imageUrl: message.imageUrl!),
                    ),
                  ),
                if (message.audioUrl != null) _buildVoicePlayer(message),
                if (message.content.isNotEmpty)
                  Text(message.content, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${message.createdAt.hour}:${message.createdAt.minute}",
                      style: TextStyle(color: Colors.white38, fontSize: 9.sp),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 4.w),
                      Icon(
                        message.status == 'read' ? Icons.done_all : Icons.done,
                        color: message.status == 'read' ? Colors.blueAccent : Colors.white38,
                        size: 12.sp,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(String replyId) {
    // Find message being replied to
    final repliedMsg = _groupController.chatMessages.firstWhereOrNull((m) => m.id == replyId);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8.r),
        border: const Border(right: BorderSide(color: AppColors.accentTeal, width: 3)),
      ),
      child: Text(
        repliedMsg?.content ?? "رسالة محذوفة",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
      ),
    );
  }

  Widget _buildVoicePlayer(ChatMessage message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), color: Colors.white),
          SizedBox(width: 10.w),
          Expanded(child: LinearProgressIndicator(value: 0, backgroundColor: Colors.white12)),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () {
              // TODO: Change voice speed
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Text("${message.voiceSpeed}x", style: TextStyle(color: Colors.white, fontSize: 10.sp)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (_replyToMessage.value == null) return const SizedBox.shrink();
              return Container(
                padding: EdgeInsets.all(10.r),
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.arrowBendUpLeft(), color: AppColors.accentTeal, size: 16.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _replyToMessage.value!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16.r, color: Colors.white38),
                      onPressed: () => _replyToMessage.value = null,
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.plus(), color: AppColors.accentTeal),
                  onPressed: _showAttachmentSheet,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => _groupController.setTyping(widget.groupId, val.isNotEmpty),
                      decoration: InputDecoration(
                        hintText: "اكتب رسالة...",
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
                        border: InputBorder.none,
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppColors.accentTeal,
                    child: Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), color: Colors.white, size: 20.r),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAttachmentOption(PhosphorIcons.image(), "صورة", _pickImage),
            _buildAttachmentOption(PhosphorIcons.microphone(), "صوت", _pickAudio),
            _buildAttachmentOption(PhosphorIcons.file(), "ملف", _pickFile),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Get.back();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundColor: AppColors.accentTeal.withOpacity(0.1),
            child: Icon(icon, color: AppColors.accentTeal),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      _groupController.sendMessage(widget.groupId, "", image: File(img.path));
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      _groupController.sendMessage(widget.groupId, "", audio: File(result.files.single.path!));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      _groupController.sendMessage(widget.groupId, "", file: File(result.files.single.path!));
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _groupController.sendMessage(
      widget.groupId,
      _messageController.text.trim(),
      replyToId: _replyToMessage.value?.id,
    );
    _messageController.clear();
    _replyToMessage.value = null;
    _groupController.setTyping(widget.groupId, false);
    _scrollToBottom();
  }
}
