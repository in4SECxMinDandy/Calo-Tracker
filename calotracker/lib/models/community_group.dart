// Group Model
// Community groups for shared goals
import 'package:flutter/material.dart';

class CommunityGroup {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final GroupCategory category;
  final GroupVisibility visibility;
  final int? maxMembers;
  final bool requireApproval;
  final String createdBy;
  final int memberCount;
  final int postCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Loaded relations
  final GroupMemberRole? currentUserRole;

  bool get isPublic => visibility == GroupVisibility.public;
  bool get isFull => maxMembers != null && memberCount >= maxMembers!;

  const CommunityGroup({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.category = GroupCategory.general,
    this.visibility = GroupVisibility.public,
    this.maxMembers,
    this.requireApproval = false,
    required this.createdBy,
    this.memberCount = 0,
    this.postCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.currentUserRole,
  });

  factory CommunityGroup.fromJson(Map<String, dynamic> json) {
    return CommunityGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      category: GroupCategory.fromString(
        json['category'] as String? ?? 'general',
      ),
      visibility: GroupVisibility.fromString(
        json['visibility'] as String? ?? 'public',
      ),
      maxMembers: json['max_members'] as int?,
      requireApproval: json['require_approval'] as bool? ?? false,
      createdBy: json['created_by'] as String,
      memberCount: json['member_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'cover_image_url': coverImageUrl,
      'category': category.dbValue, // Use snake_case for DB
      'visibility': visibility.name,
      'max_members': maxMembers,
      'require_approval': requireApproval,
      'created_by': createdBy,
    };
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final GroupMemberRole role;
  final GroupMemberStatus status;
  final DateTime joinedAt;

  // Loaded profile
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = GroupMemberRole.member,
    this.status = GroupMemberStatus.active,
    required this.joinedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: GroupMemberRole.fromString(json['role'] as String? ?? 'member'),
      status: GroupMemberStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}

enum GroupCategory {
  weightLoss,
  muscleGain,
  healthyEating,
  running,
  fitness,
  general;

  String get label {
    switch (this) {
      case GroupCategory.weightLoss:
        return 'Giảm cân';
      case GroupCategory.muscleGain:
        return 'Tăng cơ';
      case GroupCategory.healthyEating:
        return 'Ăn uống lành mạnh';
      case GroupCategory.running:
        return 'Chạy bộ';
      case GroupCategory.fitness:
        return 'Thể hình';
      case GroupCategory.general:
        return 'Chung';
    }
  }

  // Convert to snake_case for database
  String get dbValue {
    switch (this) {
      case GroupCategory.weightLoss:
        return 'weight_loss';
      case GroupCategory.muscleGain:
        return 'muscle_gain';
      case GroupCategory.healthyEating:
        return 'healthy_eating';
      case GroupCategory.running:
        return 'running';
      case GroupCategory.fitness:
        return 'fitness';
      case GroupCategory.general:
        return 'general';
    }
  }

  // Parse from snake_case database value
  static GroupCategory fromDbValue(String value) {
    switch (value) {
      case 'weight_loss':
        return GroupCategory.weightLoss;
      case 'muscle_gain':
        return GroupCategory.muscleGain;
      case 'healthy_eating':
        return GroupCategory.healthyEating;
      case 'running':
        return GroupCategory.running;
      case 'fitness':
        return GroupCategory.fitness;
      case 'general':
      default:
        return GroupCategory.general;
    }
  }

  IconData get icon {
    switch (this) {
      case GroupCategory.weightLoss:
        return Icons.trending_down;
      case GroupCategory.muscleGain:
        return Icons.fitness_center;
      case GroupCategory.healthyEating:
        return Icons.restaurant;
      case GroupCategory.running:
        return Icons.directions_run;
      case GroupCategory.fitness:
        return Icons.sports_gymnastics;
      case GroupCategory.general:
        return Icons.group;
    }
  }

  Color get color {
    switch (this) {
      case GroupCategory.weightLoss:
        return Colors.orange;
      case GroupCategory.muscleGain:
        return Colors.red;
      case GroupCategory.healthyEating:
        return Colors.green;
      case GroupCategory.running:
        return Colors.blue;
      case GroupCategory.fitness:
        return Colors.purple;
      case GroupCategory.general:
        return Colors.grey;
    }
  }

  static GroupCategory fromString(String value) {
    switch (value) {
      case 'weight_loss':
        return GroupCategory.weightLoss;
      case 'muscle_gain':
        return GroupCategory.muscleGain;
      case 'healthy_eating':
        return GroupCategory.healthyEating;
      case 'running':
        return GroupCategory.running;
      case 'fitness':
        return GroupCategory.fitness;
      default:
        return GroupCategory.general;
    }
  }
}

enum GroupVisibility {
  public,
  private,
  inviteOnly;

  String get label {
    switch (this) {
      case GroupVisibility.public:
        return 'Công khai';
      case GroupVisibility.private:
        return 'Riêng tư';
      case GroupVisibility.inviteOnly:
        return 'Chỉ mời';
    }
  }

  IconData get icon {
    switch (this) {
      case GroupVisibility.public:
        return Icons.public;
      case GroupVisibility.private:
        return Icons.lock;
      case GroupVisibility.inviteOnly:
        return Icons.mail;
    }
  }

  static GroupVisibility fromString(String value) {
    switch (value) {
      case 'private':
        return GroupVisibility.private;
      case 'invite_only':
        return GroupVisibility.inviteOnly;
      default:
        return GroupVisibility.public;
    }
  }
}

enum GroupMemberRole {
  owner,
  admin,
  moderator,
  member;

  String get label {
    switch (this) {
      case GroupMemberRole.owner:
        return 'Chủ nhóm';
      case GroupMemberRole.admin:
        return 'Quản trị viên';
      case GroupMemberRole.moderator:
        return 'Điều hành viên';
      case GroupMemberRole.member:
        return 'Thành viên';
    }
  }

  Color get color {
    switch (this) {
      case GroupMemberRole.owner:
        return Colors.amber;
      case GroupMemberRole.admin:
        return Colors.red;
      case GroupMemberRole.moderator:
        return Colors.blue;
      case GroupMemberRole.member:
        return Colors.grey;
    }
  }

  bool get canManageMembers => this == owner || this == admin;
  bool get canModerate => this != member;
  bool get canEditGroup => this == owner || this == admin;

  static GroupMemberRole fromString(String value) {
    switch (value) {
      case 'owner':
        return GroupMemberRole.owner;
      case 'admin':
        return GroupMemberRole.admin;
      case 'moderator':
        return GroupMemberRole.moderator;
      default:
        return GroupMemberRole.member;
    }
  }
}

enum GroupMemberStatus {
  active,
  pending,
  banned;

  static GroupMemberStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return GroupMemberStatus.pending;
      case 'banned':
        return GroupMemberStatus.banned;
      default:
        return GroupMemberStatus.active;
    }
  }
}
