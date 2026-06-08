import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';
import '../core/constants/constants.dart';
import 'join_team_screen.dart';
import 'my_courses_screen.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  final AuthController _authController = Get.find<AuthController>();
  final WalletController _walletController = Get.find<WalletController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 32.h),
                  _buildStatsGrid(),
                  SizedBox(height: 32.h),
                  _buildMenuSection("إدارة الحساب", [
                    _buildMenuItem(PhosphorIcons.userCircle(), "تعديل الملف الشخصي", () {}),
                    _buildMenuItem(PhosphorIcons.heart(), "قائمة المفضلة", () => Get.toNamed('/favorites')),
                    _buildMenuItem(PhosphorIcons.bookBookmark(), "كورساتي المشتراة", () => Get.to(() => MyCoursesScreen())),
                  ]),
                  SizedBox(height: 24.h),
                  _buildMenuSection("المحفظة والدعم", [
                    _buildMenuItem(PhosphorIcons.wallet(), "سجل المعاملات", () => Get.toNamed('/wallet')),
                    _buildMenuItem(PhosphorIcons.gift(), "المكافآت والكوبونات", () => Get.toNamed('/coupons')),
                    _buildMenuItem(PhosphorIcons.headset(), "مركز المساعدة AI", () => Get.toNamed('/help')),
                    _buildMenuItem(PhosphorIcons.usersThree(), "انضم لفريقنا", () => Get.to(() => JoinTeamScreen())),
                  ]),
                  SizedBox(height: 40.h),
                  _buildLogoutButton(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text("الملف الشخصي", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.gearSix(), color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final user = _authController.userData;
      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy.withOpacity(0.15), AppColors.accentTeal.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            _buildAvatar(user['avatar_url']),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? "طالب كورسيريا",
                    style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user['phone'] ?? user['email'] ?? "غير معرف",
                    style: TextStyle(color: Colors.white38, fontSize: 13.sp),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      user['role'] == 'teacher' ? "حساب مدرس 👨‍🏫" : "طالب متميز 🎓",
                      style: TextStyle(color: AppColors.accentTeal, fontSize: 11.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.1, end: 0);
    });
  }

  Widget _buildAvatar(String? url) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Hero(
          tag: 'profile_avatar',
          child: Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentTeal, width: 2),
            ),
            child: CircleAvatar(
              radius: 40.r,
              backgroundColor: AppColors.primaryNavy,
              backgroundImage: url != null ? CachedNetworkImageProvider(url) : null,
              child: url == null ? Icon(PhosphorIcons.user(), size: 40.sp, color: Colors.white) : null,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showImageSourceSheet(),
          child: Container(
            padding: EdgeInsets.all(6.r),
            decoration: const BoxDecoration(color: AppColors.accentTeal, shape: BoxShape.circle),
            child: Icon(PhosphorIcons.camera(), size: 16.sp, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() => Row(
      children: [
        _buildStatCard("الرصيد", _walletController.balance.value, PhosphorIcons.coins(), Colors.amber),
        SizedBox(width: 16.w),
        _buildStatCard("النقاط", _authController.totalPoints.value.toString(), PhosphorIcons.sparkle(), AppColors.accentTeal),
      ],
    ));
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 12.h),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            Text(label, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, bottom: 16.h),
          child: Text(title, style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10.r)),
        child: Icon(icon, color: Colors.white70, size: 20.sp),
      ),
      title: Text(label, style: TextStyle(color: Colors.white, fontSize: 15.sp)),
      trailing: Icon(PhosphorIcons.caretLeft(), color: Colors.white24, size: 16.sp),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: TextButton.icon(
        onPressed: () => _authController.logout(),
        icon: Icon(PhosphorIcons.signOut(), color: Colors.redAccent),
        label: Text("تسجيل الخروج", style: TextStyle(color: Colors.redAccent, fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showImageSourceSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("تغيير الصورة الشخصية", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 24.h),
            ListTile(
              leading: Icon(PhosphorIcons.image(), color: AppColors.accentTeal),
              title: const Text("اختيار من المعرض", style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _authController.pickAndUploadAvatar(isCamera: false);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.camera(), color: AppColors.accentTeal),
              title: const Text("التقاط صورة", style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _authController.pickAndUploadAvatar(isCamera: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
