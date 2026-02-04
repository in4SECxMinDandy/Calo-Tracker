// Achievement Model
// Defines badges, achievements and gamification elements
import 'package:flutter/material.dart';

/// Achievement types
enum AchievementType {
  streak,      // Consecutive days
  calorie,     // Calorie tracking
  water,       // Water intake
  workout,     // Workout completion
  weight,      // Weight tracking
  social,      // Sharing/community
  milestone,   // General milestones
}

/// Achievement definition
class Achievement {
  final String id;
  final String titleKey;      // Localization key
  final String descriptionKey;
  final String icon;
  final AchievementType type;
  final int requirement;      // Number needed to unlock
  final int points;           // XP points awarded
  final Color color;
  final bool isSecret;        // Hidden until unlocked

  const Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.type,
    required this.requirement,
    required this.points,
    required this.color,
    this.isSecret = false,
  });

  /// Get all available achievements
  static List<Achievement> get all => [
    // Streak achievements
    const Achievement(
      id: 'streak_3',
      titleKey: 'achievementStreak3',
      descriptionKey: 'achievementStreak3Desc',
      icon: '🔥',
      type: AchievementType.streak,
      requirement: 3,
      points: 50,
      color: Colors.orange,
    ),
    const Achievement(
      id: 'streak_7',
      titleKey: 'achievementStreak7',
      descriptionKey: 'achievementStreak7Desc',
      icon: '🔥',
      type: AchievementType.streak,
      requirement: 7,
      points: 100,
      color: Colors.orange,
    ),
    const Achievement(
      id: 'streak_14',
      titleKey: 'achievementStreak14',
      descriptionKey: 'achievementStreak14Desc',
      icon: '💪',
      type: AchievementType.streak,
      requirement: 14,
      points: 200,
      color: Colors.deepOrange,
    ),
    const Achievement(
      id: 'streak_30',
      titleKey: 'achievementStreak30',
      descriptionKey: 'achievementStreak30Desc',
      icon: '🏆',
      type: AchievementType.streak,
      requirement: 30,
      points: 500,
      color: Colors.amber,
    ),
    const Achievement(
      id: 'streak_100',
      titleKey: 'achievementStreak100',
      descriptionKey: 'achievementStreak100Desc',
      icon: '👑',
      type: AchievementType.streak,
      requirement: 100,
      points: 1000,
      color: Colors.purple,
      isSecret: true,
    ),

    // Calorie tracking achievements
    const Achievement(
      id: 'calorie_first',
      titleKey: 'achievementCalorieFirst',
      descriptionKey: 'achievementCalorieFirstDesc',
      icon: '🍎',
      type: AchievementType.calorie,
      requirement: 1,
      points: 10,
      color: Colors.green,
    ),
    const Achievement(
      id: 'calorie_10',
      titleKey: 'achievementCalorie10',
      descriptionKey: 'achievementCalorie10Desc',
      icon: '🥗',
      type: AchievementType.calorie,
      requirement: 10,
      points: 50,
      color: Colors.green,
    ),
    const Achievement(
      id: 'calorie_50',
      titleKey: 'achievementCalorie50',
      descriptionKey: 'achievementCalorie50Desc',
      icon: '🥑',
      type: AchievementType.calorie,
      requirement: 50,
      points: 150,
      color: Colors.teal,
    ),
    const Achievement(
      id: 'calorie_100',
      titleKey: 'achievementCalorie100',
      descriptionKey: 'achievementCalorie100Desc',
      icon: '🌟',
      type: AchievementType.calorie,
      requirement: 100,
      points: 300,
      color: Colors.amber,
    ),

    // Water intake achievements
    const Achievement(
      id: 'water_first',
      titleKey: 'achievementWaterFirst',
      descriptionKey: 'achievementWaterFirstDesc',
      icon: '💧',
      type: AchievementType.water,
      requirement: 1,
      points: 10,
      color: Colors.blue,
    ),
    const Achievement(
      id: 'water_7',
      titleKey: 'achievementWater7',
      descriptionKey: 'achievementWater7Desc',
      icon: '💦',
      type: AchievementType.water,
      requirement: 7,
      points: 100,
      color: Colors.blue,
    ),
    const Achievement(
      id: 'water_30',
      titleKey: 'achievementWater30',
      descriptionKey: 'achievementWater30Desc',
      icon: '🌊',
      type: AchievementType.water,
      requirement: 30,
      points: 300,
      color: Colors.cyan,
    ),

    // Workout achievements
    const Achievement(
      id: 'workout_first',
      titleKey: 'achievementWorkoutFirst',
      descriptionKey: 'achievementWorkoutFirstDesc',
      icon: '🏃',
      type: AchievementType.workout,
      requirement: 1,
      points: 20,
      color: Colors.red,
    ),
    const Achievement(
      id: 'workout_10',
      titleKey: 'achievementWorkout10',
      descriptionKey: 'achievementWorkout10Desc',
      icon: '💪',
      type: AchievementType.workout,
      requirement: 10,
      points: 100,
      color: Colors.red,
    ),
    const Achievement(
      id: 'workout_50',
      titleKey: 'achievementWorkout50',
      descriptionKey: 'achievementWorkout50Desc',
      icon: '🏋️',
      type: AchievementType.workout,
      requirement: 50,
      points: 300,
      color: Colors.deepOrange,
    ),

    // Weight tracking achievements
    const Achievement(
      id: 'weight_first',
      titleKey: 'achievementWeightFirst',
      descriptionKey: 'achievementWeightFirstDesc',
      icon: '⚖️',
      type: AchievementType.weight,
      requirement: 1,
      points: 10,
      color: Colors.purple,
    ),
    const Achievement(
      id: 'weight_goal',
      titleKey: 'achievementWeightGoal',
      descriptionKey: 'achievementWeightGoalDesc',
      icon: '🎯',
      type: AchievementType.weight,
      requirement: 1,
      points: 500,
      color: Colors.amber,
    ),

    // Milestone achievements
    const Achievement(
      id: 'early_bird',
      titleKey: 'achievementEarlyBird',
      descriptionKey: 'achievementEarlyBirdDesc',
      icon: '🌅',
      type: AchievementType.milestone,
      requirement: 1,
      points: 50,
      color: Colors.amber,
    ),
    const Achievement(
      id: 'night_owl',
      titleKey: 'achievementNightOwl',
      descriptionKey: 'achievementNightOwlDesc',
      icon: '🦉',
      type: AchievementType.milestone,
      requirement: 1,
      points: 50,
      color: Colors.indigo,
      isSecret: true,
    ),
  ];

  /// Get achievement by ID
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// User achievement progress
class UserAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final int progressValue;

  UserAchievement({
    required this.achievementId,
    required this.unlockedAt,
    required this.progressValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.millisecondsSinceEpoch,
      'progress_value': progressValue,
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      achievementId: map['achievement_id'] as String,
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(map['unlocked_at'] as int),
      progressValue: map['progress_value'] as int,
    );
  }

  Achievement? get achievement => Achievement.getById(achievementId);
}

/// User level based on XP
class UserLevel {
  final int level;
  final int currentXP;
  final int xpForNextLevel;
  final String title;

  UserLevel({
    required this.level,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.title,
  });

  double get progress {
    if (xpForNextLevel == 0) return 1.0;
    final xpInLevel = currentXP - _xpForLevel(level);
    final xpNeeded = xpForNextLevel - _xpForLevel(level);
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }

  int get xpToNextLevel => xpForNextLevel - currentXP;

  /// Calculate level from XP
  static UserLevel fromXP(int totalXP) {
    int level = 1;
    while (_xpForLevel(level + 1) <= totalXP) {
      level++;
    }

    return UserLevel(
      level: level,
      currentXP: totalXP,
      xpForNextLevel: _xpForLevel(level + 1),
      title: _titleForLevel(level),
    );
  }

  /// XP required for a level (exponential growth)
  static int _xpForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * 100 * (1 + (level - 1) * 0.1)).round();
  }

  /// Title for level
  static String _titleForLevel(int level) {
    if (level < 5) return 'levelBeginner';
    if (level < 10) return 'levelNovice';
    if (level < 20) return 'levelIntermediate';
    if (level < 35) return 'levelAdvanced';
    if (level < 50) return 'levelExpert';
    if (level < 75) return 'levelMaster';
    return 'levelLegend';
  }
}
