// Challenge Model
// Community challenges for groups
import 'package:flutter/material.dart';

class Challenge {
  final String id;
  final String? groupId;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final ChallengeType challengeType;
  final double targetValue;
  final String targetUnit;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final String? badgeName;
  final String? badgeIcon;
  final ChallengeVisibility visibility;
  final ChallengeStatus status;
  final String createdBy;
  final int participantCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // User participation data (if joined)
  final ChallengeParticipant? myProgress;

  // Computed properties
  bool get isActive => status == ChallengeStatus.active;
  bool get isUpcoming => status == ChallengeStatus.upcoming;
  bool get isCompleted => status == ChallengeStatus.completed;
  bool get hasJoined => myProgress != null;

  Duration get duration => endDate.difference(startDate);
  Duration get remainingTime => endDate.difference(DateTime.now());
  double get progressPercentage =>
      hasJoined
          ? (myProgress!.currentValue / targetValue * 100).clamp(0, 100)
          : 0;

  const Challenge({
    required this.id,
    this.groupId,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.challengeType,
    required this.targetValue,
    required this.targetUnit,
    required this.startDate,
    required this.endDate,
    this.pointsReward = 100,
    this.badgeName,
    this.badgeIcon,
    this.visibility = ChallengeVisibility.public,
    this.status = ChallengeStatus.upcoming,
    required this.createdBy,
    this.participantCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.myProgress,
  });

  factory Challenge.fromJson(
    Map<String, dynamic> json, {
    ChallengeParticipant? myProgress,
  }) {
    return Challenge(
      id: json['id'] as String,
      groupId: json['group_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      challengeType: ChallengeType.fromString(json['challenge_type'] as String),
      targetValue: (json['target_value'] as num).toDouble(),
      targetUnit: json['target_unit'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      pointsReward: json['points_reward'] as int? ?? 100,
      badgeName: json['badge_name'] as String?,
      badgeIcon: json['badge_icon'] as String?,
      visibility: ChallengeVisibility.fromString(
        json['visibility'] as String? ?? 'public',
      ),
      status: ChallengeStatus.fromString(
        json['status'] as String? ?? 'upcoming',
      ),
      createdBy: json['created_by'] as String,
      participantCount: json['participant_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      myProgress: myProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'challenge_type': challengeType.value,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'points_reward': pointsReward,
      'badge_name': badgeName,
      'badge_icon': badgeIcon,
      'visibility': visibility.name,
      'status': status.name,
      'created_by': createdBy,
    };
  }
}

class ChallengeParticipant {
  final String id;
  final String challengeId;
  final String userId;
  final double currentValue;
  final List<DailyProgress> dailyProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? rank;
  final DateTime joinedAt;
  final DateTime updatedAt;

  // Loaded profile
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.currentValue = 0,
    this.dailyProgress = const [],
    this.isCompleted = false,
    this.completedAt,
    this.rank,
    required this.joinedAt,
    required this.updatedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final dailyProgressJson = json['daily_progress'] as List?;

    return ChallengeParticipant(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
      dailyProgress:
          dailyProgressJson
              ?.map((d) => DailyProgress.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null,
      rank: json['rank'] as int?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}

class DailyProgress {
  final DateTime date;
  final double value;

  const DailyProgress({required this.date, required this.value});

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String().split('T').first,
    'value': value,
  };
}

enum ChallengeType {
  caloriesBurned,
  caloriesIntake,
  steps,
  waterIntake,
  sleepHours,
  workoutsCompleted,
  weightLoss,
  weightGain,
  streak,
  mealsLogged;

  String get value {
    switch (this) {
      case ChallengeType.caloriesBurned:
        return 'calories_burned';
      case ChallengeType.caloriesIntake:
        return 'calories_intake';
      case ChallengeType.steps:
        return 'steps';
      case ChallengeType.waterIntake:
        return 'water_intake';
      case ChallengeType.sleepHours:
        return 'sleep_hours';
      case ChallengeType.workoutsCompleted:
        return 'workouts_completed';
      case ChallengeType.weightLoss:
        return 'weight_loss';
      case ChallengeType.weightGain:
        return 'weight_gain';
      case ChallengeType.streak:
        return 'streak';
      case ChallengeType.mealsLogged:
        return 'meals_logged';
    }
  }

  String get label {
    switch (this) {
      case ChallengeType.caloriesBurned:
        return 'Đốt cháy calo';
      case ChallengeType.caloriesIntake:
        return 'Nạp đủ calo';
      case ChallengeType.steps:
        return 'Số bước chân';
      case ChallengeType.waterIntake:
        return 'Uống nước';
      case ChallengeType.sleepHours:
        return 'Giờ ngủ';
      case ChallengeType.workoutsCompleted:
        return 'Buổi tập';
      case ChallengeType.weightLoss:
        return 'Giảm cân';
      case ChallengeType.weightGain:
        return 'Tăng cân';
      case ChallengeType.streak:
        return 'Chuỗi ngày';
      case ChallengeType.mealsLogged:
        return 'Ghi bữa ăn';
    }
  }

  String get defaultUnit {
    switch (this) {
      case ChallengeType.caloriesBurned:
      case ChallengeType.caloriesIntake:
        return 'kcal';
      case ChallengeType.steps:
        return 'bước';
      case ChallengeType.waterIntake:
        return 'ml';
      case ChallengeType.sleepHours:
        return 'giờ';
      case ChallengeType.workoutsCompleted:
        return 'buổi';
      case ChallengeType.weightLoss:
      case ChallengeType.weightGain:
        return 'kg';
      case ChallengeType.streak:
        return 'ngày';
      case ChallengeType.mealsLogged:
        return 'bữa';
    }
  }

  IconData get icon {
    switch (this) {
      case ChallengeType.caloriesBurned:
        return Icons.local_fire_department;
      case ChallengeType.caloriesIntake:
        return Icons.restaurant;
      case ChallengeType.steps:
        return Icons.directions_walk;
      case ChallengeType.waterIntake:
        return Icons.water_drop;
      case ChallengeType.sleepHours:
        return Icons.bedtime;
      case ChallengeType.workoutsCompleted:
        return Icons.fitness_center;
      case ChallengeType.weightLoss:
        return Icons.trending_down;
      case ChallengeType.weightGain:
        return Icons.trending_up;
      case ChallengeType.streak:
        return Icons.whatshot;
      case ChallengeType.mealsLogged:
        return Icons.menu_book;
    }
  }

  Color get color {
    switch (this) {
      case ChallengeType.caloriesBurned:
        return Colors.orange;
      case ChallengeType.caloriesIntake:
        return Colors.green;
      case ChallengeType.steps:
        return Colors.blue;
      case ChallengeType.waterIntake:
        return Colors.cyan;
      case ChallengeType.sleepHours:
        return Colors.indigo;
      case ChallengeType.workoutsCompleted:
        return Colors.red;
      case ChallengeType.weightLoss:
        return Colors.teal;
      case ChallengeType.weightGain:
        return Colors.purple;
      case ChallengeType.streak:
        return Colors.deepOrange;
      case ChallengeType.mealsLogged:
        return Colors.brown;
    }
  }

  static ChallengeType fromString(String value) {
    switch (value) {
      case 'calories_burned':
        return ChallengeType.caloriesBurned;
      case 'calories_intake':
        return ChallengeType.caloriesIntake;
      case 'steps':
        return ChallengeType.steps;
      case 'water_intake':
        return ChallengeType.waterIntake;
      case 'sleep_hours':
        return ChallengeType.sleepHours;
      case 'workouts_completed':
        return ChallengeType.workoutsCompleted;
      case 'weight_loss':
        return ChallengeType.weightLoss;
      case 'weight_gain':
        return ChallengeType.weightGain;
      case 'streak':
        return ChallengeType.streak;
      case 'meals_logged':
        return ChallengeType.mealsLogged;
      default:
        return ChallengeType.caloriesBurned;
    }
  }
}

enum ChallengeVisibility {
  public,
  group,
  inviteOnly;

  String get label {
    switch (this) {
      case ChallengeVisibility.public:
        return 'Công khai';
      case ChallengeVisibility.group:
        return 'Nhóm';
      case ChallengeVisibility.inviteOnly:
        return 'Chỉ mời';
    }
  }

  static ChallengeVisibility fromString(String value) {
    switch (value) {
      case 'group':
        return ChallengeVisibility.group;
      case 'invite_only':
        return ChallengeVisibility.inviteOnly;
      default:
        return ChallengeVisibility.public;
    }
  }
}

enum ChallengeStatus {
  draft,
  upcoming,
  active,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case ChallengeStatus.draft:
        return 'Bản nháp';
      case ChallengeStatus.upcoming:
        return 'Sắp diễn ra';
      case ChallengeStatus.active:
        return 'Đang diễn ra';
      case ChallengeStatus.completed:
        return 'Đã kết thúc';
      case ChallengeStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color get color {
    switch (this) {
      case ChallengeStatus.draft:
        return Colors.grey;
      case ChallengeStatus.upcoming:
        return Colors.blue;
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.completed:
        return Colors.purple;
      case ChallengeStatus.cancelled:
        return Colors.red;
    }
  }

  static ChallengeStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return ChallengeStatus.draft;
      case 'upcoming':
        return ChallengeStatus.upcoming;
      case 'active':
        return ChallengeStatus.active;
      case 'completed':
        return ChallengeStatus.completed;
      case 'cancelled':
        return ChallengeStatus.cancelled;
      default:
        return ChallengeStatus.upcoming;
    }
  }
}
