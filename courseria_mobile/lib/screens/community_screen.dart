import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  final Rx<File?> _selectedPostAudio = Rx<File?>(null);
  final Rx<File?> _selectedPostPdf = Rx<File?>(null);
  final RxList<String> _selectedTags = <String>[].obs;

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
    _selectedPostAudio.value = null;
    _selectedPostPdf.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndSort(),
        _buildPostInput(),
        Expanded(
          child: Obx(() {
            return Skeletonizer(
              enabled: _communityController.isLoadingPosts.value,
              child: _communityController.filteredPosts.isEmpty && !_communityController.isLoadingPosts.value
                  ? Center(
                      child: Text("لا توجد منشورات حالياً.",
                          style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                    )
                  : RefreshIndicator(
                      onRefresh: _communityController.fetchPosts,
                      color: context.theme.primaryColor,
                      child: ListView.builder(
                        padding: EdgeInsets.all(20.r),
                        itemCount: _communityController.isLoadingPosts.value ? 2 : _communityController.filteredPosts.length,
                        itemBuilder: (context, index) {
                          if (_communityController.isLoadingPosts.value) {
                            return _buildFakePostCard();
                          }
                          final post = _communityController.filteredPosts[index];
                          return _buildPostCard(post);
                        },
                      ),
                    ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: TextField(
                onChanged: _communityController.search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(PhosphorIcons.magnifyingGlass(), color: Colors.white38, size: 20.r),
                  hintText: "بحث في المنشورات...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Obx(() => PopupMenuButton<String>(
                icon: Icon(PhosphorIcons.sortAscending(), color: context.theme.primaryColor),
                color: AppColors.secondaryNavy,
                onSelected: _communityController.setSort,
                itemBuilder: (context) => [
                  _buildSortItem('newest', 'الأحدث'),
                  _buildSortItem('popular', 'الأكثر تفاعلاً'),
                  _buildSortItem('solved', 'المحلولة'),
                  _buildSortItem('unsolved', 'غير المحلولة'),
                ],
              )),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(label, style: TextStyle(
        color: _communityController.currentSort.value == value ? context.theme.primaryColor : Colors.white
      )),
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
                    backgroundImage: !_communityController.isAnonymous.value && 
                            _authController.userProfile.value?.avatarUrl != null &&
                            _authController.userProfile.value!.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(_authController.userProfile.value!.avatarUrl!)
                        : null,
                    child: _communityController.isAnonymous.value || 
                            _authController.userProfile.value?.avatarUrl == null ||
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
                        hintText: _communityController.isAnonymous.value 
                            ? "انشر سؤالك بهوية مجهولة..." 
                            : "بماذا تفكر؟ شارك زملائك...",
                        hintStyle: AppTextStyles.body.copyWith(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      minLines: 1,
                    ),
                  ),
                ],
              ),
              if (_selectedPostImage.value != null || _selectedPostAudio.value != null || _selectedPostPdf.value != null)
                Padding(
                  padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
                  child: Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: [
                      if (_selectedPostImage.value != null)
                        _buildFilePreview(_selectedPostImage.value!, 'image', () => _selectedPostImage.value = null),
                      if (_selectedPostAudio.value != null)
                        _buildFilePreview(_selectedPostAudio.value!, 'audio', () => _selectedPostAudio.value = null),
                      if (_selectedPostPdf.value != null)
                        _buildFilePreview(_selectedPostPdf.value!, 'pdf', () => _selectedPostPdf.value = null),
                    ],
                  ),
                ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildInputIconButton(PhosphorIcons.image(), _pickImage),
                      _buildInputIconButton(PhosphorIcons.microphone(), _pickAudio),
                      _buildInputIconButton(PhosphorIcons.filePdf(), _pickPdf),
                      SizedBox(width: 5.w),
                      FilterChip(
                        label: Text("مجهول", style: TextStyle(fontSize: 10.sp, color: _communityController.isAnonymous.value ? Colors.white : Colors.white54)),
                        selected: _communityController.isAnonymous.value,
                        onSelected: (val) => _communityController.isAnonymous.value = val,
                        selectedColor: context.theme.primaryColor,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _communityController.isLoadingPosts.value || (_postContentController.text.isEmpty && _selectedPostImage.value == null && _selectedPostAudio.value == null && _selectedPostPdf.value == null)
                        ? null
                        : _createPost,
                    icon: Icon(PhosphorIcons.paperPlaneTilt(), color: Colors.white, size: 16.r),
                    label: Text("نشر", style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 12.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildInputIconButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: context.theme.primaryColor, size: 22.r),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildFilePreview(File file, String type, VoidCallback onRemove) {
    IconData icon = PhosphorIcons.file();
    String name = file.path.split('/').last;
    if (type == 'audio') icon = PhosphorIcons.microphone();
    if (type == 'pdf') icon = PhosphorIcons.filePdf();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: context.theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.theme.primaryColor, size: 16.r),
          SizedBox(width: 5.w),
          Text(name.length > 10 ? "...${name.substring(name.length - 10)}" : name, 
            style: TextStyle(color: Colors.white, fontSize: 10.sp)),
          SizedBox(width: 5.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: Colors.white54, size: 14.r),
          ),
        ],
      ),
    );
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
                  Row(
                    children: [
                      Text(post.userName ?? "مستخدم كورسيريا", style: AppTextStyles.header.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      if (post.isPinned)
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: Icon(PhosphorIcons.pushPin(PhosphorIconsStyle.fill), color: Colors.amber, size: 14.sp),
                        ),
                      if (post.isSolved)
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14.sp),
                        ),
                    ],
                  ),
                  Text(AppConstants.formatTimeAgo(post.createdAt), style: AppTextStyles.body.copyWith(color: Colors.white38, fontSize: 10.sp)),
                ],
              ),
              const Spacer(),
              _buildPostOptions(post),
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

  Widget _buildPostOptions(Post post) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: Colors.white38, size: 20.sp),
      color: AppColors.secondaryNavy,
      itemBuilder: (context) => [
        if (_authController.isTeacher)
          PopupMenuItem(
            value: 'pin',
            child: Row(
              children: [
                Icon(post.isPinned ? PhosphorIcons.pushPin(PhosphorIconsStyle.fill) : PhosphorIcons.pushPin(), color: Colors.amber, size: 18.sp),
                SizedBox(width: 10.w),
                Text(post.isPinned ? "إلغاء التثبيت" : "تثبيت المنشور", style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        if (_authController.userData['id'] == post.userId)
          PopupMenuItem(
            value: 'solved',
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18.sp),
                SizedBox(width: 10.w),
                Text(post.isSolved ? "إلغاء الحل" : "تم الحل", style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 18.sp),
              SizedBox(width: 10.w),
              const Text("إبلاغ", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'pin') {
          _communityController.pinPost(post.id, post.isPinned);
        } else if (val == 'solved') {
          _communityController.toggleSolved(post.id, post.isSolved);
        } else if (val == 'report') {
          _showReportDialog(post.id, 'post');
        }
      },
    );
  }

  void _showReportDialog(String id, String type) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        title: Text("إبلاغ عن $type", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "سبب الإبلاغ...",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              _communityController.reportContent(type, id, reasonController.text);
              Get.back();
            },
            child: const Text("إرسال"),
          ),
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

  Future<void> _pickAudio() async {
    // Using file_picker for audio
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _selectedPostAudio.value = File(result.files.single.path!);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      _selectedPostPdf.value = File(result.files.single.path!);
    }
  }

  Future<void> _createPost() async {
    await _communityController.createPost(
      _postContentController.text,
      image: _selectedPostImage.value,
      audio: _selectedPostAudio.value,
      pdf: _selectedPostPdf.value,
      tags: _selectedTags.toList(),
    );
    _postContentController.clear();
    _selectedPostImage.value = null;
    _selectedPostAudio.value = null;
    _selectedPostPdf.value = null;
    _selectedTags.clear();
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
