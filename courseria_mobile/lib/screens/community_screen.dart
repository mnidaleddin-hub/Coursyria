import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants/constants.dart';
import '../controllers/community_controller.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/ai_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/app_loading_indicator.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityController _communityController = Get.put(CommunityController());
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _postContentController = TextEditingController();
  final TextEditingController _commentContentController = TextEditingController();
  final Rx<File?> _selectedPostImage = Rx<File?>(null);

  @override
  void initState() {
    super.initState();
    _communityController.fetchPosts();
  }

  @override
  void dispose() {
    _postContentController.dispose();
    _commentContentController.dispose();
    _selectedPostImage.value = null; 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("مجتمع التعلم", style: AppTextStyles.header.copyWith(fontSize: 18.sp, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildPostInput(),
          Expanded(
            child: Obx(() {
              return Skeletonizer(
                enabled: _communityController.isLoadingPosts.value,
                child: _communityController.posts.isEmpty && !_communityController.isLoadingPosts.value
                    ? Center(
                        child: Text("لا توجد منشورات حالياً.",
                            style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                      )
                    : RefreshIndicator(
                        onRefresh: _communityController.fetchPosts,
                        color: context.theme.primaryColor,
                        child: ListView.builder(
                          padding: EdgeInsets.all(20.r),
                          itemCount: _communityController.isLoadingPosts.value ? 2 : _communityController.posts.length,
                          itemBuilder: (context, index) {
                            if (_communityController.isLoadingPosts.value) {
                              return _buildFakePostCard();
                            }
                            final post = _communityController.posts[index];
                            return _buildPostCard(post);
                          },
                        ),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFakePostCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20.r, backgroundColor: Colors.grey),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 14, color: Colors.grey),
                  SizedBox(height: 4.h),
                  Container(width: 60, height: 10, color: Colors.grey),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(width: double.infinity, height: 14, color: Colors.grey),
          SizedBox(height: 8.h),
          Container(width: 200, height: 14, color: Colors.grey),
          SizedBox(height: 20.h),
          Row(
            children: [
              Container(width: 40, height: 20, color: Colors.grey),
              SizedBox(width: 20.w),
              Container(width: 40, height: 20, color: Colors.grey),
            ],
          ),
        ],
      ),
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
                    backgroundColor: context.theme.primaryColor.withOpacity(0.2),
                    backgroundImage: _authController.userProfile.value?.avatarUrl != null &&
                            _authController.userProfile.value!.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(_authController.userProfile.value!.avatarUrl!)
                        : null,
                    child: _authController.userProfile.value?.avatarUrl == null ||
                            _authController.userProfile.value!.avatarUrl!.isEmpty
                        ? Icon(PhosphorIcons.user(), color: context.theme.primaryColor, size: 24.r)
                        : null,
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: TextField(
                      controller: _postContentController,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "بماذا تفكر؟ شارك زملائك...",
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
                          height: 150.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _selectedPostImage.value = null,
                        child: Container(
                          margin: EdgeInsets.all(5.r),
                          padding: EdgeInsets.all(5.r),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
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
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(PhosphorIcons.image(), color: context.theme.primaryColor, size: 20.r),
                    label: Text("إضافة صورة", style: AppTextStyles.body.copyWith(color: context.theme.primaryColor)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _communityController.isLoadingPosts.value || (_postContentController.text.isEmpty && _selectedPostImage.value == null)
                        ? null
                        : _createPost,
                    icon: Icon(PhosphorIcons.paperPlaneTilt(), color: Colors.white, size: 20.r),
                    label: Text("نشر", style: AppTextStyles.button.copyWith(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: context.theme.primaryColor.withOpacity(0.2),
                backgroundImage: post.userAvatarUrl != null && post.userAvatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(post.userAvatarUrl!)
                    : null,
                child: post.userAvatarUrl == null || post.userAvatarUrl!.isEmpty
                    ? Icon(PhosphorIcons.user(), color: context.theme.primaryColor, size: 24.r)
                    : null,
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.userName ?? "مستخدم كورسيريا", style: AppTextStyles.header.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  Text(AppConstants.formatTimeAgo(post.createdAt), style: AppTextStyles.body.copyWith(color: Colors.white38, fontSize: 10.sp)),
                ],
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.white38, size: 20.sp),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            post.content,
            style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 14.sp, height: 1.5),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200.h,
                  placeholder: (context, url) => Container(
                    height: 200.h,
                    color: Colors.white.withOpacity(0.1),
                    child: const AppLoadingIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200.h,
                    color: Colors.white.withOpacity(0.1),
                    child: Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 50.r)),
                  ),
                ),
              ),
            ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildActionButton(
                icon: PhosphorIcons.heart(),
                label: post.likesCount.toString(),
                isActive: post.isLiked ?? false,
                onTap: () {
                  if (post.isLiked ?? false) {
                    _communityController.unlikePost(post.id);
                  } else {
                    _communityController.likePost(post.id);
                  }
                },
                activeColor: Colors.redAccent,
              ),
              SizedBox(width: 20.w),
              _buildActionButton(
                icon: PhosphorIcons.chatCircle(),
                label: post.commentsCount.toString(),
                onTap: () => _showCommentsBottomSheet(post),
                activeColor: context.theme.primaryColor,
              ),
              const Spacer(),
              _buildActionButton(
                icon: PhosphorIcons.shareNetwork(),
                label: "",
                onTap: () {
                  Get.snackbar("مشاركة", "سيتم تنفيذ وظيفة المشاركة قريباً");
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
    Color activeColor = Colors.white38,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isActive ? activeColor : Colors.white38, size: 20.sp),
          SizedBox(width: 6.w),
          Text(label, style: AppTextStyles.body.copyWith(color: Colors.white38, fontSize: 12.sp)),
        ],
      ),
    );
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
    await _communityController.createPost(
      _postContentController.text,
      image: _selectedPostImage.value,
    );
    _postContentController.clear();
    _selectedPostImage.value = null;
  }

  void _showCommentsBottomSheet(Post post) {
    final aiController = Get.find<AIController>();
    Get.bottomSheet(
      Obx(() => Container(
            height: Get.height * 0.8,
            padding: EdgeInsets.only(
              top: 20.h,
              left: 20.w,
              right: 20.w,
              bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("التعليقات", style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 18.sp)),
                    if (_communityController.commentsForPost.isNotEmpty)
                      _buildAIActionChip(
                        "ملخص ذكي",
                        Icons.auto_awesome_outlined,
                        () => aiController.summarizeCommunityDiscussions(
                          _communityController.commentsForPost.map((c) => c.content).toList(),
                        ),
                        isLoading: aiController.isSummarizingDiscussions,
                      ),
                  ],
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: _communityController.isCommentsLoading.value
                      ? const AppLoadingIndicator()
                      : _communityController.commentsForPost.isEmpty
                          ? Center(child: Text("لا توجد تعليقات بعد.", style: AppTextStyles.body.copyWith(color: AppColors.textMuted)))
                          : ListView.builder(
                              itemCount: _communityController.commentsForPost.length,
                              itemBuilder: (context, index) {
                                final comment = _communityController.commentsForPost[index];
                                return _buildCommentItem(comment);
                              },
                            ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentContentController,
                        style: AppTextStyles.body.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "أضف تعليقاً...",
                          hintStyle: AppTextStyles.body.copyWith(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    FloatingActionButton(
                      onPressed: _communityController.isCommentsLoading.value
                          ? null
                          : () async {
                              await _communityController.addComment(post.id, _commentContentController.text);
                              _commentContentController.clear();
                            },
                      mini: true,
                      backgroundColor: context.theme.primaryColor,
                      child: _communityController.isCommentsLoading.value
                          ? const AppLoadingIndicator(size: 20, strokeWidth: 2)
                          : Icon(PhosphorIcons.paperPlaneTilt(), color: Colors.white, size: 20.r),
                    ),
                  ],
                ),
              ],
            ),
          )),
      isScrollControlled: true,
    ).whenComplete(() {
      _communityController.commentsForPost.clear(); 
    });
    _communityController.fetchCommentsForPost(post.id);
  }

  Widget _buildAIActionChip(String label, IconData icon, VoidCallback onTap, {required RxBool isLoading}) {
    return Obx(() => ActionChip(
          onPressed: isLoading.value ? null : onTap,
          avatar: isLoading.value
              ? SizedBox(height: 12.h, width: 12.h, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal))
              : Icon(icon, size: 16.sp, color: AppColors.accentTeal),
          label: Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.accentTeal)),
          backgroundColor: AppColors.accentTeal.withOpacity(0.1),
          side: const BorderSide(color: AppColors.accentTeal),
        ));
  }

  Widget _buildCommentItem(Comment comment) {
    final aiController = Get.find<AIController>();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: context.theme.primaryColor.withOpacity(0.2),
            backgroundImage: comment.userAvatarUrl != null && comment.userAvatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(comment.userAvatarUrl!)
                : null,
            child: comment.userAvatarUrl == null || comment.userAvatarUrl!.isEmpty
                ? Icon(PhosphorIcons.user(), color: context.theme.primaryColor, size: 18.r)
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName ?? "مستخدم كورسيريا",
                      style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                    if (_authController.userData['role'] == 'teacher' || _authController.userData['id'] == comment.userId)
                      GestureDetector(
                        onTap: () => aiController.correctComment(comment.content),
                        child: Icon(Icons.spellcheck_rounded, color: AppColors.accentTeal.withOpacity(0.5), size: 16.sp),
                      ),
                  ],
                ),
                Text(
                  comment.content,
                  style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 12.sp),
                ),
                Text(
                  AppConstants.formatTimeAgo(comment.createdAt),
                  style: AppTextStyles.body.copyWith(color: Colors.white38, fontSize: 10.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
