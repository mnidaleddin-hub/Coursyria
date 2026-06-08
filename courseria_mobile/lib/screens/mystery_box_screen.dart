import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../core/constants/constants.dart';
import '../controllers/gamification_controller.dart';

class MysteryBoxScreen extends StatefulWidget {
  const MysteryBoxScreen({super.key});

  @override
  State<MysteryBoxScreen> createState() => _MysteryBoxScreenState();
}

class _MysteryBoxScreenState extends State<MysteryBoxScreen> {
  final GamificationController _gamificationController = Get.find<GamificationController>();
  late ConfettiController _confettiController;
  bool _isOpened = false;
  int _wonPoints = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _openBox() async {
    final points = await _gamificationController.openMysteryBox();
    if (points > 0) {
      setState(() {
        _wonPoints = points;
        _isOpened = true;
      });
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("الصندوق الغامض", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.amber, Colors.orange, Colors.pink, Colors.blue],
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isOpened ? null : _openBox,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: _isOpened ? 300.w : 250.w,
                    child: Lottie.network(
                      _isOpened 
                        ? 'https://assets10.lottiefiles.com/packages/lf20_mYmMMU.json' // Open box
                        : 'https://assets10.lottiefiles.com/packages/lf20_tou99vdy.json', // Closed box
                      repeat: !_isOpened,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                if (!_isOpened)
                  Column(
                    children: [
                      Text(
                        "اضغط لفتح الصندوق! 🎁",
                        style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "تكلفة الفتح: 100 نقطة",
                        style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        "مبروك! 🎉",
                        style: TextStyle(color: Colors.amber, fontSize: 24.sp, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "لقد حصلت على $_wonPoints نقطة إضافية!",
                        style: TextStyle(color: Colors.white, fontSize: 18.sp),
                      ),
                      SizedBox(height: 40.h),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        ),
                        child: Text("جمع المكافأة", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
