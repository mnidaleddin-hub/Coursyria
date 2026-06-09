import 'package:get/get.dart';

class Comment {
  final String id;
  final String userId;
  final String? userName; // From user_profiles join
  final String? userAvatarUrl; // From user_profiles join
  final String postId; 
  final String content;
  final DateTime createdAt;
  final String? parentCommentId;
  final List<Comment> replies;
  final String? audioUrl;
  final String? imageUrl;
  final Map<String, int> reactions;
  final bool isTeacher;

  Comment({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.postId,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
    this.replies = const [],
    this.audioUrl,
    this.imageUrl,
    this.reactions = const {},
    this.isTeacher = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles']; 
    return Comment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profiles != null ? profiles['full_name'] as String? : null,
      userAvatarUrl: profiles != null ? profiles['avatar_url'] as String? : null,
      postId: json['post_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      parentCommentId: json['parent_comment_id'] as String?,
      audioUrl: json['audio_url'] as String?,
      imageUrl: json['image_url'] as String?,
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
      isTeacher: profiles != null ? (profiles['role'] == 'teacher') : false,
      replies: [], // To be populated later
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'parent_comment_id': parentCommentId,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'reactions': reactions,
    };
  }
}
