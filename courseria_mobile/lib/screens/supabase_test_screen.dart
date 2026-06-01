import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/supabase_service.dart';
import '../core/constants/constants.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final List<Map<String, dynamic>> _testResults = [];
  bool _isLoading = false;

  void _addResult(String title, bool success, String detail, {String? sql}) {
    setState(() {
      _testResults.add({
        'title': title,
        'success': success,
        'detail': detail,
        'sql': sql,
      });
    });
  }

  Future<void> _runComprehensiveTests() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    // 1. Connectivity
    final isConnected = await _supabaseService.isConnected();
    _addResult("الاتصال بالإنترنت", isConnected, isConnected ? "متصل" : "غير متصل");

    // 2. Table: courses (SELECT)
    final resCoursesSelect = await _supabaseService.testSelect('courses');
    _addResult("طلب (SELECT) - courses", resCoursesSelect['success'], 
      resCoursesSelect['success'] ? "تم جلب ${resCoursesSelect['data'].length} سجل" : resCoursesSelect['error'],
      sql: "CREATE POLICY \"Allow public read\" ON courses FOR SELECT USING (true);");

    // 3. Table: wallets (INSERT/UPDATE Test)
    final resWalletUpsert = await _supabaseService.testUpsert('wallets', {
      'user_id': '00000000-0000-0000-0000-000000000000', // Fake UUID
      'balance': 1000,
    });
    _addResult("إرسال (UPSERT) - wallets", resWalletUpsert['success'], 
      resWalletUpsert['success'] ? "تم التحديث بنجاح" : resWalletUpsert['error'],
      sql: "CREATE POLICY \"Allow individual insert\" ON wallets FOR INSERT WITH CHECK (auth.uid() = user_id);");

    // 4. Table: users (SELECT Profile)
    final resUsersSelect = await _supabaseService.testSelect('users', limit: 1);
    _addResult("طلب (SELECT) - users", resUsersSelect['success'], 
      resUsersSelect['success'] ? "تم الوصول للجدول" : resUsersSelect['error'],
      sql: "ALTER TABLE users ENABLE ROW LEVEL SECURITY;");

    // 5. Storage: payments (FULL CYCLE)
    final resStorage = await _supabaseService.testStorageFullCycle(
      'payments', 'test_file.txt', 'Comprehensive Test Content');
    _addResult("التخزين (Storage) - payments", resStorage['success'], 
      resStorage['success'] ? "تم الرفع والتحقق والحذف" : resStorage['error'],
      sql: "CREATE POLICY \"Allow public uploads\" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'payments');");

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تقرير اختبار Supabase الشامل"),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _runComprehensiveTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("تشغيل الاختبار الشامل"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final item = _testResults[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: ExpansionTile(
                    leading: Icon(
                      item['success'] ? Icons.check_circle : Icons.error,
                      color: item['success'] ? Colors.green : Colors.red,
                    ),
                    title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['success'] ? "✅ نجاح كامل" : "❌ فشل"),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("التفاصيل:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
                            Text(item['detail'], style: TextStyle(color: Colors.grey[700])),
                            if (!item['success'] && item['sql'] != null) ...[
                              SizedBox(height: 10.h),
                              const Text("حل SQL مقترح:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              Container(
                                padding: EdgeInsets.all(8.r),
                                color: Colors.grey[200],
                                child: SelectableText(item['sql']!, style: const TextStyle(fontFamily: 'monospace')),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
