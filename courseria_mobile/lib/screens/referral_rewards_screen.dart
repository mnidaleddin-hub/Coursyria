import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class ReferralRewardsScreen extends StatefulWidget {
  const ReferralRewardsScreen({super.key});

  @override
  State<ReferralRewardsScreen> createState() => _ReferralRewardsScreenState();
}

class _ReferralRewardsScreenState extends State<ReferralRewardsScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final SupabaseClient _supabase = Supabase.instance.client;
  String _referralCode = "جاري التحميل...";
  int _referralCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReferralData();
  }

  Future<void> _fetchReferralData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final profile = await _supabase
          .from('user_profiles')
          .select('referral_code')
          .eq('id', user.id)
          .single();
      
      final referrals = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', user.id)
          .count(CountOption.exact);

      setState(() {
        _referralCode = profile['referral_code'] ?? "غير متوفر";
        _referralCount = referrals.count;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching referral data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: const Text("نظام الإحالة والمكافآت", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
        : SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                _buildGiftIcon(),
                SizedBox(height: 24.h),
                _buildMotivationText(),
                SizedBox(height: 40.h),
                _buildReferralCodeCard(),
                SizedBox(height: 40.h),
                _buildStatsCard(),
                SizedBox(height: 40.h),
                _buildActionButtons(),
              ],
            ),
          ),
    );
  }

  Widget _buildGiftIcon() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.card_giftcard_rounded, size: 80.r, color: AppColors.accentTeal),
    );
  }

  Widget _buildMotivationText() {
    return Column(
      children: [
        Text(
          "شارك المعرفة واكسب المكافآت!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        Text(
          "ادعُ أصدقائك للتسجيل في كورسيريا، واكسب أنت وصديقك 100 ليرة سورية جديدة فور تفعيل حسابه!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildReferralCodeCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text("كود الإحالة الخاص بك", style: TextStyle(color: Colors.white54)),
          SizedBox(height: 16.h),
          Text(
            _referralCode,
            style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w900, letterSpacing: 4),
          ),
          SizedBox(height: 16.h),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _referralCode));
              Get.snackbar("تم النسخ", "تم نسخ الكود إلى الحافظة", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
            },
            icon: const Icon(Icons.copy_rounded, color: AppColors.accentTeal),
            label: const Text("نسخ الكود", style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem("إجمالي الإحالات", _referralCount.toString(), Icons.people_outline),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatItem("إجمالي المكافآت", "${_referralCount * 100}", Icons.account_balance_wallet_outlined),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white38),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton.icon(
        onPressed: () {
          Share.share(
            "انضم إلي في منصة كورسيريا التعليمية واستخدم كود الإحالة الخاص بي: $_referralCode لنحصل كلينا على مكافأة 100 ليرة سورية جديدة! 🚀\nحمل التطبيق الآن: [رابط التطبيق]",
          );
        },
        icon: const Icon(Icons.share_rounded, color: Colors.white),
        label: const Text("مشاركة الكود مع الأصدقاء", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
