import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'auth_controller.dart';

class CommunityController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = const Uuid();

  var isLoadingPosts = false.obs;
  var posts = <Post>[].obs;
  var commentsForPost = <Comment>[].obs;
  var isCommentsLoading = false.obs;
  var isAnonymous = false.obs;
  var selectedTags = <String>[].obs;
  var searchQuery = "".obs;
   var currentSort = 'newest'.obs;
   var offlinePostQueue = <Map<String, dynamic>>[].obs;

  List<Post> get filteredPosts {
    if (searchQuery.value.isEmpty) return posts;
    return posts.where((post) {
      return post.content.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          post.tags.any((tag) => tag.toLowerCase().contains(searchQuery.value.toLowerCase()));
    }).toList();
  }

  void search(String query) {
    searchQuery.value = query;
  }

  @override
  void onInit() {
    super.onInit();
    fetchPosts(); 
    _listenToPosts();
    _loadOfflineQueue();
  }

  void _loadOfflineQueue() {
    final cached = GetStorage().read('community_offline_queue');
    if (cached != null) {
      offlinePostQueue.assignAll(List<Map<String, dynamic>>.from(cached));
    }
  }

  void _saveOfflineQueue() {
    GetStorage().write('community_offline_queue', offlinePostQueue.toList());
  }

  Future<void> syncOfflinePosts() async {
    if (offlinePostQueue.isEmpty) return;
    
    final List<Map<String, dynamic>> toSync = List.from(offlinePostQueue);
    offlinePostQueue.clear();
    _saveOfflineQueue();

    for (var postData in toSync) {
      try {
        await _supabase.from('posts').insert(postData);
        
        // Auto-welcome (Feature 60)
        _checkAndAddWelcomeComment(userId);
      } catch (e) {
        offlinePostQueue.add(postData);
        _saveOfflineQueue();
      }
    }
    fetchPosts();
  }

  void setSort(String sort) {
    currentSort.value = sort;
    fetchPosts();
  }

  void _listenToPosts() {
    _supabase.from('posts').stream(primaryKey: ['id']).listen((data) {
      // Real-time update logic
      fetchPosts();
    });
  }

  void _loadPostsFromCache() {
    final cachedData = GetStorage().read('cached_community_posts');
    if (cachedData != null) {
      posts.assignAll((cachedData as List).map((e) => Post.fromJson(e)).toList());
    }
  }

  void _savePostsToCache(List<Post> fetchedPosts) {
    GetStorage().write('cached_community_posts', fetchedPosts.map((e) => e.toJson()).toList());
  }

  Future<void> fetchPosts() async {
    _loadPostsFromCache();
    if (posts.isEmpty) {
      isLoadingPosts.value = true;
    }
    try {
      final userId = _supabase.auth.currentUser?.id;

      var query = _supabase
          .from('posts')
          .select('*, profiles:user_profiles!user_id(full_name, avatar_url, role), likes!left(user_id)');

      if (selectedTags.isNotEmpty) {
        query = query.contains('tags', selectedTags);
      }

      // Apply sorting
      if (currentSort.value == 'newest') {
        query = query.order('is_pinned', ascending: false).order('created_at', ascending: false);
      } else if (currentSort.value == 'popular') {
        query = query.order('is_pinned', ascending: false).order('likes_count', ascending: false);
      } else if (currentSort.value == 'solved') {
        query = query.eq('is_solved', true).order('created_at', ascending: false);
      } else if (currentSort.value == 'unsolved') {
        query = query.eq('is_solved', false).order('created_at', ascending: false);
      }

      final List<dynamic> response = await query;

      final List<Post> fetchedPosts = response.map((json) {
        final List<dynamic>? likesData = json['likes'];
        final bool isLiked = userId != null && 
            likesData != null && 
            likesData.any((like) => like['user_id'] == userId);
        return Post.fromJson(json).copyWith(isLiked: isLiked);
      }).toList();

      posts.assignAll(fetchedPosts);
      _savePostsToCache(fetchedPosts);

    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب المنشورات: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> toggleSolved(String postId, bool currentStatus) async {
    try {
      await _supabase.from('posts').update({'is_solved': !currentStatus}).eq('id', postId);
      fetchPosts();
    } catch (e) {
      print("Error toggling solved: $e");
    }
  }

  Future<void> pinPost(String postId, bool currentStatus) async {
    if (!_authController.isTeacher) return;
    try {
      await _supabase.from('posts').update({'is_pinned': !currentStatus}).eq('id', postId);
      fetchPosts();
    } catch (e) {
      print("Error pinning post: $e");
    }
  }

  Future<void> reportContent(String type, String id, String reason) async {
    try {
      await _supabase.from('reports').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'content_type': type,
        'content_id': id,
        'reason': reason,
      });
      Get.snackbar("شكراً لك", "تم إرسال البلاغ وسيقوم المشرفون بمراجعته.");
    } catch (e) {
      print("Error reporting content: $e");
    }
  }

  Future<void> createPost(String content, {File? image, File? audio, File? pdf, List<String>? tags}) async {
    if (content.trim().isEmpty && image == null && audio == null && pdf == null) return;
    
    // Profanity Filter (Client-side pre-filter)
    final profanityList = ['سيء1', 'سيء2']; // Extended list in production
    for (var word in profanityList) {
      if (content.contains(word)) {
        Get.snackbar("تنبيه", "محتوى غير لائق.");
        return;
      }
    }

    isLoadingPosts.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      String? imageUrl;
      String? audioUrl;
      String? pdfUrl;

      if (image != null) {
        final fileName = "${_uuid.v4()}.jpg";
        await _supabase.storage.from('posts').upload("images/$fileName", image);
        imageUrl = _supabase.storage.from('posts').getPublicUrl("images/$fileName");
      }

      if (audio != null) {
        final fileName = "${_uuid.v4()}.mp3";
        await _supabase.storage.from('posts').upload("audio/$fileName", audio);
        audioUrl = _supabase.storage.from('posts').getPublicUrl("audio/$fileName");
      }

      if (pdf != null) {
        final fileName = "${_uuid.v4()}.pdf";
        await _supabase.storage.from('posts').upload("docs/$fileName", pdf);
        pdfUrl = _supabase.storage.from('posts').getPublicUrl("docs/$fileName");
      }

      final postData = {
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'audio_url': audioUrl,
        'pdf_url': pdfUrl,
        'is_anonymous': isAnonymous.value,
        'tags': tags ?? [],
      };

      try {
        await _supabase.from('posts').insert(postData);
      } catch (e) {
        // If it's a network error, queue it
        offlinePostQueue.add(postData);
        _saveOfflineQueue();
        Get.snackbar("وضع الأوفلاين", "سيتم نشر منشورك عند عودة الاتصال.");
      }

      isAnonymous.value = false;
      fetchPosts();
    } catch (e) {
      print("Error creating post: $e");
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> _checkAndAddWelcomeComment(String? userId) async {
    if (userId == null) return;
    try {
      final postsCount = await _supabase.from('posts').select('id', const FetchOptions(count: CountOption.exact)).eq('user_id', userId);
      if (postsCount.count == 1) {
        final firstPost = postsCount.data.first;
        await addComment(firstPost['id'], "أهلاً بك في مجتمع كورسيريا! نحن سعداء بمشاركتك الأولى. 🌟");
      }
    } catch (e) {
      print("Error in auto-welcome: $e");
    }
  }

  /// Likes a specific post.
  Future<void> likePost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar("تنبيه", "يجب تسجيل الدخول للإعجاب بالمنشورات.");
      return;
    }
    try {
      // Check if already liked
      final existingLike = await _supabase
          .from('likes')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existingLike == null) {
        // Add like
        await _supabase.from('likes').insert({
          'user_id': userId,
          'post_id': postId,
        });

        // Increment likes count on the post
        await _supabase.rpc('increment_post_likes', params: {'post_id': postId});
        
        // Update local state
        final index = posts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          posts[index] = posts[index].copyWith(likesCount: posts[index].likesCount + 1, isLiked: true);
        }
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل الإعجاب بالمنشور: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error liking post: $e");
    }
  }

  /// Unlikes a specific post.
  Future<void> unlikePost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar("تنبيه", "يجب تسجيل الدخول لإزالة الإعجاب.");
      return;
    }
    try {
      // Remove like
      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);

      // Decrement likes count on the post
      await _supabase.rpc('decrement_post_likes', params: {'post_id': postId});

      // Update local state
      final index = posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        posts[index] = posts[index].copyWith(likesCount: posts[index].likesCount - 1, isLiked: false);
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل إزالة الإعجاب: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error unliking post: $e");
    }
  }

  /// Checks if the current user has liked a specific post.
  /// This is primarily for initial UI rendering, `fetchPosts` already includes `isLiked`.
  Future<bool> isLikedByUser(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final response = await _supabase
          .from('likes')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId);
      return (response as List).isNotEmpty;
    } catch (e) {
      print("Error checking like status: $e");
      return false;
    }
  }

  /// Fetches comments for a specific post and builds a threaded tree.
  Future<void> fetchCommentsForPost(String postId) async {
    isCommentsLoading.value = true;
    try {
      final List<dynamic> response = await _supabase
          .from('comments')
          .select('*, profiles:user_profiles!user_id(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final List<Comment> allComments = response.map((json) => Comment.fromJson(json)).toList();
      commentsForPost.assignAll(_buildCommentThreads(allComments));
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب التعليقات: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error fetching comments: $e");
    } finally {
      isCommentsLoading.value = false;
    }
  }

  List<Comment> _buildCommentThreads(List<Comment> allComments) {
    final Map<String, Comment> commentMap = {for (var c in allComments) c.id: c};
    final List<Comment> rootComments = [];

    for (var comment in allComments) {
      if (comment.parentCommentId == null) {
        rootComments.add(comment);
      } else {
        final parent = commentMap[comment.parentCommentId];
        if (parent != null) {
          // Note: Since our model uses a final list, we need to handle this carefully.
          // In a real app, we'd use a non-final list or copyWith.
          (parent.replies as List<Comment>).add(comment);
        }
      }
    }
    return rootComments;
  }

  /// Adds or updates a reaction to a specific post or comment.
  Future<void> addReaction(String id, String reactionType, {bool isComment = false}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final table = isComment ? 'comment_reactions' : 'post_reactions';
      final column = isComment ? 'comment_id' : 'post_id';

      // Use a single upsert for reaction
      await _supabase.from(table).upsert({
        'user_id': userId,
        column: id,
        'reaction_type': reactionType,
      }, onConflict: 'user_id,$column');

      if (isComment) {
        fetchCommentsForPost(commentsForPost.firstWhere((c) => c.id == id || c.replies.any((r) => r.id == id)).postId);
      } else {
        fetchPosts();
      }
    } catch (e) {
      print("Error adding reaction: $e");
    }
  }

  /// Adds a new comment to a specific post, optionally as a reply.
  Future<void> addComment(String postId, String content, {String? parentId, File? image, File? audio}) async {
    if (content.trim().isEmpty && image == null && audio == null) {
      Get.snackbar("خطأ", "لا يمكن نشر تعليق فارغ.",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      return;
    }
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "يجب تسجيل الدخول للتعليق.";

      String? imageUrl;
      String? audioUrl;

      if (image != null) {
        final fileName = "${_uuid.v4()}.jpg";
        await _supabase.storage.from('comments').upload("images/$fileName", image);
        imageUrl = _supabase.storage.from('comments').getPublicUrl("images/$fileName");
      }

      if (audio != null) {
        final fileName = "${_uuid.v4()}.mp3";
        await _supabase.storage.from('comments').upload("audio/$fileName", audio);
        audioUrl = _supabase.storage.from('comments').getPublicUrl("audio/$fileName");
      }

      await _supabase.from('comments').insert({
        'user_id': userId,
        'post_id': postId,
        'content': content,
        'parent_comment_id': parentId,
        'image_url': imageUrl,
        'audio_url': audioUrl,
      });

      // Increment comments count on the post
      await _supabase.rpc('increment_post_comments', params: {'post_id': postId});

      Get.snackbar("نجاح", "تم إضافة تعليقك.",
          backgroundColor: Get.theme.colorScheme.secondary, colorText: Get.theme.colorScheme.onSecondary);
      fetchCommentsForPost(postId); // Refresh comments list
      fetchPosts(); // Refresh posts list to update comments count
    } catch (e) {
      Get.snackbar("خطأ", "فشل إضافة التعليق: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error adding comment: $e");
    }
  }
}
