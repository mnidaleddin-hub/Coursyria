import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/constants/constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/no_internet_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/teacher_panel_screen.dart';
import 'screens/course_catalog_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/wallet_recharge_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/referral_rewards_screen.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/wallet_controller.dart';
import 'controllers/course_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/teacher_controller.dart';
import 'controllers/lesson_controller.dart';
import 'controllers/system_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/ai_controller.dart';
import 'controllers/gamification_controller.dart';
import 'services/ai_service.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/downloads_manager_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/auth_callback_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/daily_rewards_screen.dart';
import 'screens/study_groups_screen.dart';
import 'screens/weekly_challenges_screen.dart';
import 'screens/store_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/learning_path_screen.dart';
import 'screens/smart_review_screen.dart';
import 'screens/audio_summaries_screen.dart';
import 'screens/community_screen.dart';
import 'screens/group_sessions_screen.dart';
import 'screens/mystery_box_screen.dart';
import 'screens/sticker_shop_screen.dart';
import 'screens/coupons_screen.dart';
import 'screens/monthly_report_screen.dart';
import 'screens/teacher_stats_screen.dart';
import 'screens/study_habits_screen.dart';
import 'screens/app_info_screen.dart';
import 'screens/help_screen.dart';
import 'screens/rare_achievements_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/create_course_screen.dart';
import 'screens/upload_video_screen.dart';
import 'screens/my_gallery_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/quiz_result_screen.dart';
import 'models/quiz_model.dart';
import 'models/quiz_result_model.dart';
import 'screens/quiz_screen.dart';
import 'screens/quiz_result_screen.dart';
import 'core/theme/theme_controller.dart';
import 'widgets/offline_banner.dart';

import 'screens/supabase_test_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    if (!kIsWeb) {
      await Firebase.initializeApp();
      
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(const CourseriaApp());
  }, (error, stack) {
    debugPrint('❌ Unhandled Exception: $error');
    debugPrint('Stack Trace: $stack');
  });
}

class CourseriaApp extends StatefulWidget {
  const CourseriaApp({super.key});

  @override
  State<CourseriaApp> createState() => _CourseriaAppState();
}

class _CourseriaAppState extends State<CourseriaApp> {
  late Future<void> _initFuture;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Rx<ConnectivityResult> _connectivityStatus = ConnectivityResult.wifi.obs;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Platform-specific crash prevention
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('❌ Flutter Error: ${details.exception}');
      };

      // Register Core Services early
      if (!Get.isRegistered<FlutterSecureStorage>()) {
        if (kIsWeb) {
          // Mock for Web: Secure memory only, no persistence
          Get.put(const FlutterSecureStorage(
            webOptions: WebOptions(
              dbName: 'CourseriaSecure',
              publicKey: 'CourseriaKey',
            ),
          ), permanent: true);
        } else {
          Get.put(const FlutterSecureStorage(), permanent: true);
        }
      }

      if (!Get.isRegistered<Dio>()) {
        Get.put(Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )), permanent: true);
      }

      // Initialize critical services in parallel to reduce cold start
      await Future.wait([
        GetStorage.init(),
        _initSupabase(),
        _loadEnv(),
      ]);

      // Register Controllers
      _registerMandatoryControllers();
      _registerLazyControllers();

      // Connectivity
      await _initConnectivity();
    } catch (e) {
      debugPrint('❌ Global Init Error: $e');
      rethrow;
    }
  }

  Future<void> _initSupabase() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('⚠️ Supabase Init Failed: $e');
      // We don't rethrow here to allow the app to start even if Supabase is down
    }
  }

  Future<void> _loadEnv() async {
    try {
      // await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('⚠️ Env Load Failed: $e');
    }
  }

  void _registerMandatoryControllers() {
    if (!Get.isRegistered<SystemController>()) Get.put(SystemController(), permanent: true);
    if (!Get.isRegistered<ThemeController>()) Get.put(ThemeController(), permanent: true);
    if (!Get.isRegistered<AuthController>()) Get.put(AuthController(), permanent: true);
    
    // Register Core Services
    Get.put(NotificationService(), permanent: true);
    Get.put(PaymentService(), permanent: true);
    Get.put(AIService(), permanent: true);
  }

  void _registerLazyControllers() {
    Get.lazyPut(() => WalletController(), fenix: true);
    Get.lazyPut(() => CourseController(), fenix: true);
    Get.lazyPut(() => NotificationController(), fenix: true);
    Get.lazyPut(() => TeacherController(), fenix: true);
    Get.lazyPut(() => LessonController(), fenix: true);
    Get.lazyPut(() => DashboardController(), fenix: true);
    Get.lazyPut(() => AIController(), fenix: true);
    Get.lazyPut(() => GamificationController(), fenix: true);
  }

  Future<void> _initConnectivity() async {
    final Connectivity connectivity = Connectivity();
    try {
      final List<ConnectivityResult> result = await connectivity.checkConnectivity();
      if (result.isNotEmpty) {
        _connectivityStatus.value = result.first;
      }
    } catch (e) {
      debugPrint('❌ Connectivity Check Error: $e');
    }

    _connectivitySubscription?.cancel();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _connectivityStatus.value = results.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      _enableSecureMode();
    }

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  backgroundColor: AppColors.primaryNavy,
                  body: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 60),
                          SizedBox(height: 20.h),
                          Text(
                            "حدث خطأ أثناء تشغيل التطبيق",
                            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30.h),
                          ElevatedButton(
                            onPressed: () => setState(() { _initFuture = _initializeApp(); }),
                            child: const Text("إعادة المحاولة"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  backgroundColor: AppColors.primaryNavy,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.accentTeal),
                        const SizedBox(height: 20),
                        Text(
                          "جاري تهيئة كورسيريا...",
                          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final systemController = Get.find<SystemController>();
            final themeController = Get.find<ThemeController>();

            return Obx(() => GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: AppConstants.appName,
              locale: const Locale('ar', 'SY'),
              fallbackLocale: const Locale('ar', 'SY'),
              theme: AppTheme.lightTheme(themeController.currentPrimaryColor),
              darkTheme: AppTheme.darkTheme(themeController.currentPrimaryColor),
              themeMode: themeController.themeMode.value,
              defaultTransition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 400),
              builder: (context, child) {
                return Obx(() {
                  if (_connectivityStatus.value == ConnectivityResult.none) {
                    return NoInternetScreen(onRetry: () => _initConnectivity());
                  }
                  return Stack(
                    children: [
                      Column(
                        children: [
                          Obx(() => systemController.isGlobalLoading.value
                              ? LinearProgressIndicator(
                                  value: systemController.loadingProgress.value > 0
                                      ? systemController.loadingProgress.value
                                      : null,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(themeController.currentPrimaryColor),
                                  minHeight: 3.h,
                                )
                              : SizedBox(height: 3.h)),
                          const OfflineBanner(),
                          Expanded(child: child!),
                        ],
                      ),
                      Obx(() => systemController.isBlueLightFilterEnabled.value
                          ? IgnorePointer(
                              child: Container(
                                color: Colors.orange.withOpacity(0.15),
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  );
                });
              },
              initialRoute: '/splash',
              getPages: [
                GetPage(name: '/splash', page: () => const SplashScreen()),
                GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
                GetPage(name: '/login', page: () => const LoginScreen()),
                GetPage(name: '/home', page: () => const MainWrapper()),
                GetPage(name: '/dashboard', page: () => const StudentDashboardScreen()),
                GetPage(name: '/notifications', page: () => const NotificationScreen()),
                GetPage(name: '/supabase_test', page: () => const SupabaseTestScreen()),
                GetPage(name: '/teacher_panel', page: () => const TeacherPanelScreen()),
                GetPage(name: '/catalog', page: () => const CourseCatalogScreen()),
                GetPage(name: '/settings', page: () => const SettingsScreen()),
                GetPage(name: '/wallet_recharge', page: () => WalletRechargeScreen(), transition: Transition.rightToLeftWithFade),
                GetPage(name: '/leaderboard', page: () => const LeaderboardScreen(), transition: Transition.upToDown),
                GetPage(name: '/referral', page: () => const ReferralRewardsScreen()),
                GetPage(name: '/downloads', page: () => const DownloadsManagerScreen()),
                GetPage(name: '/otp-verification', page: () => const OtpVerificationScreen()),
                GetPage(name: '/complete-profile', page: () => const CompleteProfileScreen()),
                GetPage(name: '/auth/callback', page: () => const AuthCallbackScreen()),
                GetPage(name: '/achievements', page: () => const AchievementsScreen(), transition: Transition.zoom),
                GetPage(name: '/daily-rewards', page: () => const DailyRewardsScreen(), transition: Transition.fadeIn),
                GetPage(name: '/study-groups', page: () => const StudyGroupsScreen()),
                GetPage(name: '/weekly-challenges', page: () => const WeeklyChallengesScreen(), transition: Transition.circularReveal),
                GetPage(name: '/store', page: () => const StoreScreen(), transition: Transition.cupertino),
                GetPage(name: '/teacher-dashboard', page: () => const TeacherDashboardScreen()),
                GetPage(name: '/learning-path', page: () => const LearningPathScreen()),
                GetPage(name: '/smart-review', page: () => const SmartReviewScreen()),
                GetPage(name: '/audio-summaries', page: () => const AudioSummariesScreen()),
                GetPage(name: '/community', page: () => const CommunityScreen()),
                GetPage(name: '/group-sessions', page: () => const GroupSessionsScreen()),
                GetPage(name: '/mystery-box', page: () => const MysteryBoxScreen()),
                GetPage(name: '/sticker-shop', page: () => const StickerShopScreen()),
                GetPage(name: '/coupons', page: () => const CouponsScreen()),
                GetPage(name: '/monthly-report', page: () => const MonthlyReportScreen()),
                GetPage(name: '/teacher-stats', page: () => const TeacherStatsScreen()),
                GetPage(name: '/study-habits', page: () => const StudyHabitsScreen()),
                GetPage(name: '/app-info', page: () => const AppInfoScreen()),
                GetPage(name: '/help', page: () => const HelpScreen()),
                GetPage(name: '/rare-achievements', page: () => const RareAchievementsScreen()),
                GetPage(name: '/notification-center', page: () => const NotificationCenterScreen()),
                GetPage(name: '/create-course', page: () => const CreateCourseScreen()),
                GetPage(name: '/upload-video', page: () => const UploadVideoScreen()),
                GetPage(name: '/my-gallery', page: () => const MyGalleryScreen()),
                GetPage(
                  name: '/quiz',
                  page: () {
                    final args = Get.arguments as Map<String, dynamic>;
                    if (args.containsKey('quiz')) {
                      return QuizScreen(quiz: args['quiz'] as Quiz);
                    }
                    // Handle AI Temp Quiz
                    return QuizScreen(
                      quiz: Quiz(
                        id: 'ai_temp_${DateTime.now().millisecondsSinceEpoch}',
                        title: args['title'] ?? 'اختبار ذكي',
                        description: 'اختبار مولد بواسطة الذكاء الاصطناعي',
                        passingScore: 60,
                        questionsCount: (args['questions'] as List).length,
                        isPublished: true,
                        createdAt: DateTime.now(),
                      ),
                    );
                  },
                ),
                GetPage(
                  name: '/quiz-result',
                  page: () => QuizResultScreen(result: Get.arguments as QuizResult),
                ),
              ],
            ));
          },
        );
      },
    );
  }

  Future<void> _enableSecureMode() async {
    try {
      // await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (e) {
      debugPrint("Could not enable secure mode: $e");
    }
  }
}
