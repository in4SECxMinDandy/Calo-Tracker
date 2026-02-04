// Community Profile Model
// Extended user profile for community features
import 'package:flutter/material.dart';

class CommunityProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;

  // Health data
  final double? height;
  final double? weight;
  final String? goal;
  final double? bmr;
  final double? dailyTarget;
  final String country;
  final String language;

  // Community stats
  final int totalPoints;
  final int level;
  final int challengesCompleted;
  final int followersCount;
  final int followingCount;

  // Privacy settings
  final ProfileVisibility profileVisibility;
  final bool showStatsPublicly;
  final bool allowChallengeInvites;
  final bool allowGroupInvites;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isPublic => profileVisibility == ProfileVisibility.public;

  const CommunityProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.height,
    this.weight,
    this.goal,
    this.bmr,
    this.dailyTarget,
    this.country = 'VN',
    this.language = 'vi',
    this.totalPoints = 0,
    this.level = 1,
    this.challengesCompleted = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.profileVisibility = ProfileVisibility.public,
    this.showStatsPublicly = true,
    this.allowChallengeInvites = true,
    this.allowGroupInvites = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityProfile.fromJson(Map<String, dynamic> json) {
    return CommunityProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      goal: json['goal'] as String?,
      bmr: (json['bmr'] as num?)?.toDouble(),
      dailyTarget: (json['daily_target'] as num?)?.toDouble(),
      country: json['country'] as String? ?? 'VN',
      language: json['language'] as String? ?? 'vi',
      totalPoints: json['total_points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      challengesCompleted: json['challenges_completed'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      profileVisibility: ProfileVisibility.fromString(
        json['profile_visibility'] as String? ?? 'public',
      ),
      showStatsPublicly: json['show_stats_publicly'] as bool? ?? true,
      allowChallengeInvites: json['allow_challenge_invites'] as bool? ?? true,
      allowGroupInvites: json['allow_group_invites'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'height': height,
      'weight': weight,
      'goal': goal,
      'bmr': bmr,
      'daily_target': dailyTarget,
      'country': country,
      'language': language,
      'total_points': totalPoints,
      'level': level,
      'challenges_completed': challengesCompleted,
      'followers_count': followersCount,
      'following_count': followingCount,
      'profile_visibility': profileVisibility.name,
      'show_stats_publicly': showStatsPublicly,
      'allow_challenge_invites': allowChallengeInvites,
      'allow_group_invites': allowGroupInvites,
    };
  }

  CommunityProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    double? height,
    double? weight,
    String? goal,
    double? dailyTarget,
    int? totalPoints,
    int? level,
    ProfileVisibility? profileVisibility,
    bool? showStatsPublicly,
  }) {
    return CommunityProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      bmr: bmr,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      country: country,
      language: language,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      challengesCompleted: challengesCompleted,
      followersCount: followersCount,
      followingCount: followingCount,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showStatsPublicly: showStatsPublicly ?? this.showStatsPublicly,
      allowChallengeInvites: allowChallengeInvites,
      allowGroupInvites: allowGroupInvites,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

enum ProfileVisibility {
  public,
  friends,
  private;

  String get label {
    switch (this) {
      case ProfileVisibility.public:
        return 'Công khai';
      case ProfileVisibility.friends:
        return 'Bạn bè';
      case ProfileVisibility.private:
        return 'Riêng tư';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileVisibility.public:
        return Icons.public;
      case ProfileVisibility.friends:
        return Icons.people;
      case ProfileVisibility.private:
        return Icons.lock;
    }
  }

  static ProfileVisibility fromString(String value) {
    switch (value) {
      case 'friends':
        return ProfileVisibility.friends;
      case 'private':
        return ProfileVisibility.private;
      default:
        return ProfileVisibility.public;
    }
  }
}
