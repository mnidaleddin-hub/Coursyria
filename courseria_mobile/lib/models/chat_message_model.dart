import 'package:get/get.dart';

class ChatMessage {
  final String id;
  final String groupId;
  final String userId;
  final String? userName;
  final String? userAvatarUrl;
  final String content;
  final String? imageUrl;
  final String? audioUrl;
  final String? fileUrl;
  final String? fileName;
  final String? replyToId;
  final String status; // 'pending', 'sent', 'error'
  final DateTime createdAt;
  final Map<String, int> reactions;
  final bool isTeacher;
  final double voiceSpeed;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.content,
    this.imageUrl,
    this.audioUrl,
    this.fileUrl,
    this.fileName,
    this.replyToId,
    this.status = 'sent',
    required this.createdAt,
    this.reactions = const {},
    this.isTeacher = false,
    this.voiceSpeed = 1.0,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    return ChatMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      userName: profiles != null ? profiles['full_name'] as String? : null,
      userAvatarUrl: profiles != null ? profiles['avatar_url'] as String? : null,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      replyToId: json['reply_to_id'] as String?,
      status: json['status'] as String? ?? 'sent',
      createdAt: DateTime.parse(json['created_at'] as String),
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
      isTeacher: profiles != null ? (profiles['role'] == 'teacher') : false,
      voiceSpeed: (json['voice_speed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'file_url': fileUrl,
      'file_name': fileName,
      'reply_to_id': replyToId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'reactions': reactions,
      'voice_speed': voiceSpeed,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    String? imageUrl,
    String? audioUrl,
    String? fileUrl,
    String? fileName,
    String? replyToId,
    String? status,
    DateTime? createdAt,
    Map<String, int>? reactions,
    bool? isTeacher,
    double? voiceSpeed,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      replyToId: replyToId ?? this.replyToId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      isTeacher: isTeacher ?? this.isTeacher,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
    );
  }
}
