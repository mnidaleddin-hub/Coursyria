import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_controller.dart';
import '../models/course_model.dart';
import '../core/constants/constants.dart';
import '../core/utils/offline_video_manager.dart';
import 'package:logger/logger.dart';
import 'system_controller.dart';

class LessonController extends GetxController {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final Logger _logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;
  final OfflineVideoManager _offlineManager = OfflineVideoManager();

  var lessons = <Lesson>[].obs;
  var isLoading = false.obs;
  var isSubscribed = false.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;

  // --- Offline & Signed URLs ---
  var isDownloaded = false.obs;
  var downloadProgress = 0.0.obs;
  var isDownloading = false.obs;
  var downloadStatuses = <String, DownloadStatus>{}.obs;
  var downloadProgresses = <String, double>{}.obs;
  var usedStorageMB = 0.0.obs;

  Future<void> updateUsedStorage() async {
    usedStorageMB.value = await _offlineManager.getUsedStorageMB();
  }

  Future<void> deleteDownload(String lessonId) async {
    await _offlineManager.deleteVideo(lessonId);
    downloadStatuses.remove(lessonId);
    downloadProgresses.remove(lessonId);
    await updateUsedStorage();
  }

  Future<String> getSecureUrl(String originalUrl) async {
    try {
      // If it's already a signed URL or local path, return as is
      if (originalUrl.contains('token=') || originalUrl.startsWith('/')) return originalUrl;

      // Extract path from public URL
      // Example: https://.../storage/v1/object/public/course-videos/lessons/vid.mp4
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('course-videos');
      
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        
        // Generate Signed URL valid for 1 hour
        final signedUrl = await _supabase.storage
            .from('course-videos')
            .createSignedUrl(filePath, 3600);
            
        return signedUrl;
      }
      return originalUrl;
    } catch (e) {
      _logger.e("Error generating signed URL: $e");
      return originalUrl;
    }
  }

  Future<void> checkDownloadStatus(String lessonId) async {
    final downloaded = await _offlineManager.isVideoDownloaded(lessonId);
    if (downloaded) {
      downloadStatuses[lessonId] = DownloadStatus.completed;
      downloadProgresses[lessonId] = 1.0;
    }
  }

  Future<void> downloadLesson(Lesson lesson, String videoUrl) async {
    try {
      downloadStatuses[lesson.id] = DownloadStatus.downloading;
      downloadProgresses[lesson.id] = 0.0;
      
      final secureUrl = await getSecureUrl(videoUrl);
      await _offlineManager.downloadVideo(
        url: secureUrl,
        lessonId: lesson.id,
        title: lesson.title,
        onUpdate: (p, status) {
          downloadProgresses[lesson.id] = p;
          downloadStatuses[lesson.id] = status;
          
          // Legacy support for single-video UI
          downloadProgress.value = p;
          isDownloading.value = status == DownloadStatus.downloading;
          if (status == DownloadStatus.completed) isDownloaded.value = true;
        },
      );
      
      Get.snackbar("تم التحميل", "الدرس متاح الآن للمشاهدة أوفلاين", 
          backgroundColor: AppColors.accentTeal, colorText: Colors.white);
    } catch (e) {
      _logger.e("Download error: $e");
      downloadStatuses[lesson.id] = DownloadStatus.failed;
      Get.snackbar("خطأ", "فشل تحميل الدرس");
    }
  }

  /// Fetch lessons for a specific course
  /// [courseId] must be a valid UUID string
  Future<void> fetchLessons(String courseId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      // 1. UUID Validation using Helper from SystemController
      final systemController = Get.find<SystemController>();
      if (!systemController.isValidUuid(courseId)) {
        _logger.e("Invalid UUID format for course_id: $courseId");
        
        // Proactive Fix: If in Offline Mode or Dev, we allow mock data even with bad UUID
        if (systemController.isOfflineMode.value) {
          await Future.delayed(const Duration(milliseconds: 800));
          lessons.assignAll([
            Lesson(id: "l1", title: "مقدمة في الجبر", isFree: true, duration: "15:00"),
            Lesson(id: "l2", title: "المعادلات من الدرجة الثانية", isFree: false, duration: "25:00"),
            Lesson(id: "l3", title: "المتراجحات والقيمة المطلقة", isFree: false, duration: "20:00"),
          ]);
          isSubscribed.value = true;
          return;
        }
        
        throw "تنسيق معرف الكورس غير صالح (UUID required)";
      }

      _logger.d("Fetching lessons for course_id: $courseId");

      // 1. Fetch lessons from API as requested
      // Format: https://coursyria-api.onrender.com/courses/{course_id}/lessons
      final response =
          await _dio.get('/courses/$courseId/lessons');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        lessons.assignAll(data.map((json) => Lesson.fromJson(json)).toList());
        _logger.d("Fetched ${lessons.length} lessons from Supabase via API");
      } else {
        throw "فشل في جلب الدروس: ${response.statusCode}";
      }

      // 2. Check enrollment status for Access Control
      await checkEnrollmentStatus(courseId);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "حدث خطأ أثناء تحميل الدروس";
      _logger.e("Error in fetchLessons: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify if the current user is enrolled in the course
  Future<void> checkEnrollmentStatus(String courseId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        isSubscribed.value = false;
        return;
      }

      // Check 'enrollments' table first as per instructions
      final enrollment = await _supabase
          .from('enrollments')
          .select()
          .eq('user_id', user.id)
          .eq('course_id', courseId)
          .maybeSingle();

      if (enrollment != null) {
        isSubscribed.value = true;
        _logger.d("User is enrolled via 'enrollments' table");
        return;
      }

      // Fallback to 'transactions' table
      final transaction = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .eq('course_id', courseId)
          .eq('status', 'completed')
          .maybeSingle();

  isSubscribed.value = transaction != null;
      if (isSubscribed.value) {
        _logger.d("User is enrolled via 'transactions' table");
      }
    } catch (e) {
      _logger.e("Error checking enrollment: $e");
      isSubscribed.value = false;
    }
  }

  // --- YouTube Features Logic ---
  var currentLessonLikes = 0.obs;
  var isLiked = false.obs;
  var comments = <Map<String, dynamic>>[].obs;
  var lessonNotes = <Map<String, dynamic>>[].obs;
  var lessonChapters = <Map<String, dynamic>>[].obs;

  Future<void> fetchLessonNotes(String lessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(milliseconds: 300));
        lessonNotes.assignAll([
          {'id': 'n1', 'content': 'ملاحظة مهمة جداً عن الجبر', 'timestamp': 45},
          {'id': 'n2', 'content': 'قاعدة المثلث الذهبي', 'timestamp': 120},
        ]);
        return;
      }
      
      if (user == null) return;
      final response = await _supabase
          .from('lesson_notes')
          .select()
          .eq('lesson_id', lessonId)
          .eq('user_id', user.id)
          .order('timestamp', ascending: true);
      lessonNotes.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      // If table doesn't exist, we skip
      debugPrint("Note: lesson_notes table might be missing: $e");
    }
  }

  Future<void> addLessonNote(String lessonId, String content, int timestamp) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('lesson_notes').insert({
        'lesson_id': lessonId,
        'user_id': user.id,
        'content': content,
        'timestamp': timestamp,
      });
      fetchLessonNotes(lessonId);
      Get.snackbar("تم الحفظ", "تم إضافة ملاحظتك الذكية بنجاح", 
          backgroundColor: AppColors.accentTeal, colorText: Colors.white);
    } catch (e) {
      _logger.e("Error adding note: $e");
      Get.snackbar("خطأ", "فشل في حفظ الملاحظة. تأكد من وجود جدول lesson_notes");
    }
  }

  Future<void> fetchLessonChapters(String lessonId) async {
    try {
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(milliseconds: 300));
        lessonChapters.assignAll([
          {'id': 'c1', 'title': 'البداية والترحيب', 'timestamp': 0},
          {'id': 'c2', 'title': 'شرح المفهوم الأساسي', 'timestamp': 180},
          {'id': 'c3', 'title': 'أمثلة عملية', 'timestamp': 450},
          {'id': 'c4', 'title': 'ملخص الدرس', 'timestamp': 800},
        ]);
        return;
      }

      final response = await _supabase
          .from('lesson_chapters')
          .select()
          .eq('lesson_id', lessonId)
          .order('timestamp', ascending: true);
      lessonChapters.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _logger.e("Error fetching chapters: $e");
    }
  }

  Future<void> incrementViews(String lessonId) async {
    try {
      await _supabase.rpc('increment_lesson_views', params: {'lesson_id_param': lessonId});
    } catch (e) {
      _logger.e("Error incrementing views: $e");
    }
  }

  Future<void> fetchComments(String lessonId) async {
    try {
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(milliseconds: 300));
        comments.assignAll([
          {'id': 'co1', 'content': 'درس رائع جداً، شكراً لك أستاذ!', 'profiles': {'full_name': 'أحمد السوري'}},
          {'id': 'co2', 'content': 'هل يمكن شرح النقطة الثانية مرة أخرى؟', 'profiles': {'full_name': 'سارة المحمد'}},
        ]);
        return;
      }

      final response = await _supabase
          .from('comments')
          .select('*, profiles:user_id(full_name)')
          .eq('lesson_id', lessonId)
          .order('created_at', ascending: false);
      comments.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _logger.e("Error fetching comments: $e");
    }
  }

  Future<void> checkIfLiked(String lessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        isLiked.value = false;
        return;
      }

      final existingLike = await _supabase
          .from('lesson_likes')
          .select()
          .eq('user_id', user.id)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      isLiked.value = existingLike != null;
    } catch (e) {
      _logger.e("Error checking if liked: $e");
      isLiked.value = false;
    }
  }

  Future<void> addComment(String lessonId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('comments').insert({
        'lesson_id': lessonId,
        'user_id': user.id,
        'content': text,
      });
      fetchComments(lessonId); // Refresh
    } catch (e) {
      _logger.e("Error adding comment: $e");
      Get.snackbar("خطأ", "فشل في إضافة التعليق");
    }
  }

  Future<void> toggleLike(String lessonId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if already liked (assuming a lesson_likes table)
      final existingLike = await _supabase
          .from('lesson_likes')
          .select()
          .eq('user_id', user.id)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('lesson_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('lesson_id', lessonId);
        isLiked.value = false;
        currentLessonLikes.value--;
      } else {
        // Like
        await _supabase.from('lesson_likes').insert({
          'user_id': user.id,
          'lesson_id': lessonId,
        });
        isLiked.value = true;
        currentLessonLikes.value++;
      }
    } catch (e) {
      _logger.e("Error toggling like: $e");
    }
  }

  // --- Phase 2: Progress & Parental Notification ---
  Future<void> markLessonAsCompleted(Lesson lesson, String courseTitle) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Update progress in student_progress table
      await _supabase.from('student_progress').upsert({
        'user_id': user.id,
        'lesson_id': lesson.id,
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      });

      Get.snackbar("رائع!", "تم إكمال الدرس بنجاح ✅", 
          backgroundColor: AppColors.accentTeal, colorText: Colors.white);

      // Phase 2: Add Points
      final authController = Get.find<AuthController>();
      await authController.addPoints(50); // 50 points per lesson

      // 2. Fetch parent phone if available
      final userData = await _supabase.from('user_profiles').select('full_name, parent_phone').eq('id', user.id).single();
      final String? parentPhone = userData['parent_phone'];
      final String studentName = userData['full_name'] ?? "الطالب";

      if (parentPhone != null && parentPhone.isNotEmpty) {
        await _sendParentNotification(studentName, lesson.title, courseTitle, parentPhone);
      }
    } catch (e) {
      _logger.e("Error marking lesson as completed: $e");
    }
  }

  Future<void> _sendParentNotification(String studentName, String lessonTitle, String courseTitle, String parentPhone) async {
    try {
      // Sanitize phone number for Green-API
      String cleanPhone = parentPhone.replaceAll('+', '').replaceAll(' ', '').trim();
      if (cleanPhone.startsWith('0')) cleanPhone = cleanPhone.substring(1);
      if (!cleanPhone.startsWith('963')) cleanPhone = "963$cleanPhone";
      
      final String message = "مرحباً يا فندم، يسعدنا إعلامكم أن ابنكم البطل $studentName قد أنجز بنجاح درس: $lessonTitle في كورس $courseTitle عبر منصة كورسيريا! 🚀";
      
      final url = Uri.parse("${AppConstants.waApiUrl}/waInstance${AppConstants.waIdInstance}/sendMessage/${AppConstants.waTokenInstance}");

      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chatId": "$cleanPhone@c.us",
          "message": message
        }),
      );
      _logger.d("WhatsApp notification sent to parent: $parentPhone");
    } catch (e) {
      _logger.e("Error sending WhatsApp notification: $e");
    }
  }

  // --- Phase 3: Comment Management ---
  Future<void> deleteComment(String commentId, String lessonId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);
      fetchComments(lessonId); // Refresh list
      Get.snackbar("تم الحذف", "تم حذف التعليق بنجاح", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      _logger.e("Error deleting comment: $e");
      Get.snackbar("خطأ", "فشل حذف التعليق");
    }
  }
}
