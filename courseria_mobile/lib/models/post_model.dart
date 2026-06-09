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
  final bool? isLiked; 
  final bool isPinned;
  final bool isAnonymous;
  final bool isSolved;
  final String? audioUrl;
  final String? pdfUrl;
  final List<String> tags;
  final Map<String, int> reactions;
  final bool isTeacher;

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
    this.isPinned = false,
    this.isAnonymous = false,
    this.isSolved = false,
    this.audioUrl,
    this.pdfUrl,
    this.tags = const [],
    this.reactions = const {},
    this.isTeacher = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles']; 
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['is_anonymous'] == true ? "مستخدم مجهول" : (profiles != null ? profiles['full_name'] as String? : null),
      userAvatarUrl: json['is_anonymous'] == true ? null : (profiles != null ? profiles['avatar_url'] as String? : null),
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLiked: json['is_liked'] as bool?,
      isPinned: json['is_pinned'] ?? false,
      isAnonymous: json['is_anonymous'] ?? false,
      isSolved: json['is_solved'] ?? false,
      audioUrl: json['audio_url'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
      isTeacher: profiles != null ? (profiles['role'] == 'teacher') : false,
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
      'is_pinned': isPinned,
      'is_anonymous': isAnonymous,
      'is_solved': isSolved,
      'audio_url': audioUrl,
      'pdf_url': pdfUrl,
      'tags': tags,
      'reactions': reactions,
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
    bool? isPinned,
    bool? isAnonymous,
    bool? isSolved,
    String? audioUrl,
    String? pdfUrl,
    List<String>? tags,
    Map<String, int>? reactions,
    bool? isTeacher,
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
      isPinned: isPinned ?? this.isPinned,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isSolved: isSolved ?? this.isSolved,
      audioUrl: audioUrl ?? this.audioUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      tags: tags ?? this.tags,
      reactions: reactions ?? this.reactions,
      isTeacher: isTeacher ?? this.isTeacher,
    );
  }
}
