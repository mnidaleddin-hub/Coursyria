import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import 'core/constants/constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_wrapper.dart';
import 'screens/login_screen.dart';
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
import 'controllers/auth_controller.dart';
import 'controllers/wallet_controller.dart';
import 'controllers/course_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/teacher_controller.dart';
import 'controllers/lesson_controller.dart';
import 'controllers/system_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/downloads_manager_screen.dart';
import 'core/theme/theme_controller.dart';
import 'widgets/offline_banner.dart';

import 'screens/supabase_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Notifications
  await NotificationService.init();

  // Register Dio
  Get.put(
    Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    )),
    permanent: true,
  );

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
  }

  // Dependency Injection - Pre-initialize core controllers
  Get.put(AuthController(), permanent: true);
  Get.lazyPut(() => WalletController(), fenix: true);
  Get.lazyPut(() => CourseController(), fenix: true);
  Get.lazyPut(() => NotificationController(), fenix: true);
  Get.lazyPut(() => TeacherController(), fenix: true);
  Get.lazyPut(() => LessonController(), fenix: true);
  Get.lazyPut(() => DashboardController(), fenix: true);
  Get.put(SystemController(), permanent: true); // Immediate for update check
  Get.put(ThemeController());

  // Set Preferred Orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const CourseriaApp());
}

class CourseriaApp extends StatelessWidget {
  const CourseriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Prevent Screenshots and Screen Recording
    if (!kIsWeb) {
      _enableSecureMode();
    }

    final systemController = Get.find<SystemController>();
    final themeController = Get.find<ThemeController>();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          locale: const Locale('ar', 'SY'),
          fallbackLocale: const Locale('ar', 'SY'),
          theme: AppTheme.lightTheme(systemController.selectedThemeColor.value),
          darkTheme: AppTheme.darkTheme(systemController.selectedThemeColor.value),
          themeMode: themeController.theme,
          builder: (context, child) {
            return Column(
              children: [
                const OfflineBanner(),
                Expanded(child: child!),
              ],
            );
          },
          initialRoute: '/splash',
          getPages: [
            GetPage(name: '/splash', page: () => const SplashScreen()),
            GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/home', page: () => const MainWrapper()),
            GetPage(name: '/dashboard', page: () => const StudentDashboardScreen()),
            GetPage(
                name: '/notifications', page: () => const NotificationScreen()),
            GetPage(name: '/supabase_test', page: () => const SupabaseTestScreen()),
            GetPage(
                name: '/teacher_panel', page: () => const TeacherPanelScreen()),
            GetPage(name: '/catalog', page: () => CourseCatalogScreen()),
            GetPage(name: '/settings', page: () => const SettingsScreen()),
            GetPage(name: '/wallet_recharge', page: () => WalletRechargeScreen()),
            GetPage(name: '/leaderboard', page: () => const LeaderboardScreen()),
            GetPage(name: '/referral', page: () => const ReferralRewardsScreen()),
            GetPage(name: '/downloads', page: () => const DownloadsManagerScreen()),
          ],
        ));
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
