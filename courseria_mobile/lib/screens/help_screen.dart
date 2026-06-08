import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {'q': 'كيف يمكنني شحن المحفظة؟', 'a': 'يمكنك الشحن عبر مكاتبنا المعتمدة أو باستخدام بطاقات الدفع الإلكتروني المتاحة في التطبيق.'},
      {'q': 'هل يمكنني مشاهدة الدروس دون إنترنت؟', 'a': 'نعم، يمكنك تحميل الدروس ومشاهدتها لاحقاً من قسم التحميلات.'},
      {'q': 'كيف أتواصل مع المعلم؟', 'a': 'يمكنك ترك سؤالك في قسم التعليقات أسفل كل درس وسيجيبك المعلم في أقرب وقت.'},
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("الدعم والمساعدة", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("الأسئلة الشائعة", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            ...faqs.map((faq) => _buildFaqItem(faq['q']!, faq['a']!)),
            SizedBox(height: 40.h),
            Text("ما زلت بحاجة للمساعدة؟", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _buildContactCard(PhosphorIcons.envelope(), "البريد الإلكتروني", "support@courseria.com"),
            _buildContactCard(PhosphorIcons.whatsappLogo(), "واتساب الدعم", "+963 9xx xxx xxx"),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(color: AppColors.accentTeal, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(answer, style: TextStyle(color: Colors.white70, fontSize: 13.sp, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 24.sp),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
            ],
          ),
        ],
      ),
    );
  }
}
