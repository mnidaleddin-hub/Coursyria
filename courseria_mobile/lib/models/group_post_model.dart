import 'package:get/get.dart';

class GroupPost {
  final String id;
  final String groupId;
  final String userId;
  final String? userName; // From user_profiles join
  final String? userAvatarUrl; // From user_profiles join
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final bool isPinned;
  final DateTime createdAt;
  final bool? isLiked; // To be set dynamically

  GroupPost({
    required this.id,
    required this.groupId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.isPinned,
    required this.createdAt,
    this.isLiked,
  });

  factory GroupPost.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles']; // Supabase join result
    return GroupPost(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      userName: profiles != null ? profiles['full_name'] as String? : null,
      userAvatarUrl: profiles != null ? profiles['avatar_url'] as String? : null,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLiked: json['is_liked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupPost copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    bool? isPinned,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return GroupPost(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
