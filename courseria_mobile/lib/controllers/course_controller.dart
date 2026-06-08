import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import '../models/course_model.dart';
import '../services/analytics_service.dart';
import '../core/constants/constants.dart';
import '../screens/video_player_screen.dart';
import '../services/course_service.dart';
import 'wallet_controller.dart';
import 'auth_controller.dart';
import 'system_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/certificate_service.dart';
import '../services/ai_service.dart';

class CourseController extends GetxController {
  final WalletController _walletController = Get.find<WalletController>();
  final CourseService _courseService = CourseService();
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final Logger _logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService();

  var allCourses = <Course>[].obs;
  var myCourses = <Course>[].obs;
  var filteredCourses = <Course>[].obs;
  var selectedSubject = "الكل".obs;
  var selectedCategory = "الكل".obs;
  var searchQuery = ''.obs; 
  var isAiSorting = false.obs;
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

  final List<String> categories = [
    "الكل",
    "تاسع",
    "بكالوريا",
    "لغات",
    "مهارات",
  ];

  @override
  void onInit() {
    super.onInit();
    // 1. Sync Token for protected routes
    _syncAuthToken();

    // Listen to search text changes with debouncing
    debounce(searchQuery, (_) => applyFilters(), time: const Duration(milliseconds: 500));
    
    fetchCoursesFromApi();
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
  var courseReviews = <Map<String, dynamic>>[].obs;

  Future<void> fetchCourseReviews(String courseId) async {
    try {
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(milliseconds: 300));
        courseReviews.assignAll([
          {'user': 'أحمد م.', 'rating': 5, 'comment': 'شرح ممتاز جداً ومبسط'},
          {'user': 'سارة ح.', 'rating': 4, 'comment': 'محتوى قيم جداً'},
        ]);
        return;
      }
      final response = await _dio.get('/courses/$courseId/reviews');
      if (response.statusCode == 200) {
        courseReviews.assignAll(List<Map<String, dynamic>>.from(response.data));
      }
    } catch (e) {
      _logger.e("Error fetching reviews: $e");
    }
  }

  Future<void> submitReview(String courseId, double rating, String comment) async {
    try {
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        Get.snackbar("شكراً لك!", "تم تسجيل تقييمك محلياً (وضع التجربة)", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
        return;
      }
      final response = await _dio.post('/courses/$courseId/reviews', data: {
        'rating': rating,
        'comment': comment,
      });
      if (response.statusCode == 200) {
        Get.snackbar("تم التقييم", "شكراً لمشاركتك رأيك معنا", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
        fetchCourseReviews(courseId);
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال التقييم", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) return;
      final response = await _dio.get('/courses/favorites');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        favoriteCourses
            .assignAll(data.map((json) => Course.fromJson(json['courses'])).toList());
      }
    } catch (e) {
      _logger.e("Error fetching favorites: $e");
    }
  }

  Future<void> fetchMyCourses() async {
    try {
      isLoading.value = true;
      
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      final response = await _dio.get('/courses/my-courses');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final purchasedCourses = data.map((e) => Course.fromJson(e['courses'])).toList();
        myCourses.assignAll(purchasedCourses);
      }
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
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        Get.snackbar("المفضلة", "تم إضافة الكورس للمفضلة (محلياً)",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
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

      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        // We still keep a minimal fallback but focus on real data
        _logger.d("Offline Mode active - using cache or minimal mock if needed");
      }

      // Implement Retry with Backoff logic
      int retryCount = 0;
      const maxRetries = 3;
      bool success = false;

      while (retryCount < maxRetries && !success) {
        try {
          // 1. Fetch Purchased Courses first
          await fetchMyCourses();

          // 2. Fetch all courses
          final List<dynamic> data = await _courseService.getAllCourses();
          
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
          
          // Save for offline mode
          _saveToOfflineCache(courses);

          applyFilters();
          success = true;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) rethrow;
          _logger.w("Retry $retryCount/$maxRetries for fetching courses...");
          await Future.delayed(Duration(seconds: retryCount * 2)); // Exponential backoff
        }
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "فشل الاتصال بقاعدة البيانات. تأكد من اتصالك بالإنترنت.";
      _logger.e("Critical Error fetching courses: $e");
      
      // Load from offline cache if network fails
      _loadFromOfflineCache();

      Get.snackbar(
        "خطأ في الاتصال",
        "تعذر جلب البيانات من السيرفر. تم تحميل البيانات المخبأة.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE63946),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _saveToOfflineCache(List<Course> courses) {
    final storage = GetStorage();
    // Cache last 10 courses
    final cacheData = courses.take(10).map((e) => e.toJson()).toList();
    storage.write('offline_courses_cache', cacheData);
  }

  void _loadFromOfflineCache() {
    final storage = GetStorage();
    final List<dynamic>? cachedData = storage.read('offline_courses_cache');
    if (cachedData != null) {
      final cachedCourses = cachedData.map((e) => Course.fromJson(e)).toList();
      allCourses.assignAll(cachedCourses);
      applyFilters();
    }
  }

  void searchCourses(String query) {
    searchQuery.value = query;
  }

  void filterCoursesBySubject(String subject) {
    selectedSubject.value = subject;
    applyFilters(); // Apply filters when subject changes
  }

  Future<void> sortCoursesByAI() async {
    try {
      isAiSorting.value = true;
      final authController = Get.find<AuthController>();
      final userInterests = (authController.userData['interests'] as List<dynamic>?)?.cast<String>() ?? ["تعليم", "مهارات"];

      final List<Map<String, dynamic>> coursesData = filteredCourses.map((c) => {
        'id': c.id,
        'title': c.title,
        'subject': c.subject,
        'category': c.category,
      }).toList();

      if (coursesData.isEmpty) return;

      final sortedIds = await _aiService.sortCoursesByInterests(
        userInterests: userInterests,
        courses: coursesData,
      );

      // Reorder filteredCourses based on sortedIds
      final List<Course> sortedList = [];
      for (var id in sortedIds) {
        final course = filteredCourses.firstWhereOrNull((c) => c.id == id);
        if (course != null) sortedList.add(course);
      }

      // Add remaining if any
      for (var c in filteredCourses) {
        if (!sortedList.contains(c)) sortedList.add(c);
      }

      filteredCourses.assignAll(sortedList);
      authController.triggerHaptic(AppHapticFeedback.success);
      Get.snackbar("ذكاء اصطناعي", "تم ترتيب الكورسات حسب اهتماماتك ✨", backgroundColor: AppColors.accentTeal.withOpacity(0.8), colorText: Colors.white);
    } catch (e) {
      _logger.e("Error AI sorting: $e");
    } finally {
      isAiSorting.value = false;
    }
  }

  Future<String> generateInviteLink(String courseId) async {
    // Mock logic for invite link
    return "https://coursyria.com/invite/$courseId?ref=${_supabase.auth.currentUser?.id}";
  }

  void applyFilters() {
    List<Course> tempCourses = List.from(allCourses);

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

      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(milliseconds: 500));
        Get.to(() => VideoPlayerScreen(
              lesson: lesson,
              videoUrl: "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4",
            ));
        return;
      }

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

        final systemController = Get.find<SystemController>();
        if (systemController.isOfflineMode.value) {
          await Future.delayed(const Duration(seconds: 1));
          course.isPurchased = true;
          myCourses.add(course);
          _walletController.balance.value = (currentBalance - course.price).toString();
          allCourses.refresh();
          filteredCourses.refresh();
          Get.snackbar("نجاح (تجربة)", "تم شراء الكورس بنجاح في وضع التجربة", snackPosition: SnackPosition.BOTTOM);
          return;
        }

        // 1. Call Backend to perform purchase
        final response = await _dio.post('/wallet/purchase/${course.id}');

        // 2. Update local state
        course.isPurchased = true;
        myCourses.add(course);
        AnalyticsService.logCoursePurchase(course.id, course.title, course.price);
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
