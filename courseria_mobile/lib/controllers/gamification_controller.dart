import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gamification_models.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

class GamificationController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var stickers = <Sticker>[].obs;
  var userStickers = <String>[].obs; // sticker_ids
  var achievements = <Achievement>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStickers();
    fetchAchievements();
    fetchUserGamificationData();
  }

  Future<void> fetchStickers() async {
    try {
      final response = await _supabase.from('stickers').select().order('price');
      stickers.assignAll((response as List).map((e) => Sticker.fromJson(e)).toList());
    } catch (e) {
      debugPrint("Error fetching stickers: $e");
    }
  }

  Future<void> fetchAchievements() async {
    try {
      final response = await _supabase.from('achievements').select();
      achievements.assignAll((response as List).map((e) => Achievement.fromJson(e)).toList());
    } catch (e) {
      debugPrint("Error fetching achievements: $e");
    }
  }

  Future<void> fetchUserGamificationData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Fetch User Stickers
      final stickersRes = await _supabase.from('user_stickers').select('sticker_id').eq('user_id', userId);
      userStickers.assignAll((stickersRes as List).map((e) => e['sticker_id'] as String).toList());

      // Fetch User Achievements
      final achRes = await _supabase.from('user_achievements').select('achievement_id, unlocked_at').eq('user_id', userId);
      final unlockedAchs = (achRes as List).map((e) => e['achievement_id']).toSet();

      // Update achievements list with unlocked status
      achievements.value = achievements.map((ach) {
        final userAch = (achRes as List).firstWhereOrNull((e) => e['achievement_id'] == ach.id);
        if (userAch != null) {
          return Achievement(
            id: ach.id,
            title: ach.title,
            description: ach.description,
            iconName: ach.iconName,
            pointsReward: ach.pointsReward,
            rarity: ach.rarity,
            unlockedAt: DateTime.parse(userAch['unlocked_at']),
          );
        }
        return ach;
      }).toList();
    } catch (e) {
      debugPrint("Error fetching user gamification data: $e");
    }
  }

  Future<void> buySticker(Sticker sticker) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final currentPoints = _authController.userProfile.value?.totalPoints ?? 0;
    if (currentPoints < sticker.price) {
      Get.snackbar("رصيد غير كافٍ", "تحتاج إلى ${sticker.price - currentPoints} نقطة إضافية لشراء هذا الملصق.",
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      // 1. Transaction: Deduct points and Add Sticker
      // Note: In a production app, use an RPC for atomicity.
      await _supabase.from('user_stickers').insert({
        'user_id': userId,
        'sticker_id': sticker.id,
      });

      await _authController.updateUserProfile({
        'total_points': currentPoints - sticker.price,
      });

      userStickers.add(sticker.id);
      Get.snackbar("نجاح! 🎉", "تم شراء ملصق ${sticker.name} بنجاح.",
          backgroundColor: AppColors.successGreen, colorText: Colors.white);
    } catch (e) {
      debugPrint("Error buying sticker: $e");
      Get.snackbar("خطأ", "فشل شراء الملصق. قد تكون اشتريته بالفعل.",
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<int> openMysteryBox() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final currentPoints = _authController.userProfile.value?.totalPoints ?? 0;
    if (currentPoints < 100) {
      Get.snackbar("رصيد غير كافٍ", "فتح الصندوق يكلف 100 نقطة.",
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
      return 0;
    }

    isLoading.value = true;
    try {
      // Reward logic (random between 50 and 1000)
      final List<int> rewards = [50, 100, 150, 200, 500, 1000];
      final reward = (rewards..shuffle()).first;

      await _authController.updateUserProfile({
        'total_points': currentPoints - 100 + reward,
      });

      return reward;
    } catch (e) {
      debugPrint("Error opening mystery box: $e");
      return 0;
    } finally {
      isLoading.value = false;
    }
  }
}
