import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/constants.dart';
import '../controllers/group_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/group_post_model.dart';

class GroupPostsScreen extends StatefulWidget {
  final String groupId;
  const GroupPostsScreen({super.key, required this.groupId});

  @override
  State<GroupPostsScreen> createState() => _GroupPostsScreenState();
}

class _GroupPostsScreenState extends State<GroupPostsScreen> {
  final GroupController _groupController = Get.find<GroupController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _postContentController = TextEditingController();
  final Rx<File?> _selectedPostImage = Rx<File?>(null);

  @override
  void initState() {
    super.initState();
    _groupController.fetchGroupPosts(widget.groupId);
  }

  @override
  void dispose() {
    _postContentController.dispose();
    _selectedPostImage.value = null;
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 700,
    );
    if (image != null) {
      _selectedPostImage.value = File(image.path);
    }
  }

  Future<void> _createPost() async {
    if (_postContentController.text.trim().isEmpty && _selectedPostImage.value == null) return;
    
    await _groupController.createGroupPost(
      widget.groupId,
      _postContentController.text,
      image: _selectedPostImage.value,
    );
    _postContentController.clear();
    _selectedPostImage.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPostInput(),
        Expanded(
          child: Obx(() {
            if (_groupController.isLoadingGroupPosts.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
            } else if (_groupController.groupPosts.isEmpty) {
              return Center(
                child: Text("لا توجد منشورات في هذه المجموعة بعد.",
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () => _groupController.fetchGroupPosts(widget.groupId),
                color: AppColors.accentTeal,
                child: ListView.builder(
                  padding: EdgeInsets.all(20.r),
                  itemCount: _groupController.groupPosts.length,
                  itemBuilder: (context, index) {
                    final post = _groupController.groupPosts[index];
                    return _buildPostCard(post);
                  },
                ),
              );
            }
          }),
        ),
      ],
    );
  }

  Widget _buildPostInput() {
    return Obx(() => Container(
          margin: EdgeInsets.all(20.r),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: AppColors.accentTeal.withOpacity(0.2),
                    backgroundImage: _authController.userProfile.value?.avatarUrl != null &&
                            _authController.userProfile.value!.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(_authController.userProfile.value!.avatarUrl!)
                        : null,
                    child: _authController.userProfile.value?.avatarUrl == null ||
                            _authController.userProfile.value!.avatarUrl!.isEmpty
                        ? Icon(PhosphorIcons.user(), color: AppColors.accentTeal, size: 24.r)
                        : null,
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: TextField(
                      controller: _postContentController,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "اكتب شيئاً للمجموعة...",
                        hintStyle: AppTextStyles.body.copyWith(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      minLines: 1,
                    ),
                  ),
                ],
              ),
              if (_selectedPostImage.value != null)
                Padding(
                  padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15.r),
                        child: Image.file(
                          _selectedPostImage.value!,
                          height: 120.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _selectedPostImage.value = null,
                        child: Container(
                          margin: EdgeInsets.all(5.r),
                          padding: EdgeInsets.all(5.r),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Icon(Icons.close, color: Colors.white, size: 18.r),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: Icon(PhosphorIcons.image(), color: AppColors.accentTeal, size: 24.r),
                    tooltip: "إضافة صورة",
                  ),
                  ElevatedButton(
                    onPressed: _groupController.isLoadingGroupPosts.value ? null : _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    ),
                    child: Text("نشر", style: AppTextStyles.button.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildPostCard(GroupPost post) {
    final bool isOwner = _groupController.currentGroup.value?.ownerId == _authController.userProfile.value?.id;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: post.isPinned ? AppColors.accentTeal.withOpacity(0.05) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: post.isPinned ? AppColors.accentTeal.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isPinned)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Icon(PhosphorIcons.pushPinFill(), color: AppColors.accentTeal, size: 16.r),
                  SizedBox(width: 5.w),
                  Text("منشور مثبت", style: AppTextStyles.body.copyWith(color: AppColors.accentTeal, fontSize: 10.sp)),
                ],
              ),
            ),
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.accentTeal.withOpacity(0.2),
                backgroundImage: post.userAvatarUrl != null && post.userAvatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(post.userAvatarUrl!)
                    : null,
                child: post.userAvatarUrl == null || post.userAvatarUrl!.isEmpty
                    ? Icon(PhosphorIcons.user(), color: AppColors.accentTeal, size: 20.r)
                    : null,
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.userName ?? "مستخدم كورسيريا",
                      style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 13.sp)),
                  Text(AppConstants.formatTimeAgo(post.createdAt),
                      style: AppTextStyles.body.copyWith(color: Colors.white38, fontSize: 10.sp)),
                ],
              ),
              const Spacer(),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white38, size: 20.r),
                  color: AppColors.primaryNavy,
                  onSelected: (value) {
                    if (value == 'pin') {
                      _groupController.togglePinPost(post.id, post.isPinned);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(post.isPinned ? PhosphorIcons.pushPinSlash() : PhosphorIcons.pushPin(), color: Colors.white, size: 18.r),
                          SizedBox(width: 10.w),
                          Text(post.isPinned ? "إلغاء التثبيت" : "تثبيت المنشور", style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 15.h),
          Text(
            post.content,
            style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 14.sp, height: 1.5),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    height: 200.h,
                    color: Colors.white.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator(color: AppColors.accentTeal)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200.h,
                    color: Colors.white.withOpacity(0.1),
                    child: Icon(Icons.broken_image, color: Colors.white38, size: 50.r),
                  ),
                ),
              ),
            ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildActionButton(
                icon: post.isLiked == true ? PhosphorIcons.heartFill() : PhosphorIcons.heart(),
                label: post.likesCount.toString(),
                isActive: post.isLiked == true,
                onTap: () {
                  if (post.isLiked == true) {
                    _groupController.unlikeGroupPost(post.id);
                  } else {
                    _groupController.likeGroupPost(post.id);
                  }
                },
                activeColor: Colors.redAccent,
              ),
              SizedBox(width: 25.w),
              _buildActionButton(
                icon: PhosphorIcons.chatCircle(),
                label: post.commentsCount.toString(),
                onTap: () {
                  // TODO: Implement comments for group posts
                  Get.snackbar("التعليقات", "سيتم تنفيذ التعليقات قريباً");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
    Color activeColor = AppColors.accentTeal,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isActive ? activeColor : Colors.white38, size: 20.r),
          SizedBox(width: 8.w),
          Text(label, style: AppTextStyles.body.copyWith(color: Colors.white38, fontSize: 12.sp)),
        ],
      ),
    );
  }
}
