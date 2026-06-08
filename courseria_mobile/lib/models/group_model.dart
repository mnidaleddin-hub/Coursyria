import 'package:get/get.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String? coverImageUrl;
  final String ownerId;
  final int memberCount;
  final int postCount;
  final bool isPrivate;
  final String? joinCode;
  final DateTime createdAt;
  final bool? isMember; // To be set dynamically
  final String? myRole; // Role of the current user in the group

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.coverImageUrl,
    required this.ownerId,
    required this.memberCount,
    required this.postCount,
    required this.isPrivate,
    this.joinCode,
    required this.createdAt,
    this.isMember,
    this.myRole,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      ownerId: json['owner_id'] as String,
      memberCount: json['member_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      isPrivate: json['is_private'] as bool,
      joinCode: json['join_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isMember: json['is_member'] as bool?,
      myRole: json['my_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_image_url': coverImageUrl,
      'owner_id': ownerId,
      'member_count': memberCount,
      'post_count': postCount,
      'is_private': isPrivate,
      'join_code': joinCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImageUrl,
    String? ownerId,
    int? memberCount,
    int? postCount,
    bool? isPrivate,
    String? joinCode,
    DateTime? createdAt,
    bool? isMember,
    String? myRole,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ownerId: ownerId ?? this.ownerId,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      isPrivate: isPrivate ?? this.isPrivate,
      joinCode: joinCode ?? this.joinCode,
      createdAt: createdAt ?? this.createdAt,
      isMember: isMember ?? this.isMember,
      myRole: myRole ?? this.myRole,
    );
  }
}
