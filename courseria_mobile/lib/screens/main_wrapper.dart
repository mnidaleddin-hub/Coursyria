import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/responsive_wrapper.dart';
import 'community_screen.dart';
import 'home_screen.dart';
import 'course_catalog_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';
import 'teacher_dashboard_screen.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with SingleTickerProviderStateMixin {
  final RxInt _currentIndex = 0.obs;
  late AnimationController _fabController;
  bool _isMenuOpen = false;

  final List<Widget> _pages = [
    HomeScreen(),
    const CourseCatalogScreen(),
    const CommunityScreen(),
    WalletScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationDestinationData> _destinations = [
    NavigationDestinationData(
      icon: PhosphorIcons.house(),
      selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
      label: "الرئيسية",
      selectedIconWidget: PhosphorIcon(PhosphorIcons.house(PhosphorIconsStyle.fill)).animate().scale(duration: 200.ms),
    ),
    NavigationDestinationData(
      icon: PhosphorIcons.bookOpen(),
      selectedIcon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
      label: "الكورسات",
      selectedIconWidget: PhosphorIcon(PhosphorIcons.bookOpen(PhosphorIconsStyle.fill)).animate().scale(duration: 200.ms),
    ),
    NavigationDestinationData(
      icon: PhosphorIcons.usersThree(),
      selectedIcon: PhosphorIcons.usersThree(PhosphorIconsStyle.fill),
      label: "المجتمع",
      selectedIconWidget: PhosphorIcon(PhosphorIcons.usersThree(PhosphorIconsStyle.fill)).animate().scale(duration: 200.ms),
    ),
    NavigationDestinationData(
      icon: PhosphorIcons.wallet(),
      selectedIcon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
      label: "المحفظة",
      selectedIconWidget: PhosphorIcon(PhosphorIcons.wallet(PhosphorIconsStyle.fill)).animate().scale(duration: 200.ms),
    ),
    NavigationDestinationData(
      icon: PhosphorIcons.gear(),
      selectedIcon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
      label: "الإعدادات",
      selectedIconWidget: PhosphorIcon(PhosphorIcons.gear(PhosphorIconsStyle.fill)).animate().scale(duration: 200.ms),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _checkRating();
  }

  void _checkRating() {
    final storage = GetStorage();
    final firstLaunch = storage.read('first_launch') ?? DateTime.now().millisecondsSinceEpoch;
    if (storage.read('first_launch') == null) {
      storage.write('first_launch', firstLaunch);
    }

    final days = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(firstLaunch)).inDays;
    final rated = storage.read('app_rated') ?? false;

    if (days >= 7 && !rated) {
      Future.delayed(const Duration(seconds: 5), () => _showRatingDialog());
    }
  }

  void _showRatingDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text("هل تستمتع بكورسيريا؟"),
        content: const Text("تقييمك يساعدنا على تقديم أفضل جودة تعليمية للمنهاج السوري."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("لاحقاً")),
          ElevatedButton(
            onPressed: () {
              GetStorage().write('app_rated', true);
              Get.back();
              Get.snackbar("شكراً لك!", "نقدر وقتك ودعمك لنا.");
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
            child: const Text("تقييم الآن"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.theme.scaffoldBackgroundColor,
                    context.theme.primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .shimmer(duration: const Duration(seconds: 5), color: AppColors.accentTeal.withOpacity(0.05)),
          ),
          Obx(() => ResponsiveWrapper(
            currentIndex: _currentIndex.value,
            onIndexChanged: (index) => _currentIndex.value = index,
            destinations: _destinations,
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation, secondaryAnimation) {
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              },
              child: _pages[_currentIndex.value],
            ),
          )),
          _buildFloatingMenu(),
        ],
      ),
    );
  }

  Widget _buildFloatingMenu() {
    final authController = Get.find<AuthController>();
    final isTeacher = authController.userData['role'] == 'teacher';

    return Positioned(
      bottom: 90.h,
      right: 20.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isMenuOpen) ...[
            if (isTeacher)
              _buildMenuItem(PhosphorIcons.chalkboardTeacher(), "لوحة المعلم", () {
                _toggleMenu();
                Get.toNamed('/teacher-dashboard');
              }),
            if (isTeacher) SizedBox(height: 12.h),
            _buildMenuItem(PhosphorIcons.chatTeardropDots(), "الدعم الفني", () {
              _toggleMenu();
              Get.toNamed('/ai-chat');
            }),
            SizedBox(height: 12.h),
            _buildMenuItem(PhosphorIcons.shareNetwork(), "مشاركة", () {}),
            SizedBox(height: 12.h),
          ],
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: AppColors.accentTeal,
            elevation: 4,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _fabController,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        _toggleMenu();
        onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: const BoxDecoration(color: AppColors.primaryNavy, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.2),
    );
  }
}
