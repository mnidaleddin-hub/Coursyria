import 'package:get/get.dart';

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String? userName; // From user_profiles join
  final String? userAvatarUrl; // From user_profiles join
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles']; // Supabase join result
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      userName: profiles != null ? profiles['full_name'] as String? : null,
      userAvatarUrl: profiles != null ? profiles['avatar_url'] as String? : null,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
