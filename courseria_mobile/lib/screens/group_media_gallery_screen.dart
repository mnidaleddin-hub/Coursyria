import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/colors.dart';
import '../controllers/group_controller.dart';
import '../models/chat_message_model.dart';

class GroupMediaGalleryScreen extends StatelessWidget {
  final String groupId;
  final String groupName;

  const GroupMediaGalleryScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final GroupController groupController = Get.find<GroupController>();
    
    // Filter messages that have media
    final mediaMessages = groupController.chatMessages.where((m) => m.imageUrl != null || m.fileUrl != null).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          backgroundColor: AppColors.secondaryNavy,
          title: Text("وسائط المجموعة - $groupName", style: TextStyle(fontSize: 16.sp, color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: AppColors.accentTeal,
            tabs: [
              Tab(text: "الصور"),
              Tab(text: "الملفات"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildImageGrid(mediaMessages.where((m) => m.imageUrl != null).toList()),
            _buildFileList(mediaMessages.where((m) => m.fileUrl != null).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<ChatMessage> messages) {
    if (messages.isEmpty) return _buildEmptyState("لا توجد صور");
    return GridView.builder(
      padding: EdgeInsets.all(10.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5.r,
        mainAxisSpacing: 5.r,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // TODO: Open Full Screen
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: messages[index].imageUrl!,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileList(List<ChatMessage> messages) {
    if (messages.isEmpty) return _buildEmptyState("لا توجد ملفات");
    return ListView.builder(
      padding: EdgeInsets.all(10.r),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Card(
          color: AppColors.secondaryNavy,
          child: ListTile(
            leading: Icon(PhosphorIcons.filePdf(), color: AppColors.accentTeal),
            title: Text(msg.fileName ?? "ملف غير معروف", style: const TextStyle(color: Colors.white)),
            subtitle: Text(AppConstants.formatTimeAgo(msg.createdAt), style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
            trailing: Icon(PhosphorIcons.downloadSimple(), color: Colors.white),
            onTap: () {
              // TODO: Download file
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.folderOpen(), color: Colors.white12, size: 80.r),
          SizedBox(height: 20.h),
          Text(message, style: TextStyle(color: Colors.white38, fontSize: 16.sp)),
        ],
      ),
    );
  }
}

class AppConstants {
  static String formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return "${diff.inDays} يوم";
    if (diff.inHours > 0) return "${diff.inHours} ساعة";
    if (diff.inMinutes > 0) return "${diff.inMinutes} دقيقة";
    return "الآن";
  }
}
