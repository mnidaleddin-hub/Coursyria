import 'package:get/get.dart';

class Comment {
  final String id;
  final String userId;
  final String? userName; // From user_profiles join
  final String? userAvatarUrl; // From user_profiles join
  final String postId; // New field
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.postId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles']; // Supabase join result
    return Comment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profiles != null ? profiles['full_name'] as String? : null,
      userAvatarUrl: profiles != null ? profiles['avatar_url'] as String? : null,
      postId: json['post_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
