import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../models/group_post_model.dart';
import 'auth_controller.dart';

import '../models/chat_message_model.dart';

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

  var chatMessages = <ChatMessage>[].obs;
  var typingUsers = <String>[].obs;
  var onlineMembers = <String>[].obs;
  var messageQueue = <ChatMessage>[].obs;
  var pinnedMessages = <ChatMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyGroups();
    fetchPublicGroups();
  }

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
          .select('groups(*, group_members!left(user_id, role))') 
          .eq('user_id', userId);

      final fetchedGroups = response.map((e) {
        final json = e['groups'];
        final List<dynamic>? membersData = json['group_members'];
        final String? myRole = membersData != null && membersData.isNotEmpty 
            ? (membersData.firstWhereOrNull((member) => member['user_id'] == userId)?['role'] as String?)
            : null;
        return Group.fromJson(json).copyWith(isMember: true, myRole: myRole);
      }).toList();

      myGroups.assignAll(fetchedGroups);
      _saveMyGroupsToCache(fetchedGroups);
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب مجموعاتي: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
    } finally {
      isLoadingGroups.value = false;
    }
  }

  void _saveMyGroupsToCache(List<Group> groups) {
    GetStorage().write('cached_my_groups', groups.map((e) => e.toJson()).toList());
  }

  void _loadMyGroupsFromCache() {
    final cachedData = GetStorage().read('cached_my_groups');
    if (cachedData != null) {
      myGroups.assignAll((cachedData as List).map((e) => Group.fromJson(e)).toList());
    }
  }

  Future<void> togglePinPost(String postId, bool isPinned) async {
    try {
      await _supabase.from('group_posts').update({'is_pinned': !isPinned}).eq('id', postId);
      fetchGroupPosts(currentGroup.value?.id ?? "");
    } catch (e) {
      print("Error toggling pin: $e");
    }
  }

  Future<void> toggleSolved(String postId, bool isSolved) async {
    try {
      await _supabase.from('group_posts').update({'is_solved': !isSolved}).eq('id', postId);
      fetchGroupPosts(currentGroup.value?.id ?? "");
    } catch (e) {
      print("Error toggling solved: $e");
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

  Future<void> fetchGroupDetails(String groupId) async {
    isLoadingGroups.value = true;
    try {
      final response = await _supabase
          .from('groups')
          .select('*, group_members!left(user_id, role)')
          .eq('id', groupId)
          .single();
      
      final userId = _supabase.auth.currentUser?.id;
      final List<dynamic>? membersData = response['group_members'];
      final String? myRole = membersData != null && userId != null
          ? (membersData.firstWhereOrNull((member) => member['user_id'] == userId)?['role'] as String?)
          : null;

      currentGroup.value = Group.fromJson(response).copyWith(
        isMember: myRole != null,
        myRole: myRole,
      );

      // Also fetch related data for the group
      await Future.wait([
        fetchGroupMembers(groupId),
        fetchGroupPosts(groupId),
      ]);

      // Only listen to messages and sync if the user is a member
      if (myRole != null) {
        _listenToMessages(groupId);
        syncOfflineMessages();
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب تفاصيل المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error fetching group details: $e");
    } finally {
      isLoadingGroups.value = false;
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

  Future<void> fetchGroupPosts(String groupId) async {
    _loadPostsFromCache(groupId);
    if (groupPosts.isEmpty) {
      isLoadingGroupPosts.value = true;
    }
    try {
      final userId = _supabase.auth.currentUser?.id;

      final List<dynamic> response = await _supabase
          .from('group_posts')
          .select('*, profiles:user_id(full_name, avatar_url, role), likes!left(user_id)')
          .eq('group_id', groupId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      final List<GroupPost> fetchedPosts = response.map((json) {
        final List<dynamic>? likesData = json['likes'];
        final bool isLiked = userId != null && 
            likesData != null && 
            likesData.any((like) => like['user_id'] == userId);
        return GroupPost.fromJson(json).copyWith(isLiked: isLiked);
      }).toList();

      groupPosts.assignAll(fetchedPosts);
      _savePostsToCache(groupId, fetchedPosts);
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب منشورات المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
    } finally {
      isLoadingGroupPosts.value = false;
    }
  }

  void _loadPostsFromCache(String groupId) {
    final cachedData = GetStorage().read('cached_group_posts_$groupId');
    if (cachedData != null) {
      groupPosts.assignAll((cachedData as List).map((e) => GroupPost.fromJson(e)).toList());
    }
  }

  void _savePostsToCache(String groupId, List<GroupPost> posts) {
    GetStorage().write('cached_group_posts_$groupId', posts.map((e) => e.toJson()).toList());
  }

  Future<void> createGroupPost(String groupId, String content, {File? image, bool isAnonymous = false}) async {
    // Profanity Filter (Reuse from community)
    final profanityList = ['badword1', 'badword2']; 
    for (var word in profanityList) {
      if (content.contains(word)) {
        Get.snackbar("تنبيه", "محتوى غير لائق.");
        return;
      }
    }

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
        'is_anonymous': isAnonymous,
      });

      fetchGroupPosts(groupId);
    } catch (e) {
      Get.snackbar("خطأ", "فشل نشر منشور المجموعة: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
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

  void _listenToMessages(String groupId) {
    _loadChatFromCache(groupId);
    
    // Real-time messages
    _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .listen((data) {
      final messages = data.map((e) => ChatMessage.fromJson(e)).toList();
      chatMessages.assignAll(messages);
      _saveChatToCache(groupId, messages);
      _markMessagesAsRead(groupId);
    });

    // Presence & Typing (using Supabase Realtime Channels)
    final channel = _supabase.channel('group_$groupId');
    
    channel.onPresenceSync((payload) {
      final presenceState = channel.presenceState();
      onlineMembers.assignAll(presenceState.keys);
    }).onPresenceJoin((payload) {
      // Handle join
    }).onPresenceLeave((payload) {
      // Handle leave
    }).onBroadcast(event: 'typing', callback: (payload) {
      final String userId = payload['user_id'];
      final bool typing = payload['is_typing'];
      if (typing) {
        if (!typingUsers.contains(userId)) typingUsers.add(userId);
      } else {
        typingUsers.remove(userId);
      }
    }).subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        channel.track({'user_id': _supabase.auth.currentUser?.id});
      }
    });
  }

  void setTyping(String groupId, bool isTyping) {
    _supabase.channel('group_$groupId').sendBroadcast(
      event: 'typing',
      payload: {'user_id': _supabase.auth.currentUser?.id, 'is_typing': isTyping},
    );
  }

  Future<void> _markMessagesAsRead(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('chat_messages')
          .update({'status': 'read'})
          .eq('group_id', groupId)
          .neq('user_id', userId)
          .eq('status', 'sent');
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  Future<void> sendMessage(String groupId, String content, {String? replyToId, File? image, File? audio, File? file}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    String? imageUrl;
    String? audioUrl;
    String? fileUrl;
    String? fileName;

    // Upload files if any
    try {
      if (image != null) {
        final name = "${_uuid.v4()}.jpg";
        await _supabase.storage.from('chat_media').upload("images/$name", image);
        imageUrl = _supabase.storage.from('chat_media').getPublicUrl("images/$name");
      }
      if (audio != null) {
        final name = "${_uuid.v4()}.mp3";
        await _supabase.storage.from('chat_media').upload("audio/$name", audio);
        audioUrl = _supabase.storage.from('chat_media').getPublicUrl("audio/$name");
      }
      if (file != null) {
        fileName = file.path.split('/').last;
        final name = "${_uuid.v4()}_$fileName";
        await _supabase.storage.from('chat_media').upload("files/$name", file);
        fileUrl = _supabase.storage.from('chat_media').getPublicUrl("files/$name");
      }
    } catch (e) {
      Get.snackbar("خطأ في الرفع", "فشل رفع الوسائط: $e");
    }

    final message = ChatMessage(
      id: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      content: content,
      replyToId: replyToId,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      await _supabase.from('chat_messages').insert(message.toJson());
    } catch (e) {
      messageQueue.add(message);
      _saveOfflineMessages();
      Get.snackbar("وضع الأوفلاين", "سيتم إرسال الرسالة عند عودة الاتصال.");
    }
  }

  void _saveChatToCache(String groupId, List<ChatMessage> messages) {
    // Keep only last 100 messages for cache efficiency (Feature 111)
    final toCache = messages.length > 100 ? messages.sublist(messages.length - 100) : messages;
    GetStorage().write('cached_chat_$groupId', toCache.map((e) => e.toJson()).toList());
  }

  void _loadChatFromCache(String groupId) {
    final cached = GetStorage().read('cached_chat_$groupId');
    if (cached != null) {
      chatMessages.assignAll((cached as List).map((e) => ChatMessage.fromJson(e)).toList());
    }
  }

  void _saveOfflineMessages() {
    GetStorage().write('offline_messages', messageQueue.map((e) => e.toJson()).toList());
  }

  Future<void> syncOfflineMessages() async {
    final cached = GetStorage().read('offline_messages');
    if (cached != null) {
      messageQueue.assignAll((cached as List).map((e) => ChatMessage.fromJson(e)).toList());
    }

    if (messageQueue.isEmpty) return;
    
    final List<ChatMessage> toSync = List.from(messageQueue);
    messageQueue.clear();
    _saveOfflineMessages();

    for (var msg in toSync) {
      try {
        await _supabase.from('chat_messages').insert(msg.toJson());
      } catch (e) {
        messageQueue.add(msg);
        _saveOfflineMessages();
      }
    }
  }

  Future<void> deleteGroupMessage(String messageId) async {
    if (!_authController.isTeacher) return;
    try {
      await _supabase.from('chat_messages').delete().eq('id', messageId);
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  Future<void> toggleMuteRoom(String groupId, bool isMuted) async {
    try {
      await _supabase.from('groups').update({'is_muted': !isMuted}).eq('id', groupId);
      fetchGroupDetails(groupId);
    } catch (e) {
      print("Error muting room: $e");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final myRole = currentGroup.value?.myRole;
    if (myRole != 'owner' && myRole != 'teacher') {
      Get.snackbar("تنبيه", "ليس لديك صلاحية حذف الرسائل.");
      return;
    }

    try {
      await _supabase.from('chat_messages').delete().eq('id', messageId);
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  Future<void> kickMember(String groupId, String userId) async {
    if (currentGroup.value?.myRole != 'owner') return;

    try {
      await _supabase.from('group_members').delete().eq('group_id', groupId).eq('user_id', userId);
      fetchGroupMembers(groupId);
    } catch (e) {
      print("Error kicking member: $e");
    }
  }

  Future<void> toggleRoomLock(String groupId, bool isLocked) async {
    if (currentGroup.value?.myRole != 'owner') return;

    try {
      await _supabase.from('groups').update({'is_locked': !isLocked}).eq('id', groupId);
      fetchGroupDetails(groupId);
    } catch (e) {
      print("Error toggling room lock: $e");
    }
  }

  Future<void> addMessageReaction(String messageId, String reaction) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('chat_message_reactions').upsert({
        'user_id': userId,
        'message_id': messageId,
        'reaction': reaction,
      }, onConflict: 'user_id,message_id');
    } catch (e) {
      print("Error adding message reaction: $e");
    }
  }

  Future<void> reportGroupContent(String type, String id, String reason) async {
    try {
      await _supabase.from('reports').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'content_type': 'group_$type',
        'content_id': id,
        'reason': reason,
      });
      Get.snackbar("شكراً لك", "تم إرسال البلاغ.");
    } catch (e) {
      print("Error reporting group content: $e");
    }
  }
}
