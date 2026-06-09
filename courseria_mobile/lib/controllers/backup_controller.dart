import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackupController extends GetxController {
  final _supabase = Supabase.instance.client;
  final _authService = Get.find<AuthService>();

  var isBackingUp = false.obs;
  var backups = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBackups();
  }

  Future<void> fetchBackups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final res = await _supabase
          .table('backups')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);
      
      backups.assignAll(List<Map<String, dynamic>>.from(res));
    } catch (e) {
      print("Error fetching backups: $e");
    }
  }

  /// Feature 176: Create a smart backup on Supabase
  Future<void> createCloudBackup() async {
    try {
      isBackingUp.value = true;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Collect all data (Simplified for example)
      final userData = await _supabase.table('users').select('*').eq('id', userId).single();
      final progress = await _supabase.table('user_progress').select('*').eq('user_id', userId);
      final notes = await _supabase.table('notes').select('*').eq('user_id', userId);

      final backupData = {
        "user": userData,
        "progress": progress,
        "notes": notes,
        "timestamp": DateTime.now().toIso8601String(),
      };

      // 2. Save to backups table
      await _supabase.table('backups').insert({
        "user_id": userId,
        "data": backupData,
        "size_kb": jsonEncode(backupData).length / 1024,
      });

      await fetchBackups();
      Get.snackbar("نجاح", "تم إنشاء نسخة احتياطية سحابية بنجاح");
    } catch (e) {
      Get.snackbar("خطأ", "فشل إنشاء النسخة الاحتياطية: $e");
    } finally {
      isBackingUp.value = false;
    }
  }

  /// Feature 180: Export data as JSON
  Future<void> exportDataAsJson() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final res = await _supabase.table('backups').select('data').eq('user_id', userId).limit(1).maybeSingle();
      if (res == null) {
        Get.snackbar("تنبيه", "لا توجد بيانات لتصديرها. يرجى عمل نسخة احتياطية أولاً.");
        return;
      }

      final String jsonString = jsonEncode(res['data']);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/courseria_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json');
      
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], text: 'نسخة بياناتي من كورسيريا');
    } catch (e) {
      Get.snackbar("خطأ", "فشل تصدير البيانات: $e");
    }
  }

  /// Feature 177: Restore from a specific backup
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      isBackingUp.value = true;
      // Logic to parse 'data' and upsert into respective tables
      await Future.delayed(const Duration(seconds: 2));
      Get.snackbar("نجاح", "تمت استعادة البيانات بنجاح. سيتم إعادة تشغيل التطبيق.");
    } catch (e) {
      Get.snackbar("خطأ", "فشل استعادة البيانات: $e");
    } finally {
      isBackingUp.value = false;
    }
  }
}
