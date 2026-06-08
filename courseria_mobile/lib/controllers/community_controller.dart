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

  @override
  void onInit() {
    super.onInit();
    fetchPosts(); // Fetch posts on controller initialization
  }

  /// Fetches all community posts with user and like status.
  Future<void> fetchPosts() async {
    isLoadingPosts.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;

      final List<dynamic> response = await _supabase
          .from('posts')
          .select('*, profiles:user_id(full_name, avatar_url), likes!left(user_id)') // Join with profiles and likes
          .order('created_at', ascending: false);

      posts.assignAll(response.map((json) {
        // Determine if the current user has liked the post
        final List<dynamic>? likesData = json['likes'];
        final bool isLiked = likesData != null && likesData.any((like) => like['user_id'] == userId);
        return Post.fromJson(json).copyWith(isLiked: isLiked);
      }).toList());

    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب المنشورات: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error fetching posts: $e");
    } finally {
      isLoadingPosts.value = false;
    }
  }

  /// Creates a new community post, optionally with an image.
  Future<void> createPost(String content, {File? image}) async {
    if (content.trim().isEmpty && image == null) {
      Get.snackbar("خطأ", "لا يمكن نشر منشور فارغ.",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      return;
    }

    isLoadingPosts.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "يجب تسجيل الدخول أولاً.";

      String? imageUrl;
      if (image != null) {
        final String fileExtension = image.path.split('.').last;
        final String fileName = '${_uuid.v4()}.$fileExtension';
        final String filePath = 'post_images/$fileName';

        // Upload image to Supabase Storage
        await _supabase.storage.from('post_images').upload(
              filePath,
              image,
              fileOptions: const FileOptions(upsert: false),
            );
        imageUrl = _supabase.storage.from('post_images').getPublicUrl(filePath);
      }

      // Insert new post into the 'posts' table
      await _supabase.from('posts').insert({
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'likes_count': 0,
        'comments_count': 0,
      });

      Get.snackbar("نجاح", "تم نشر منشورك بنجاح.",
          backgroundColor: Get.theme.colorScheme.secondary, colorText: Get.theme.colorScheme.onSecondary);
      fetchPosts(); // Refresh posts list
    } catch (e) {
      Get.snackbar("خطأ", "فشل نشر المنشور: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error creating post: $e");
    } finally {
      isLoadingPosts.value = false;
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

  /// Fetches comments for a specific post.
  Future<void> fetchCommentsForPost(String postId) async {
    isCommentsLoading.value = true;
    try {
      final List<dynamic> response = await _supabase
          .from('comments')
          .select('*, profiles:user_id(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      commentsForPost.assignAll(response.map((json) => Comment.fromJson(json)).toList());
    } catch (e) {
      Get.snackbar("خطأ", "فشل جلب التعليقات: $e",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      print("Error fetching comments: $e");
    } finally {
      isCommentsLoading.value = false;
    }
  }

  /// Adds a new comment to a specific post.
  Future<void> addComment(String postId, String content) async {
    if (content.trim().isEmpty) {
      Get.snackbar("خطأ", "لا يمكن نشر تعليق فارغ.",
          backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      return;
    }
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "يجب تسجيل الدخول للتعليق.";

      await _supabase.from('comments').insert({
        'user_id': userId,
        'post_id': postId,
        'content': content,
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
