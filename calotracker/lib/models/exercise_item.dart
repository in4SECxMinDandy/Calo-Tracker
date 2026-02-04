// Exercise Item Model
// Data model for workout exercises with filtered categories
import 'package:flutter/material.dart';

/// Mức độ khó của bài tập
enum ExerciseDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case ExerciseDifficulty.easy:
        return 'Dễ';
      case ExerciseDifficulty.medium:
        return 'Trung bình';
      case ExerciseDifficulty.hard:
        return 'Khó';
    }
  }

  Color get color {
    switch (this) {
      case ExerciseDifficulty.easy:
        return const Color(0xFF4CAF50);
      case ExerciseDifficulty.medium:
        return const Color(0xFFFF9800);
      case ExerciseDifficulty.hard:
        return const Color(0xFFE53935);
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseDifficulty.easy:
        return Icons.star_outline;
      case ExerciseDifficulty.medium:
        return Icons.star_half;
      case ExerciseDifficulty.hard:
        return Icons.star;
    }
  }
}

/// Địa điểm tập luyện
enum ExerciseLocation {
  home,
  gym;

  String get label {
    switch (this) {
      case ExerciseLocation.home:
        return 'Tại nhà';
      case ExerciseLocation.gym:
        return 'Phòng gym';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseLocation.home:
        return Icons.home;
      case ExerciseLocation.gym:
        return Icons.fitness_center;
    }
  }

  Color get color {
    switch (this) {
      case ExerciseLocation.home:
        return const Color(0xFF2196F3);
      case ExerciseLocation.gym:
        return const Color(0xFF9C27B0);
    }
  }
}

/// Mục tiêu tập luyện
enum ExerciseGoal {
  weightLoss,
  muscleGain,
  maintain;

  String get label {
    switch (this) {
      case ExerciseGoal.weightLoss:
        return 'Giảm cân';
      case ExerciseGoal.muscleGain:
        return 'Tăng cơ';
      case ExerciseGoal.maintain:
        return 'Duy trì';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseGoal.weightLoss:
        return Icons.trending_down;
      case ExerciseGoal.muscleGain:
        return Icons.trending_up;
      case ExerciseGoal.maintain:
        return Icons.balance;
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case ExerciseGoal.weightLoss:
        return [const Color(0xFFE53935), const Color(0xFFFF5722)];
      case ExerciseGoal.muscleGain:
        return [const Color(0xFF1565C0), const Color(0xFF2196F3)];
      case ExerciseGoal.maintain:
        return [const Color(0xFF43A047), const Color(0xFF66BB6A)];
    }
  }
}

/// Model cho một bài tập
class ExerciseItem {
  final String id;
  final String name;
  final String description;
  final String muscleGroup; // Nhóm cơ chính
  final int durationMinutes; // Thời lượng gợi ý
  final int sets; // Số hiệp
  final int reps; // Số lần lặp mỗi hiệp
  final ExerciseDifficulty difficulty;
  final ExerciseLocation location;
  final ExerciseGoal goal;
  final String youtubeUrl; // Link YouTube hướng dẫn
  final String thumbnailUrl; // Thumbnail
  final int caloriesPerSet; // Calo đốt/hiệp

  const ExerciseItem({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.durationMinutes,
    required this.sets,
    required this.reps,
    required this.difficulty,
    required this.location,
    required this.goal,
    required this.youtubeUrl,
    this.thumbnailUrl = '',
    this.caloriesPerSet = 10,
  });

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes phút';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}p' : '${hours}h';
  }

  String get setsRepsFormatted => '$sets hiệp × $reps lần';

  int get totalCalories => sets * caloriesPerSet;
}
