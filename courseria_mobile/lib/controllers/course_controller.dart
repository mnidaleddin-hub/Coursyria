import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import '../models/course_model.dart';
import '../core/constants/constants.dart';
import '../screens/video_player_screen.dart';
import '../services/course_service.dart';
import 'wallet_controller.dart';
import 'auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/certificate_service.dart';

class CourseController extends GetxController {
  final WalletController _walletController = Get.find<WalletController>();
  final CourseService _courseService = CourseService();
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final Logger _logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;

  var allCourses = <Course>[].obs;
  var myCourses = <Course>[].obs;
  var filteredCourses = <Course>[].obs;
  var selectedSubject = "الكل".obs;
  var searchQuery = ''.obs; // New reactive variable for search query
  TextEditingController searchController =
      TextEditingController(); // New text editing controller
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;

  final List<String> subjects = [
    "الكل",
    "رياضيات",
    "فيزياء",
    "كيمياء",
    "إنجليزي",
    "فرنسي",
  ];

  @override
  void onInit() {
    super.onInit();
    // 1. Sync Token for protected routes
    _syncAuthToken();

    // 2. Setup interceptors for logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d("Dio Request: ${options.method} ${options.uri}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
              "Dio Response: ${response.statusCode} ${response.requestOptions.uri}");
          _logger.d("Response Data: ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          _logger.e(
              "Dio Error: ${e.requestOptions.method} ${e.requestOptions.uri}");
          _logger.e("Error Type: ${e.type}");
          _logger.e("Error Message: ${e.message}");
          if (e.response != null) {
            _logger.e("Error Response Data: ${e.response?.data}");
            _logger.e("Error Response Status: ${e.response?.statusCode}");
          }
          return handler.next(e);
        },
      ),
    );
    fetchCoursesFromApi();

    // Listen to search text changes
    ever(searchQuery, (_) => applyFilters());
    fetchMyCourses();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _syncAuthToken() {
    final authController = Get.find<AuthController>();
    _dio.options.headers['Authorization'] =
        'Bearer ${authController.token.value}';
  }

  var favoriteCourses = <Course>[].obs;

  Future<void> fetchFavorites() async {
    try {
      final response = await _dio.get('/courses/favorites');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        favoriteCourses
            .assignAll(data.map((json) => Course.fromJson(json)).toList());
      }
    } catch (e) {
      _logger.e("Error fetching favorites: $e");
    }
  }

  Future<void> fetchMyCourses() async {
    try {
      isLoading.value = true;
      final userId = Get.find<AuthController>().userData['id'];
      if (userId == null) {
        _logger.e("User ID is null, cannot fetch purchased courses.");
        isLoading.value = false;
        return;
      }
      // Assuming a 'user_courses' table that links user_id to course_id
      // And we are joining to get course details from the 'courses' table
      final List<dynamic> response = await _supabase
          .from('user_courses')
          .select('course_id, courses(*)')
          .eq('user_id', userId);

      final purchasedCourses =
          response.map((e) => Course.fromJson(e['courses'])).toList();
      myCourses.assignAll(purchasedCourses);
    } catch (e) {
      _logger.e("Error fetching purchased courses: $e");
      hasError.value = true;
      errorMessage.value = "فشل في جلب كورساتك المشتراة.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(String courseId) async {
    try {
      final response = await _dio.post('/courses/$courseId/favorite');
      if (response.statusCode == 200) {
        Get.snackbar("المفضلة", response.data['message'],
            snackPosition: SnackPosition.BOTTOM);
        fetchFavorites(); // Refresh list
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل تحديث المفضلة",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> fetchCoursesFromApi() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      // Try fetching from Supabase
      final List<dynamic> data = await _courseService.getAllCourses();
      
      if (data.isEmpty) {
        _logger.w("No courses found in Supabase.");
      }

      final courses = data
          .map((json) {
            try {
              return Course.fromJson(json);
            } catch (e) {
              _logger.e("Error parsing single course: $e, Data: $json");
              return null;
            }
          })
          .whereType<Course>()
          .toList();

      allCourses.assignAll(courses);

      // Mark purchased courses
      for (var course in allCourses) {
        if (myCourses.any((myCourse) => myCourse.id == course.id)) {
          course.isPurchased = true;
        }
      }

      applyFilters(); // Apply filters after fetching courses
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "فشل الاتصال بقاعدة البيانات. تأكد من اتصالك بالإنترنت.";
      _logger.e("Critical Error fetching courses: $e");
      
      // Prevent app crash by showing a snackbar instead of throwing
      Get.snackbar(
        "خطأ في الاتصال",
        "تعذر جلب البيانات من السيرفر. يرجى المحاولة لاحقاً.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFE63946),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void searchCourses(String query) {
    searchQuery.value = query;
  }

  void filterCoursesBySubject(String subject) {
    selectedSubject.value = subject;
    applyFilters(); // Apply filters when subject changes
  }

  void applyFilters() {
    List<Course> tempCourses = allCourses;

    // Filter by status: Only 'approved' for regular students
    final authController = Get.find<AuthController>();
    if (!authController.isTeacher) {
      tempCourses = tempCourses.where((c) => c.status == 'approved').toList();
    }

    // Filter by subject
    if (selectedSubject.value != "الكل") {
      tempCourses = tempCourses
          .where((course) => course.subject == selectedSubject.value)
          .toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      tempCourses = tempCourses.where((course) {
        final lowerCaseQuery = searchQuery.value.toLowerCase();
        return course.title.toLowerCase().contains(lowerCaseQuery) ||
            course.instructor.toLowerCase().contains(lowerCaseQuery) ||
            course.subject.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    filteredCourses.assignAll(tempCourses);
  }

  /// VECTOR 1: Content Protection & DRM
  Future<void> playLesson(Lesson lesson) async {
    try {
      isLoading.value = true;

      // 1. Get Secure Stream URL from Backend
      final response = await _dio.get('/courses/lessons/${lesson.id}/stream');
      final String secureUrl = response.data['url'];

      // 2. Navigate to Secure Player
      Get.to(() => VideoPlayerScreen(
            lesson: lesson,
            videoUrl: secureUrl,
          ));
    } catch (e) {
      String errorMsg = "فشل في تحضير الفيديو";
      if (e is DioException) {
        errorMsg = e.response?.data['detail'] ?? errorMsg;
      }
      Get.snackbar("تنبيه", errorMsg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Save playback progress to local storage (and eventually to Supabase)
  void savePlaybackProgress(String lessonId, int seconds) {
    final storage = GetStorage();
    Map<String, dynamic> progress = storage.read('playback_progress') ?? {};
    progress[lessonId] = seconds;
    storage.write('playback_progress', progress);
  }

  /// VECTOR 3: Secure Asset Downloads & Viewing
  Future<void> downloadAsset(LessonAsset asset) async {
    try {
      if (asset.fileUrl.isEmpty) {
        Get.snackbar("تنبيه", "رابط الملف غير متوفر حالياً");
        return;
      }

      final Uri url = Uri.parse(asset.fileUrl);

      // Attempt to launch the URL (which opens the PDF in a new tab/native viewer)
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("خطأ", "لا يمكن فتح الملف، يرجى التأكد من توفر قارئ PDF");
      }
    } catch (e) {
      _logger.e("Error opening asset: $e");
      Get.snackbar("خطأ", "فشل في عرض الملف");
    }
  }

  Future<void> purchaseCourse(Course course) async {
    if (course.isPurchased) return;

    final double currentBalance =
        double.tryParse(_walletController.balance.value) ?? 0;

    if (currentBalance >= course.price) {
      try {
        isLoading.value = true;

        // 1. Call Backend to perform purchase
        final response = await _dio.post('/wallet/purchase/${course.id}');

        // 2. Update local state
        course.isPurchased = true;
        myCourses.add(course);
        allCourses.refresh(); // To update the purchased status on home screen
        filteredCourses
            .refresh(); // To update the purchased status on home screen

        // 3. Update balance from backend response
        _walletController.balance.value =
            response.data['new_balance'].toString();

        // Force update UI
        allCourses.refresh();
        filteredCourses.refresh();

        Get.snackbar(
          "تم الشراء بنجاح",
          response.data['message'] ?? "لقد تم شراء كورس ${course.title} بنجاح",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        );
      } catch (e) {
        String errorMsg = "فشل في إتمام عملية الشراء";
        if (e is DioException) {
          errorMsg = e.response?.data['detail'] ?? errorMsg;
        }
        Get.snackbar("خطأ", errorMsg, snackPosition: SnackPosition.BOTTOM);
      } finally {
        isLoading.value = false;
      }
    } else {
      Get.snackbar(
        "رصيد غير كافٍ",
        "يرجى شحن محفظتك لتتمكن من شراء هذا الكورس",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
      );
    }
  }

  /// Phase 3: Certificate Logic
  Future<void> checkCourseCompletion(String courseId, String courseName, String teacherName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Get total lessons in course
      final lessonsCount = await _supabase.from('lessons').select('id').eq('course_id', courseId).count(CountOption.exact);
      final totalLessons = lessonsCount.count;

      // 2. Get completed lessons for this user
      final completedCount = await _supabase.from('student_progress').select('id').eq('user_id', user.id).eq('status', 'completed').count(CountOption.exact);
      final completedLessons = completedCount.count;

      if (completedLessons >= totalLessons && totalLessons > 0) {
        final authController = Get.find<AuthController>();
        final studentName = authController.userData['name'] ?? "طالب متميز";

        Get.defaultDialog(
          title: "تهانينا! 🎉",
          middleText: "لقد أتممت كافة دروس الكورس بنجاح. هل تود استخراج شهادة التخرج؟",
          textConfirm: "استخراج الشهادة",
          textCancel: "لاحقاً",
          onConfirm: () {
            Get.back();
            CertificateService.generateAndShare(
              studentName: studentName,
              courseName: courseName,
              teacherName: teacherName,
            );
          },
        );
      }
    } catch (e) {
      _logger.e("Error checking completion: $e");
    }
  }
}
