import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/course_controller.dart';
import '../core/constants/constants.dart';
import 'join_team_screen.dart';

import 'my_courses_screen.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  final AuthController _authController = Get.find<AuthController>();
  final WalletController _walletController = Get.find<WalletController>();
  final CourseController _courseController = Get.find<CourseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        title:
            const Text("حسابي", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildProfileCard(),
            SizedBox(height: 20.h),
            _buildActionGrid(),
            SizedBox(height: 20.h),
            _buildSectionTitle("المحفظة والسجل"),
            _buildWalletHistory(),
            SizedBox(height: 20.h),
            _buildSectionTitle("الدعم والطلبات"),
            _buildSupportActions(),
            SizedBox(height: 40.h),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = _authController.userData;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35.r,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            child: Icon(Icons.person, size: 40.r, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? "طالب كورسيريا",
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.bold)),
                Text(user['phone_number'] ?? user['email'] ?? "",
                    style:
                        TextStyle(color: AppColors.textGrey, fontSize: 14.sp)),
                SizedBox(height: 5.h),
                // Display wallet balance here
                Obx(() => Text(
                      "الرصيد: ${_walletController.balance.value} ليرة سورية جديدة",
                      style: TextStyle(
                          color: AppColors.accentTeal,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold),
                    )),
                SizedBox(height: 5.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text("بكالوريا - علمي",
                      style: TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      children: [
        _buildGridItem(Icons.favorite_rounded, "مفضلتي", Colors.red, () {}),
        SizedBox(width: 15.w),
        _buildGridItem(Icons.library_books_rounded, "كورساتي", Colors.blue,
            () => Get.to(() => MyCoursesScreen())),
      ],
    );
  }

  Widget _buildGridItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30.r),
              SizedBox(height: 10.h),
              Text(label,
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, right: 5.w),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWalletHistory() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primaryBlue),
            title: const Text("سجل المعاملات"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.pending_actions,
                color: AppColors.accentOrange),
            title: const Text("الطلبات المعلقة"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportActions() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.green),
            title: const Text("طلب كورس مجاني (صدقة)"),
            subtitle: const Text("للحالات المتعثرة مادياً"),
            onTap: () => _showCharityDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.support_agent, color: AppColors.primaryBlue),
            title: const Text("الدعم الفني والشكاوي"),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.group_add_rounded,
                color: AppColors.accentTeal),
            title: const Text("انضم إلى فريقنا"),
            subtitle: const Text("مدرسين، مصورين، تقنيين"),
            onTap: () => Get.to(() => JoinTeamScreen()),
          ),
        ],
      ),
    );
  }

  void _showCharityDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("طلب كورس مجاني", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "يرجى كتابة سبب طلب الكورس (سيتم مراجعته من قبل الإدارة)"),
            SizedBox(height: 15.h),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "اكتب تبريرك هنا...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () {
                Get.back();
                Get.snackbar("تم الإرسال", "سيتم مراجعة طلبك والرد عليك قريباً",
                    snackPosition: SnackPosition.BOTTOM);
              },
              child: const Text("إرسال الطلب")),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _authController.logout(),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("تسجيل الخروج",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
