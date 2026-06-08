import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/constants.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    try {
      // الانتظار قليلاً للتأكد من معالجة Supabase للرابط
      await Future.delayed(const Duration(seconds: 1));
      
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // إغلاق المتصفح الخارجي إذا كان مفتوحاً (للهواتف)
        if (!GetPlatform.isWeb) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop'); 
          // ملاحظة: SystemNavigator.pop قد يغلق التطبيق بالكامل في بعض الحالات، 
          // ولكن في تدفق OAuth عادة ما يعيد التركيز للتطبيق. 
          // الأفضل هو الاعتماد على أن الـ Deep Link أعاد المستخدم بالفعل.
        }
        
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }
    } catch (e) {
      debugPrint("Auth Callback Error: $e");
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accentTeal),
            SizedBox(height: 24),
            Text(
              "جاري التحقق من تسجيل الدخول...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
