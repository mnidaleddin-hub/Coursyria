import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import 'package:confetti/confetti.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'الثيم الذهبي 🏆', 'cost': 5000, 'desc': 'واجهة ملكية فريدة للتطبيق', 'icon': Icons.palette_rounded, 'color': Colors.amber},
      {'title': 'رمز التميز ✨', 'cost': 2000, 'desc': 'يظهر بجانب اسمك في المناقشات', 'icon': Icons.verified_rounded, 'color': AppColors.accentTeal},
      {'title': 'خصم 50% 🎫', 'cost': 10000, 'desc': 'على أي كورس مدفوع قادم', 'icon': Icons.local_offer_rounded, 'color': Colors.pinkAccent},
      {'title': 'دخول مبكر 🚀', 'cost': 3000, 'desc': 'شاهد الدروس قبل الجميع بـ 24 ساعة', 'icon': Icons.speed, 'color': Colors.blueAccent},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("متجر النقاط 🛒"),
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            margin: EdgeInsets.only(left: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(color: AppColors.accentTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.accentTeal, size: 18),
                SizedBox(width: 4.w),
                const Text("12,450", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GridView.builder(
            padding: EdgeInsets.all(24.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildStoreCard(item);
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.amber, AppColors.accentTeal, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 32.r),
          ),
          SizedBox(height: 16.h),
          Text(item['title'] as String, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: Text(item['desc'] as String, textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () {
              _confettiController.play();
              Get.snackbar("تم الشراء! 🎉", "استمتع بميزتك الجديدة من كورسيريا", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                SizedBox(width: 4.w),
                Text("${item['cost']}", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
