import 'package:get/get.dart';

class Post {
  final String id;
  final String userId;
  final String? userName; // From user_profiles join
  final String? userAvatarUrl; // From user_profiles join
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool? isLiked; // To be set dynamically

  Post({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.isLiked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles']; // Supabase join result
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profiles != null ? profiles['full_name'] as String? : null,
      userAvatarUrl: profiles != null ? profiles['avatar_url'] as String? : null,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      likesCount: json['likes_count'] as int,
      commentsCount: json['comments_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLiked: json['is_liked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
