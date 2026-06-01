import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../models/course_model.dart';
import '../controllers/course_controller.dart';
import '../controllers/lesson_controller.dart';
import '../core/constants/constants.dart';
import '../core/utils/offline_video_manager.dart';
import 'dart:io';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../services/ai_service.dart';
import 'quiz_play_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Lesson lesson;
  final String videoUrl;

  const VideoPlayerScreen(
      {super.key, required this.lesson, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with TickerProviderStateMixin {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final CourseController _courseController = Get.find<CourseController>();
  final LessonController _lessonController = Get.find<LessonController>();
  final AuthController _authController = Get.find<AuthController>();
  final OfflineVideoManager _offlineManager = OfflineVideoManager();
  final TextEditingController _commentController = TextEditingController();
  bool _isInitializing = true;
  late TabController _tabController;
  final FocusNode _noteFocus = FocusNode();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. Anti-Screen Recording & Screenshot Security
    if (!kIsWeb && Platform.isAndroid) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
    _initializeFlow();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initial data for YouTube features
    _lessonController.currentLessonLikes.value = widget.lesson.likesCount ?? 0;
    _lessonController.fetchComments(widget.lesson.id);
    _lessonController.checkIfLiked(widget.lesson.id);
    _lessonController.incrementViews(widget.lesson.id);
    _lessonController.checkDownloadStatus(widget.lesson.id);
    _lessonController.fetchLessonNotes(widget.lesson.id);
    _lessonController.fetchLessonChapters(widget.lesson.id);
  }

  Future<void> _initializeFlow() async {
    setState(() => _isInitializing = true);
    
    String finalUrl = widget.videoUrl;
    bool isOffline = await _offlineManager.isVideoDownloaded(widget.lesson.id);

    if (isOffline) {
      final offlineFile = await _offlineManager.getDecryptedVideo(widget.lesson.id);
      if (offlineFile != null) {
        _initializePlayer(file: offlineFile);
        return;
      }
    }

    // If not offline or decryption failed, get signed URL
    finalUrl = await _lessonController.getSecureUrl(widget.videoUrl);
    _initializePlayer(url: finalUrl);
  }

  Future<void> _initializePlayer({String? url, File? file}) async {
    // Dispose previous if any
    await _videoPlayerController?.dispose();
    _chewieController?.dispose();

    if (file != null) {
      _videoPlayerController = VideoPlayerController.file(file);
    } else {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url!));
    }

    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      playbackSpeeds: [0.5, 1.0, 1.25, 1.5, 2.0],
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.accentTeal,
        handleColor: AppColors.accentTeal,
        backgroundColor: Colors.grey.withOpacity(0.5),
        bufferedColor: Colors.white.withOpacity(0.3),
      ),
      placeholder: Container(color: Colors.black),
      errorBuilder: (context, errorMessage) {
        return const Center(
            child: Text("خطأ في تشغيل الفيديو",
                style: TextStyle(color: Colors.white)));
      },
    );

    // Sync Playback Progress
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.position.inSeconds % 10 == 0) {
        _courseController.savePlaybackProgress(
            widget.lesson.id, _videoPlayerController!.value.position.inSeconds);
      }
    });

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    // 1. Clear Security Flags
    if (!kIsWeb && Platform.isAndroid) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _commentController.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    _tabController.dispose();
    
    // Clean up temporary decrypted files
    _offlineManager.cleanupDecryptedCache();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<LessonAsset> availableAssets = [
      ...widget.lesson.worksheets,
      ...widget.lesson.solvedTests,
      ...widget.lesson.unsolvedTests,
      ...widget.lesson.examReviews,
    ];

    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: MediaQuery.of(context).orientation == Orientation.landscape
          ? null
          : AppBar(
              title: Text(widget.lesson.title,
                  style: TextStyle(fontSize: 16.sp, color: Colors.white)),
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => _showQualitySelector(context),
                ),
                if (availableAssets.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.attachment_rounded, color: Colors.white),
                    onPressed: () => _showAssetsBottomSheet(context, availableAssets),
                  ),
              ],
            ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildPlayerWithGestures();
          }

          return Column(
            children: [
              // 1. Video Player Section
              _buildPlayerWithGestures(),

              // 2. Interactive Info Section (Premium Overhaul)
              Expanded(
                child: Column(
                  children: [
                    _buildInteractiveTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildChaptersTab(),
                          _buildNotesTab(),
                          _buildDiscussionTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerWithGestures() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Center(
            child: !_isInitializing &&
                    _chewieController != null &&
                    _chewieController!
                        .videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(color: AppColors.accentTeal),
          ),
          // Gesture Overlays
          if (!_isInitializing)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => _seekRelative(-10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => _seekRelative(10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _seekRelative(int seconds) {
    if (_videoPlayerController == null) return;
    final newPos = _videoPlayerController!.value.position +
        Duration(seconds: seconds);
    _videoPlayerController!.seekTo(newPos);
    _authController.triggerHaptic(AppHapticFeedback.light);
  }

  Widget _buildInteractiveTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accentTeal,
        labelColor: AppColors.accentTeal,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(text: "الفصول"),
          Tab(text: "ملاحظاتي"),
          Tab(text: "المناقشة"),
        ],
      ),
    );
  }

  Widget _buildChaptersTab() {
    return Obx(() {
      if (_lessonController.lessonChapters.isEmpty) {
        return _buildEmptyState(Icons.list_alt_rounded, "لا توجد فصول لهذا الدرس");
      }
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _lessonController.lessonChapters.length,
        itemBuilder: (context, index) {
          final chapter = _lessonController.lessonChapters[index];
          final timestamp = chapter['timestamp'] as int;
          return _buildChapterTile(chapter['title'], timestamp);
        },
      );
    });
  }

  Widget _buildChapterTile(String title, int seconds) {
    return ListTile(
      onTap: () {
        _videoPlayerController?.seekTo(Duration(seconds: seconds));
        _authController.triggerHaptic(AppHapticFeedback.light);
      },
      leading: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.accentTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          _formatDuration(Duration(seconds: seconds)),
          style: TextStyle(color: AppColors.accentTeal, fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
      trailing: const Icon(Icons.play_circle_outline, color: Colors.white24),
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  focusNode: _noteFocus,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "اكتب ملاحظة ذكية...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: AppColors.secondaryNavy,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              IconButton.filled(
                onPressed: _saveNote,
                icon: const Icon(Icons.add_task_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.accentTeal),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_lessonController.lessonNotes.isEmpty) {
              return _buildEmptyState(Icons.note_alt_outlined, "لم تسجل أي ملاحظات بعد");
            }
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _lessonController.lessonNotes.length,
              itemBuilder: (context, index) {
                final note = _lessonController.lessonNotes[index];
                return _buildNoteCard(note);
              },
            );
          }),
        ),
      ],
    );
  }

  void _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;
    final currentPos = _videoPlayerController?.value.position.inSeconds ?? 0;
    await _lessonController.addLessonNote(widget.lesson.id, _noteController.text, currentPos);
    _noteController.clear();
    _noteFocus.unfocus();
    _authController.triggerHaptic(AppHapticFeedback.success);
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final timestamp = note['timestamp'] as int;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _videoPlayerController?.seekTo(Duration(seconds: timestamp)),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(color: AppColors.accentTeal, borderRadius: BorderRadius.circular(4.r)),
                  child: Text(_formatDuration(Duration(seconds: timestamp)), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_vert, color: Colors.white24, size: 16),
            ],
          ),
          SizedBox(height: 8.h),
          Text(note['content'], style: TextStyle(color: Colors.white, fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _buildDiscussionTab() {
    return Column(
      children: [
        // Discussion Filters could go here
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildLessonInfoSection(),
                const Divider(color: Colors.white10),
                _buildCommentsList(),
              ],
            ),
          ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildLessonInfoSection() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.lesson.title, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text("${widget.lesson.viewsCount ?? 0} مشاهدة • ${widget.lesson.description ?? ""}", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
          SizedBox(height: 16.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  activeIcon: Icons.thumb_up_alt,
                  label: "إعجاب",
                  obsValue: _lessonController.currentLessonLikes,
                  obsActive: _lessonController.isLiked,
                  onTap: () => _lessonController.toggleLike(widget.lesson.id),
                ),
                SizedBox(width: 8.w),
                _buildQuizButton(),
                SizedBox(width: 8.w),
                _buildSummaryButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: const BoxDecoration(color: AppColors.secondaryNavy, border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "اسأل شيئاً...", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
            ),
          ),
          IconButton(
            onPressed: () {
              _lessonController.addComment(widget.lesson.id, _commentController.text);
              _commentController.clear();
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(Icons.send_rounded, color: AppColors.accentTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return Obx(() => ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: _lessonController.comments.length,
      itemBuilder: (context, index) {
        final comment = _lessonController.comments[index];
        return _buildCommentTile(comment);
      },
    ));
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16.r, backgroundColor: Colors.grey[800], child: Text((comment['profiles']?['full_name'] ?? "?")[0], style: const TextStyle(color: Colors.white))),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment['profiles']?['full_name'] ?? "طالب", style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
                SizedBox(height: 4.h),
                Text(comment['content'], style: TextStyle(color: Colors.white, fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48.sp, color: Colors.white10),
          SizedBox(height: 12.h),
          Text(message, style: TextStyle(color: Colors.white24, fontSize: 14.sp)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildCommentDeleteButton(Map<String, dynamic> comment) {
    final currentUserId = Get.find<AuthController>().userData['id'];
    final bool isOwner = comment['user_id'] == currentUserId;
    final bool isTeacher = Get.find<AuthController>().isTeacher;
    // For teacher, they can delete if it's their course. Assuming lesson.teacherId exists.
    final bool canDelete = isOwner || (isTeacher && widget.lesson.teacherId == currentUserId);

    if (!canDelete) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
      onPressed: () {
        Get.defaultDialog(
          title: "حذف التعليق",
          middleText: "هل أنت متأكد من حذف هذا التعليق؟",
          backgroundColor: AppColors.secondaryNavy,
          titleStyle: const TextStyle(color: Colors.white),
          middleTextStyle: const TextStyle(color: Colors.white70),
          textConfirm: "حذف",
          textCancel: "إلغاء",
          confirmTextColor: Colors.white,
          onConfirm: () {
            _lessonController.deleteComment(comment['id'].toString(), widget.lesson.id);
            Get.back();
          },
        );
      },
    );
  }

  Widget _buildSummaryButton() {
    return InkWell(
      onTap: () => generateAndSaveSummary(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.accentTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentTeal, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accentTeal, size: 20.sp),
            SizedBox(width: 5.w),
            Text(
              "لخص ذكياً",
              style: TextStyle(
                  color: AppColors.accentTeal,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _displaySummaryBottomSheet(String summary, {required bool isCached}) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: const BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isCached ? "ملخص الدرس (محفوظ أوفلاين) 💾" : "ملخص الدرس الذكي ✨", 
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.white54)),
              ],
            ),
            SizedBox(height: 20.h),
            Flexible(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: summary,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.6),
                    listBullet: const TextStyle(color: AppColors.accentTeal),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            if (!isCached)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final storage = GetStorage();
                    storage.write("lesson_summary_${widget.lesson.id}", summary);
                    Get.back();
                    Get.snackbar("تم الحفظ", "تم حفظ الملخص للوصول إليه أوفلاين 💾", 
                        backgroundColor: AppColors.accentTeal, colorText: Colors.white);
                  },
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text("حفظ للمراجعة أوفلاين"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryNavy),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> generateAndSaveSummary() async {
    final storage = GetStorage();
    final String storageKey = "lesson_summary_${widget.lesson.id}";
    String? cachedSummary = storage.read(storageKey);

    if (cachedSummary != null) {
      _displaySummaryBottomSheet(cachedSummary, isCached: true);
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.accentTeal)),
      barrierDismissible: false,
    );
    
    try {
      final aiService = AIService();
      final summary = await aiService.summarizeLesson(widget.lesson.title, widget.lesson.description ?? "");
      Get.back(); // Close loading
      _displaySummaryBottomSheet(summary, isCached: false);
    } catch (e) {
      Get.back();
      Get.snackbar("خطأ", "فشل توليد الملخص الذكي", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Widget _buildQuizButton() {
    return InkWell(
      onTap: () {
        final quizController = Get.put(QuizController());
        quizController.startQuiz(
          type: 'lesson',
          topicName: widget.lesson.title,
          cId: null, // We might want to pass courseId here if available
          lId: widget.lesson.id,
        );
        Get.to(() => QuizPlayScreen());
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.quiz_rounded, color: Colors.amber, size: 20.sp),
            SizedBox(width: 5.w),
            Text(
              "اختبار (AI)",
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return InkWell(
      onTap: () => _lessonController.markLessonAsCompleted(widget.lesson, "كورس متميز"), // Replace with actual course title if available
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.accentTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentTeal, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.accentTeal, size: 20.sp),
            SizedBox(width: 5.w),
            Text(
              "اكتمل الدرس",
              style: TextStyle(color: AppColors.accentTeal, fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_lessonController.isDownloading.value) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 15, height: 15,
              child: CircularProgressIndicator(
                value: _lessonController.downloadProgress.value,
                strokeWidth: 2,
                color: AppColors.accentTeal,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              "${(_lessonController.downloadProgress.value * 100).toInt()}%",
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _lessonController.isDownloaded.value 
          ? null // Already downloaded
          : _lessonController.downloadLesson(widget.lesson, widget.videoUrl),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              _lessonController.isDownloaded.value ? Icons.check_circle : Icons.download_for_offline_outlined,
              color: _lessonController.isDownloaded.value ? AppColors.accentTeal : Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 5.w),
            Text(
              _lessonController.isDownloaded.value ? "محمل" : "تحميل",
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required RxInt obsValue,
    required RxBool obsActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Obx(() => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              obsActive.value ? activeIcon : icon,
              color: obsActive.value ? AppColors.accentTeal : Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 5.w),
            Text(
              "${obsValue.value}",
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildSimpleActionButton(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20.sp),
          SizedBox(width: 5.w),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 13.sp)),
        ],
      ),
    );
  }

  void _showQualitySelector(BuildContext context) {
    final qualities = ["تلقائي", "1080p", "720p", "480p", "360p"];
    
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: const BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 20.h),
            Text("جودة العرض", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10.h),
            ...qualities.map((q) => ListTile(
              leading: const Icon(Icons.high_quality_outlined, color: AppColors.accentTeal),
              title: Text(q, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              onTap: () {
                Get.back();
                Get.snackbar("جودة الفيديو", "تم تغيير الجودة إلى $q", 
                    snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.accentTeal, colorText: Colors.white);
                // Future implementation: Logic to switch between URLs/bitrates
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showAssetsBottomSheet(
      BuildContext context, List<LessonAsset> assets) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: const BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 20.h),
            Text(
              "مرفقات الدرس",
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 10.h),
            ListView.builder(
              shrinkWrap: true,
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return ListTile(
                  leading: _getAssetIcon(asset.assetType),
                  title: Text(asset.title, style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppColors.accentTeal),
                    onPressed: () {
                      // Assuming downloadAsset exists in CourseController
                      Get.back();
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Icon _getAssetIcon(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.redAccent);
      case 'zip':
        return const Icon(Icons.archive, color: Colors.grey);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blueAccent);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.white54);
    }
  }
}
