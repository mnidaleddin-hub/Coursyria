import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:courseria_mobile/core/constants/constants.dart';
import '../models/course_model.dart';
import 'auth_controller.dart';
import 'course_controller.dart';

class TeacherController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  var courseStats = <String, dynamic>{}.obs;

  Future<void> fetchTeacherAnalytics(String teacherId) async {
    try {
      final response = await _supabase.rpc('get_teacher_analytics', params: {'teacher_id_param': teacherId});
      courseStats.value = response ?? {};
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
    }
  }
  final AuthController _authController = Get.find<AuthController>();
  final CourseController _courseController = Get.find<CourseController>();

  var isLoading = false.obs;
  var uploadProgress = 0.0.obs;
  var selectedFile = Rxn<File>();
  var selectedCourseId = "".obs;

  // Course Request Logic
  Future<void> requestNewCourse({
    required String title,
    required String subject,
    required String gradeLevel,
    required double price,
    String? description,
    String? generalNotes,
  }) async {
    try {
      isLoading.value = true;
      final userId = _authController.userData['id'];

      await _supabase.from('courses').insert({
        'title': title,
        'subject': subject,
        'grade_level': gradeLevel,
        'price': price,
        'description': description ?? "",
        'general_notes': generalNotes,
        'teacher_id': userId,
        'instructor': _authController.userData['name'] ?? "أستاذ متميز",
        'status': 'pending', // Explicitly setting pending
        'rating': 0.0,
        'cover_url': "", // Default or teacher can upload later
      });

      Get.snackbar("تم الإرسال", "تم إرسال طلب إنشاء الكورس للإدارة",
          backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      _courseController.fetchCoursesFromApi(); // Refresh to show in pending section
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال الطلب: $e",
          backgroundColor: const Color(0xFFE63946), colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickVideo() async {
    if (kIsWeb) {
      Get.snackbar("تنبيه", "تحميل الملفات عبر المتصفح يحتاج إعدادات إضافية");
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      selectedFile.value = File(result.files.single.path!);
    }
  }

  Future<void> uploadLesson({
    required String title,
    required String description,
    required String courseId,
  }) async {
    if (selectedFile.value == null) {
      Get.snackbar("خطأ", "يرجى اختيار ملف فيديو أولاً");
      return;
    }

    try {
      isLoading.value = true;
      uploadProgress.value = 0.0;

      final file = selectedFile.value!;
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final filePath = "lessons/$fileName";

      // 1. Upload to Supabase Storage with real progress
      await _supabase.storage.from('course-videos').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      
      // Since supabase_flutter upload doesn't support progress callback yet,
      // we simulate a smooth progress after the upload starts, 
      // but in a production environment with larger files, 
      // one might use a custom tus client or similar.
      // For now, let's at least ensure the bucket is correct.

      uploadProgress.value = 1.0;

      // 2. Get Public URL (We'll use signed URLs at runtime for viewing)
      final String videoUrl = _supabase.storage.from('course-videos').getPublicUrl(filePath);

      // 3. Save to Database
      await _supabase.from('lessons').insert({
        'course_id': courseId,
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'teacher_id': _authController.userData['id'],
        'instructor_id': _authController.userData['id'],
        'is_free': false,
        'views_count': 0,
        'likes_count': 0,
      });

      Get.snackbar("نجاح", "تم رفع الدرس بنجاح", 
          backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      _courseController.fetchCoursesFromApi();
      Get.back();
    } catch (e) {
      print("Upload error: $e");
      Get.snackbar("خطأ", "فشل رفع الدرس: $e", 
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
      uploadProgress.value = 0.0;
      selectedFile.value = null;
    }
  }

  // --- Phase 4: Teacher Management ---
  Future<void> deleteCourse(String courseId) async {
    try {
      isLoading.value = true;
      // 1. Delete from database (Cascade deletes should handle progression if configured)
      await _supabase.from('courses').delete().eq('id', courseId);
      
      Get.snackbar("تم الحذف", "تم حذف الكورس بنجاح", backgroundColor: Colors.redAccent, colorText: Colors.white);
      _courseController.fetchCoursesFromApi();
      Get.back();
    } catch (e) {
      Get.snackbar("خطأ", "فشل حذف الكورس: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      isLoading.value = true;
      await _supabase.from('lessons').delete().eq('id', lessonId);
      
      Get.snackbar("تم الحذف", "تم حذف الفيديو بنجاح", backgroundColor: Colors.redAccent, colorText: Colors.white);
      _courseController.fetchCoursesFromApi();
    } catch (e) {
      Get.snackbar("خطأ", "فشل حذف الفيديو: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> renameLesson(String lessonId, String newTitle) async {
    try {
      await _supabase.from('lessons').update({'title': newTitle}).eq('id', lessonId);
      Get.snackbar("تم التحديث", "تم تغيير اسم الدرس بنجاح", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      _courseController.fetchCoursesFromApi();
    } catch (e) {
      Get.snackbar("خطأ", "فشل تحديث الاسم: $e");
    }
  }

  Future<void> updateLessonOrder(String courseId, List<Lesson> lessons) async {
    try {
      for (int i = 0; i < lessons.length; i++) {
        await _supabase.from('lessons').update({'sort_order': i}).eq('id', lessons[i].id);
      }
    } catch (e) {
      print("Error updating lesson order: $e");
    }
  }

  // --- Phase 5: Comments Management for Teachers ---
  var teacherComments = <Map<String, dynamic>>[].obs;
  var isCommentsLoading = false.obs;

  Future<void> fetchTeacherComments() async {
    try {
      isCommentsLoading.value = true;
      final userId = _authController.userData['id'];

      // Fetch comments for lessons belonging to this teacher's courses
      // We can use a join or filter by teacher_id in lessons
      final response = await _supabase
          .from('comments')
          .select('*, profiles:user_id(full_name), lessons!inner(title, teacher_id)')
          .eq('lessons.teacher_id', userId)
          .order('created_at', ascending: false);

      teacherComments.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching teacher comments: $e");
    } finally {
      isCommentsLoading.value = false;
    }
  }

  Future<void> replyToComment(String commentId, String replyText) async {
    try {
      // In a real scenario, we might have a 'replies' table or update the comment
      // For now, let's assume we update the 'reply' column in the comments table
      await _supabase.from('comments').update({
        'teacher_reply': replyText,
        'replied_at': DateTime.now().toIso8601String(),
      }).eq('id', commentId);
      
      Get.snackbar("تم الرد", "تم إرسال ردك بنجاح", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      fetchTeacherComments(); // Refresh
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال الرد: $e");
    }
  }
}
