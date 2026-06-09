import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gamification_models.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/constants.dart';

import '../controllers/community_controller.dart';

class GamificationController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  var stickers = <Sticker>[].obs;
  var userStickers = <String>[].obs; // sticker_ids
  var achievements = <Achievement>[].obs;
  var isLoading = false.obs;

  Future<void> unlockAchievement(String achievementId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final ach = achievements.firstWhere((a) => a.id == achievementId);
      
      // Check if already unlocked
      final existing = await _supabase.from('user_achievements')
          .select().eq('user_id', userId).eq('achievement_id', achievementId).maybeSingle();
      
      if (existing != null) return;

      await _supabase.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      });

      // Post to community (Feature 49)
      final communityController = Get.find<CommunityController>();
      await communityController.createPost(
        "🎉 لقد حصلت للتو على وسام جديد: ${ach.title}! 🏆\n${ach.description}",
        tags: ['إنجازات', 'تحفيز'],
      );

      Get.snackbar("إنجاز جديد! 🏆", "لقد حصلت على وسام: ${ach.title}", backgroundColor: Colors.amber);
      fetchUserGamificationData();
    } catch (e) {
      debugPrint("Error unlocking achievement: $e");
    }
  }

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

      // Fetch User Profile for XP/Streak
      final profileRes = await _supabase.from('user_profiles').select('total_points, level, current_streak').eq('id', userId).single();
      xpPoints.value = profileRes['total_points'] ?? 0;
      currentLevel.value = profileRes['level'] ?? 1;
      dailyStreak.value = profileRes['current_streak'] ?? 0;

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

  var xpPoints = 0.obs;
  var currentLevel = 1.obs;
  var dailyStreak = 0.obs;
  var lastActiveDate = Rxn<DateTime>();

  Future<void> addXP(int amount) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final newXP = xpPoints.value + amount;
      final newLevel = (newXP / 1000).floor() + 1;
      
      await _supabase.from('user_profiles').update({
        'total_points': newXP, // Assuming points = XP for simplicity
        'level': newLevel,
      }).eq('id', userId);

      xpPoints.value = newXP;
      if (newLevel > currentLevel.value) {
        currentLevel.value = newLevel;
        Get.snackbar("مستوى جديد! 🎉", "وصلت إلى المستوى $newLevel", backgroundColor: Colors.amber);
      }
    } catch (e) {
      debugPrint("Error adding XP: $e");
    }
  }

  Future<void> checkStreak() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final profile = await _supabase.from('user_profiles').select('current_streak, last_active_at').eq('id', userId).single();
    final lastActive = profile['last_active_at'] != null ? DateTime.parse(profile['last_active_at']) : null;
    int streak = profile['current_streak'] ?? 0;

    final now = DateTime.now();
    if (lastActive != null) {
      final diff = now.difference(lastActive).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    await _supabase.from('user_profiles').update({
      'current_streak': streak,
      'last_active_at': now.toIso8601String(),
    }).eq('id', userId);

    dailyStreak.value = streak;
  }

  Future<void> exchangePointsForCoupon(int points) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (xpPoints.value < points) {
      Get.snackbar("رصيد غير كافٍ", "أنت بحاجة لمزيد من XP لاستبدال الجوائز", backgroundColor: Colors.orange);
      return;
    }

    try {
      // Exchange logic
      await addXP(-points);
      Get.snackbar("مبروك! 🎁", "تم استبدال النقاط بكوبون خصم بنجاح", backgroundColor: AppColors.accentTeal, colorText: Colors.white);
    } catch (e) {
      debugPrint("Exchange error: $e");
    }
  }
