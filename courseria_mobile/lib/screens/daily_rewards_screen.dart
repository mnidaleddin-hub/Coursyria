import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/constants.dart';
import '../widgets/confetti_overlay.dart';
import '../core/utils/confetti_utils.dart';

class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
  int _currentStreak = 0;
  bool _alreadyClaimed = false;

  final List<Map<String, dynamic>> _rewards = [
    {'day': 1, 'points': 50, 'icon': Icons.stars_rounded},
    {'day': 2, 'points': 100, 'icon': Icons.auto_awesome_rounded},
    {'day': 3, 'points': 150, 'icon': Icons.bolt_rounded},
    {'day': 4, 'points': 200, 'icon': Icons.emoji_events_rounded},
    {'day': 5, 'points': 300, 'icon': Icons.military_tech_rounded},
    {'day': 6, 'points': 500, 'icon': Icons.workspace_premium_rounded},
    {'day': 7, 'points': 1000, 'icon': Icons.diamond_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _checkDailyReward();
  }

  Future<void> _checkDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimDate = prefs.getString('last_claim_date') ?? "";
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    _currentStreak = prefs.getInt('reward_streak') ?? 0;
    
    if (lastClaimDate == today) {
      setState(() => _alreadyClaimed = true);
    }
  }

  Future<void> _claimReward(int dayIndex) async {
    if (_alreadyClaimed || dayIndex != _currentStreak) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await prefs.setString('last_claim_date', today);
    await prefs.setInt('reward_streak', (_currentStreak + 1) % 7);
    
    ConfettiUtils.playConfetti();
    setState(() => _alreadyClaimed = true);
    
    Get.snackbar(
      "مبروك! 🎉",
      "لقد حصلت على ${_rewards[dayIndex]['points']} نقطة مكافأة اليوم",
      backgroundColor: Get.theme.primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                Text("المكافآت اليومية 🎁", 
                  style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w900)),
                SizedBox(height: 8.h),
                Text("سجل دخول يومياً لتحصل على جوائز خارقة!", 
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
                SizedBox(height: 40.h),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                    ),
                    itemCount: _rewards.length,
                    itemBuilder: (context, index) {
                      final reward = _rewards[index];
                      final isClaimed = index < _currentStreak;
                      final isToday = index == _currentStreak && !_alreadyClaimed;
                      final isLocked = index > _currentStreak || (index == _currentStreak && _alreadyClaimed);

                      return GestureDetector(
                        onTap: () => _claimReward(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isToday ? Get.theme.primaryColor : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isToday ? Colors.white : Colors.white10,
                              width: isToday ? 2 : 1,
                            ),
                            boxShadow: isToday ? [
                              BoxShadow(color: Get.theme.primaryColor.withOpacity(0.3), blurRadius: 15)
                            ] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("اليوم ${reward['day']}", 
                                style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                              SizedBox(height: 8.h),
                              Icon(
                                isClaimed ? Icons.check_circle_rounded : reward['icon'], 
                                color: isClaimed ? Colors.greenAccent : (isLocked ? Colors.white24 : Get.theme.primaryColor), 
                                size: 32.r
                              ),
                              SizedBox(height: 8.h),
                              Text("${reward['points']}", 
                                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: const Text("العودة للتعلم", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
