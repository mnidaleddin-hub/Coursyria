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
  final AuthController _authController = Get.find<AuthController>();
  final CourseController _courseController = Get.find<CourseController>();

  var isLoading = false.obs;
  var uploadProgress = 0.0.obs;
  var selectedFile = Rxn<File>();
  var selectedCourseId = "".obs;
  
  // Stats
  var teacherStats = {
    'student_count': 0,
    'course_count': 0,
    'sales_count': 0,
    'total_earnings': 0.0,
  }.obs;

  var teacherCourses = <Course>[].obs;
  var teacherComments = <Map<String, dynamic>>[].obs;
  var isCommentsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (_authController.userData['role'] == 'teacher') {
      refreshDashboard();
    }
  }

  Future<void> refreshDashboard() async {
    final teacherId = _authController.userData['id'];
    if (teacherId == null) return;
    
    await Future.wait([
      fetchTeacherStats(teacherId),
      fetchTeacherCourses(teacherId),
    ]);
  }

  Future<void> fetchTeacherStats(String teacherId) async {
    try {
      // In a real app, you might use an RPC or multiple queries
      // For now, let's simulate with some logic or direct queries if tables allow
      final coursesResponse = await _supabase
          .from('courses')
          .select('id, price')
          .eq('teacher_id', teacherId);
      
      final courseIds = (coursesResponse as List).map((c) => c['id']).toList();
      
      int salesCount = 0;
      double totalEarnings = 0.0;
      int studentCount = 0;

      if (courseIds.isNotEmpty) {
        // This assumes a 'user_courses' or 'subscriptions' table exists
        final salesResponse = await _supabase
            .from('user_courses')
            .select('course_id')
            .inFilter('course_id', courseIds);
        
        salesCount = (salesResponse as List).length;
        
        // Calculate earnings (simplified: sum of prices for each sale)
        for (var sale in salesResponse) {
          final course = (coursesResponse as List).firstWhere((c) => c['id'] == sale['course_id']);
          totalEarnings += (course['price'] ?? 0).toDouble();
        }

        // Distinct students
        final studentsResponse = await _supabase
            .from('user_courses')
            .select('user_id')
            .inFilter('course_id', courseIds);
        
        final distinctStudents = (studentsResponse as List).map((s) => s['user_id']).toSet();
        studentCount = distinctStudents.length;
      }

      teacherStats.value = {
        'student_count': studentCount,
        'course_count': (coursesResponse as List).length,
        'sales_count': salesCount,
        'total_earnings': totalEarnings,
      };
    } catch (e) {
      debugPrint("Error fetching teacher stats: $e");
    }
  }

  Future<void> requestNewCourse(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      await _supabase.from('courses').insert({
        ...data,
        'teacher_id': _authController.userData['id'],
        'status': 'pending',
      });
      Get.back();
      Get.snackbar("نجاح", "تم إرسال طلب إنشاء الكورس للمراجعة.");
      refreshDashboard();
    } catch (e) {
      debugPrint("Error requesting new course: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase.from('courses').delete().eq('id', courseId);
      Get.snackbar("نجاح", "تم حذف الكورس بنجاح.");
      refreshDashboard();
    } catch (e) {
      debugPrint("Error deleting course: $e");
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      await _supabase.from('lessons').delete().eq('id', lessonId);
      Get.snackbar("نجاح", "تم حذف الدرس بنجاح.");
    } catch (e) {
      debugPrint("Error deleting lesson: $e");
    }
  }

  Future<void> updateLessonOrder(String courseId, List<Lesson> lessons) async {
    try {
      for (int i = 0; i < lessons.length; i++) {
        await _supabase.from('lessons').update({'order_index': i}).eq('id', lessons[i].id);
      }
      Get.snackbar("نجاح", "تم تحديث ترتيب الدروس.");
    } catch (e) {
      debugPrint("Error updating lesson order: $e");
    }
  }

  Future<void> renameLesson(String lessonId, String newTitle) async {
    try {
      await _supabase.from('lessons').update({'title': newTitle}).eq('id', lessonId);
      Get.snackbar("نجاح", "تم تغيير اسم الدرس.");
    } catch (e) {
      debugPrint("Error renaming lesson: $e");
    }
  }

  Future<void> fetchTeacherComments() async {
    isCommentsLoading.value = true;
    try {
      // Simplified: fetch comments for teacher's courses
      final teacherId = _authController.userData['id'];
      final response = await _supabase
          .from('comments')
          .select('*, lessons(title, course_id)')
          .eq('lessons.teacher_id', teacherId);
      
      teacherComments.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetching teacher comments: $e");
    } finally {
      isCommentsLoading.value = false;
    }
  }

  Future<void> replyToComment(String commentId, String replyText) async {
    try {
      // Simplified: Add a reply comment
      await _supabase.from('comments').insert({
        'content': replyText,
        'parent_id': commentId,
        'user_id': _authController.userData['id'],
      });
      Get.snackbar("نجاح", "تم إرسال الرد.");
      fetchTeacherComments();
    } catch (e) {
      debugPrint("Error replying to comment: $e");
    }
  }

  Future<void> fetchTeacherCourses(String teacherId) async {
    try {
      final response = await _supabase
          .from('courses')
          .select('*, lessons(*)')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      teacherCourses.assignAll((response as List).map((e) => Course.fromJson(e)).toList());
    } catch (e) {
      debugPrint("Error fetching teacher courses: $e");
    }
  }

  Future<void> createCourse({
    required String title,
    required String subject,
    required String gradeLevel,
    required double price,
    required String description,
    File? imageFile,
  }) async {
    try {
      isLoading.value = true;
      final userId = _authController.userData['id'];

      String? coverUrl;
      if (imageFile != null) {
        final fileName = "${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}";
        await _supabase.storage.from('course-covers').upload(fileName, imageFile);
        coverUrl = _supabase.storage.from('course-covers').getPublicUrl(fileName);
      }

      await _supabase.from('courses').insert({
        'title': title,
        'subject': subject,
        'grade_level': gradeLevel,
        'price': price,
        'description': description,
        'teacher_id': userId,
        'instructor': _authController.userData['name'] ?? "أستاذ متميز",
        'cover_url': coverUrl ?? "",
        'status': 'approved', // Auto-approved for now as per teacher request
      });

      Get.snackbar("نجاح", "تم إنشاء الكورس بنجاح", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      refreshDashboard();
      Get.back();
    } catch (e) {
      Get.snackbar("خطأ", "فشل إنشاء الكورس: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
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
      Get.snackbar("خطأ", "يرجى اختيار ملف فيديو");
      return;
    }

    try {
      isLoading.value = true;
      final file = selectedFile.value!;
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      
      await _supabase.storage.from('course-videos').upload(fileName, file);
      final videoUrl = _supabase.storage.from('course-videos').getPublicUrl(fileName);

      await _supabase.from('lessons').insert({
        'course_id': courseId,
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'teacher_id': _authController.userData['id'],
      });

      Get.snackbar("نجاح", "تم رفع الدرس بنجاح", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
      refreshDashboard();
      Get.back();
    } catch (e) {
      Get.snackbar("خطأ", "فشل رفع الدرس: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
      selectedFile.value = null;
    }
  }
}
