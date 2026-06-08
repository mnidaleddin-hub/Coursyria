import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../models/group_post_model.dart';
import 'auth_controller.dart';

class GroupController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = const Uuid();

  SupabaseClient get supabase => _supabase;

  var isLoadingGroups = false.obs;
  var myGroups = <Group>[].obs;
  var publicGroups = <Group>[].obs;
  var currentGroup = Rx<Group?>(null);
  var groupMembers = <GroupMember>[].obs;
  var groupPosts = <GroupPost>[].obs;
  var isLoadingGroupPosts = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyGroups();
    fetchPublicGroups();
  }

  /// Fetches groups that the current user is a member of.
  Future<void> fetchMyGroups() async {
    isLoadingGroups.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        myGroups.clear();
        return;
      }

      final List<dynamic> response = await _supabase
          .from('group_members')
          .select('groups(*)') 
          .eq('user_id', userId);

      myGroups.assignAll(response.map((e) => Group.fromJson(e['groups'])).toList());
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب مجموعاتي: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error fetching my groups: $e");
    } finally {
      isLoadingGroups.value = false;
    }
  }

  /// Fetches all public groups.
  Future<void> fetchPublicGroups() async {
    isLoadingGroups.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;

      final List<dynamic> response = await _supabase
          .from('groups')
          .select('*, group_members!left(user_id)') 
          .eq('is_private', false);

      publicGroups.assignAll(response.map((json) {
        final List<dynamic>? membersData = json['group_members'];
        final bool isMember = membersData != null && membersData.any((member) => member['user_id'] == userId);
        return Group.fromJson(json).copyWith(isMember: isMember);
      }).toList());
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب المجموعات العامة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error fetching public groups: $e");
    } finally {
      isLoadingGroups.value = false;
    }
  }

  /// Fetches details for a specific group.
  Future<void> fetchGroupDetails(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('groups')
          .select('*, group_members!left(user_id, role)')
          .eq('id', groupId)
          .single();

      final List<dynamic>? membersData = response['group_members'];
      final bool isMember = membersData != null && membersData.any((member) => member['user_id'] == userId);
      final String? myRole = isMember ? (membersData!.firstWhere((member) => member['user_id'] == userId)['role'] as String?) : null;

      currentGroup.value = Group.fromJson(response).copyWith(isMember: isMember, myRole: myRole);
    } catch (e) {
      print("Error fetching group details: $e");
    }
  }

  /// Fetches members of a specific group.
  Future<void> fetchGroupMembers(String groupId) async {
    isLoadingGroups.value = true;
    try {
      final List<dynamic> response = await _supabase
          .from('group_members')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('group_id', groupId);

      groupMembers.assignAll(response.map((e) => GroupMember.fromJson(e)).toList());
    } catch (e) {
      print("Error fetching group members: $e");
    } finally {
      isLoadingGroups.value = false;
    }
  }

  /// Creates a new group.
  Future<void> createGroup(String name, String description, bool isPrivate, {File? coverImage}) async {
    isLoadingGroups.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "يجب تسجيل الدخول لإنشاء مجموعة.";

      String? coverImageUrl;
      if (coverImage != null) {
        final String fileExtension = coverImage.path.split('.').last;
        final String fileName = '${_uuid.v4()}.$fileExtension';
        final String filePath = 'group_covers/$fileName';

        await _supabase.storage.from('group_covers').upload(
              filePath,
              coverImage,
              fileOptions: const FileOptions(upsert: false),
            );
        coverImageUrl = _supabase.storage.from('group_covers').getPublicUrl(filePath);
      }

      final String groupId = _uuid.v4();
      final String? joinCode = isPrivate ? _uuid.v4().substring(0, 8) : null;

      await _supabase.from('groups').insert({
        'id': groupId,
        'name': name,
        'description': description,
        'cover_image_url': coverImageUrl,
        'owner_id': userId,
        'member_count': 1,
        'post_count': 0,
        'is_private': isPrivate,
        'join_code': joinCode,
      });

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'owner',
      });

      Get.snackbar("نجاح", "تم إنشاء المجموعة بنجاح.",
          backgroundColor: Get.theme.colorScheme.secondary, colorText: Get.theme.colorScheme.onSecondary);
      fetchMyGroups();
      fetchPublicGroups();
    } catch (e) {
      Get.snackbar("خطأ", "فشل إنشاء المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error creating group: $e");
    } finally {
      isLoadingGroups.value = false;
    }
  }

  /// Joins a group using groupId or joinCode.
  Future<void> joinGroup(String groupId, {String? joinCode}) async {
    isLoadingGroups.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "يجب تسجيل الدخول للانضمام إلى المجموعات.";

      final group = await _supabase.from('groups').select().eq('id', groupId).single();
      if (group['is_private'] == true && group['join_code'] != joinCode) {
        throw "رمز الانضمام غير صحيح للمجموعة الخاصة.";
      }

      final existingMember = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        Get.snackbar("تنبيه", "أنت بالفعل عضو في هذه المجموعة.",
            backgroundColor: Get.theme.colorScheme.primary, colorText: Get.theme.colorScheme.onPrimary);
        return;
      }

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      await _supabase.rpc('increment_group_member_count', params: {'group_id': groupId});

      Get.snackbar("نجاح", "تم الانضمام إلى المجموعة بنجاح.",
          backgroundColor: Get.theme.colorScheme.secondary, colorText: Get.theme.colorScheme.onSecondary);
      fetchGroupDetails(groupId);
      fetchMyGroups();
      fetchPublicGroups();
    } catch (e) {
      Get.snackbar("خطأ", "فشل الانضمام إلى المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error joining group: $e");
    } finally {
      isLoadingGroups.value = false;
    }
  }

  /// Leaves a group.
  Future<void> leaveGroup(String groupId) async {
    isLoadingGroups.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "يجب تسجيل الدخول للمغادرة.";

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      await _supabase.rpc('decrement_group_member_count', params: {'group_id': groupId});

      Get.snackbar("نجاح", "تمت مغادرة المجموعة بنجاح.",
          backgroundColor: Get.theme.colorScheme.secondary, colorText: Get.theme.colorScheme.onSecondary);
      fetchGroupDetails(groupId);
      fetchMyGroups();
      fetchPublicGroups();
    } catch (e) {
      Get.snackbar("خطأ", "فشل مغادرة المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error leaving group: $e");
    } finally {
      isLoadingGroups.value = false;
    }
  }

  /// Fetches posts for a specific group.
  Future<void> fetchGroupPosts(String groupId) async {
    isLoadingGroupPosts.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;

      final List<dynamic> response = await _supabase
          .from('group_posts')
          .select('*, profiles:user_id(full_name, avatar_url), likes!left(user_id)')
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      groupPosts.assignAll(response.map((json) {
        final List<dynamic>? likesData = json['likes'];
        final bool isLiked = likesData != null && likesData.any((like) => like['user_id'] == userId);
        return GroupPost.fromJson(json).copyWith(isLiked: isLiked);
      }).toList());
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب منشورات المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error fetching group posts: $e");
    } finally {
      isLoadingGroupPosts.value = false;
    }
  }

  /// Creates a new post within a group, optionally with an image.
  Future<void> createGroupPost(String groupId, String content, {File? image}) async {
    isLoadingGroupPosts.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "يجب تسجيل الدخول لإنشاء منشور.";

      String? imageUrl;
      if (image != null) {
        final String fileExtension = image.path.split('.').last;
        final String fileName = '${_uuid.v4()}.$fileExtension';
        final String filePath = 'group_post_images/$fileName';

        await _supabase.storage.from('group_post_images').upload(
              filePath,
              image,
              fileOptions: const FileOptions(upsert: false),
            );
        imageUrl = _supabase.storage.from('group_post_images').getPublicUrl(filePath);
      }

      await _supabase.from('group_posts').insert({
        'group_id': groupId,
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'likes_count': 0,
        'comments_count': 0,
        'is_pinned': false,
      });

      // We might need an RPC for this if we want to keep it consistent
      // For now, let's assume it's handled or we can add it later if needed.
      // await _supabase.rpc('increment_group_post_count', params: {'group_id': groupId});

      Get.snackbar("نجاح", "تم نشر منشور المجموعة بنجاح.",
          backgroundColor: Get.theme.colorScheme.secondary, colorText: Get.theme.colorScheme.onSecondary);
      fetchGroupPosts(groupId);
    } catch (e) {
      Get.snackbar("خطأ", "فشل نشر منشور المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error creating group post: $e");
    } finally {
      isLoadingGroupPosts.value = false;
    }
  }

  /// Likes a specific group post.
  Future<void> likeGroupPost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar("تنبيه", "يجب تسجيل الدخول للإعجاب بالمنشورات.");
      return;
    }
    try {
      await _supabase.from('likes').insert({
        'user_id': userId,
        'post_id': postId,
      });

      await _supabase.rpc('increment_group_post_likes', params: {'post_id': postId});

      final index = groupPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        groupPosts[index] = groupPosts[index].copyWith(likesCount: groupPosts[index].likesCount + 1, isLiked: true);
      }
    } catch (e) {
      print("Error liking group post: $e");
    }
  }

  /// Unlikes a specific group post.
  Future<void> unlikeGroupPost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);

      await _supabase.rpc('decrement_group_post_likes', params: {'post_id': postId});

      final index = groupPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        groupPosts[index] = groupPosts[index].copyWith(likesCount: groupPosts[index].likesCount - 1, isLiked: false);
      }
    } catch (e) {
      print("Error unliking group post: $e");
    }
  }

  /// Toggles the pinned status of a group post.
  Future<void> togglePinPost(String postId, bool isPinned) async {
    try {
      await _supabase
          .from('group_posts')
          .update({'is_pinned': !isPinned})
          .eq('id', postId);

      final index = groupPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        groupPosts[index] = groupPosts[index].copyWith(isPinned: !isPinned);
      }
      
      Get.snackbar("نجاح", isPinned ? "تم إلغاء تثبيت المنشور." : "تم تثبيت المنشور بنجاح.",
          backgroundColor: Get.theme.colorScheme.secondary, colorText: Get.theme.colorScheme.onSecondary);
    } catch (e) {
      Get.snackbar("خطأ", "فشل تغيير حالة تثبيت المنشور: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
    }
  }
}
