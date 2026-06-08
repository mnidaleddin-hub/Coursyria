import 'dart:convert';

class UserProfile {
  final String id;
  final String? avatarUrl;
  final String? bio;
  final String? gradeLevel;
  final List<String>? interests;
  final String? role;
  final String? referralCode;
  final double? walletBalance;
  final int? currentStreak;
  final int? totalPoints;
  final String? fullName;
  final String? username;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    this.avatarUrl,
    this.fullName,
    this.username,
    this.bio,
    this.gradeLevel,
    this.interests,
    this.role,
    this.referralCode,
    this.walletBalance,
    this.currentStreak,
    this.totalPoints,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      gradeLevel: json['grade_level'] as String?,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      role: json['role'] as String?,
      referralCode: json['referral_code'] as String?,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble(),
      currentStreak: json['current_streak'] as int?,
      totalPoints: json['total_points'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar_url': avatarUrl,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'grade_level': gradeLevel,
      'interests': interests,
      'role': role,
      'referral_code': referralCode,
      'wallet_balance': walletBalance,
      'current_streak': currentStreak,
      'total_points': totalPoints,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Optional: Add copyWith for easier object manipulation
  UserProfile copyWith({
    String? id,
    String? avatarUrl,
    String? bio,
    String? gradeLevel,
    List<String>? interests,
    String? role,
    String? referralCode,
    double? walletBalance,
    int? currentStreak,
    int? totalPoints,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      referralCode: referralCode ?? this.referralCode,
      walletBalance: walletBalance ?? this.walletBalance,
      currentStreak: currentStreak ?? this.currentStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
