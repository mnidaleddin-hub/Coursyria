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
import 'student_dashboard_screen.dart';
import '../controllers/course_controller.dart';
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
    const GroupsScreen(),
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
      icon: PhosphorIcons.chatCircleDots(),
      selectedIcon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill),
      label: "المجموعات",
      selectedIconWidget: PhosphorIcon(PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill)).animate().scale(duration: 200.ms),
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
    return Obx(() {
      String title = "الرئيسية";
      List<Widget>? actions;

      switch (_currentIndex.value) {
        case 0:
          title = "كورسيريا";
          break;
        case 1:
          title = "تصفح الكورسات";
          final courseController = Get.find<CourseController>();
          actions = [
            Obx(() => courseController.isAiSorting.value 
              ? const Center(child: Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
                  onPressed: () => courseController.sortCoursesByAI(),
                  tooltip: "رتب حسب اهتماماتي (AI)",
                )),
          ];
          break;
        case 2:
          title = "مجتمع التعلم";
          break;
        case 3:
          title = "المحفظة الرقمية";
          break;
        case 4:
          title = "الإعدادات";
          break;
      }

      return Scaffold(
        appBar: _currentIndex.value == 0 
          ? null 
          : AppBar(
              title: Text(title, style: AppTextStyles.header.copyWith(fontSize: 18.sp, color: Colors.white)),
              backgroundColor: AppColors.primaryNavy,
              elevation: 0,
              centerTitle: true,
              actions: actions,
            ),
        body: ResponsiveWrapper(
          currentIndex: _currentIndex.value,
          onIndexChanged: (index) => _currentIndex.value = index,
          destinations: _destinations,
          child: Stack(
            children: [
              PageTransitionSwitcher(
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
              _buildFloatingMenu(),
            ],
          ),
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width <= 600
            ? Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex.value,
                    onTap: (index) => _currentIndex.value = index,
                    backgroundColor: AppColors.secondaryNavy,
                    selectedItemColor: AppColors.accentTeal,
                    unselectedItemColor: Colors.white54,
                    type: BottomNavigationBarType.fixed,
                    items: _destinations.map((d) => BottomNavigationBarItem(
                      icon: d.iconWidget ?? Icon(d.icon),
                      activeIcon: d.selectedIconWidget ?? Icon(d.selectedIcon),
                      label: d.label,
                    )).toList(),
                  ),
                )
            : null,
      );
    });
  }

  Widget _buildFloatingMenu() {
    final authController = Get.find<AuthController>();
    final isTeacher = authController.userData['role'] == 'teacher';

    return Positioned(
      bottom: MediaQuery.of(context).size.width <= 600 ? 20.h : 90.h,
      right: 20.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isMenuOpen) ...[
            if (isTeacher)
              _buildMenuItem(PhosphorIcons.chalkboardTeacher(), "لوحة المعلم", () {
                Get.toNamed('/teacher-dashboard');
              }),
            if (isTeacher) SizedBox(height: 12.h),
            _buildMenuItem(PhosphorIcons.chatTeardropDots(), "المساعد الذكي", () {
              Get.toNamed('/ai-chat');
            }),
            SizedBox(height: 12.h),
            _buildMenuItem(PhosphorIcons.sparkle(), "توليد كويز (AI)", () {
              Get.toNamed('/ai-chat', arguments: {'action': 'quiz'});
            }),
            SizedBox(height: 12.h),
            _buildMenuItem(PhosphorIcons.translate(), "مترجم الدروس", () {
              Get.toNamed('/ai-chat', arguments: {'action': 'translate'});
            }),
            SizedBox(height: 12.h),
            _buildMenuItem(PhosphorIcons.exam(), "امتحان تجريبي", () {
              Get.toNamed('/ai-chat', arguments: {'action': 'exam'});
            }),
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
        mainAxisAlignment: MainAxisAlignment.end,
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
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }
}
