// Workout Progress Tracking Model
class WorkoutProgress {
  final String userId;
  final String programId;
  final DateTime startDate;
  final int currentWeek;
  final Map<String, DayProgress> completedDays; // date -> progress

  WorkoutProgress({
    required this.userId,
    required this.programId,
    required this.startDate,
    required this.currentWeek,
    required this.completedDays,
  });

  factory WorkoutProgress.fromJson(Map<String, dynamic> json) {
    final daysMap = <String, DayProgress>{};
    final days = json['completedDays'] as Map<String, dynamic>?;
    days?.forEach((key, value) {
      daysMap[key] = DayProgress.fromJson(value as Map<String, dynamic>);
    });

    return WorkoutProgress(
      userId: json['userId'] as String,
      programId: json['programId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      currentWeek: json['currentWeek'] as int,
      completedDays: daysMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'programId': programId,
    'startDate': startDate.toIso8601String(),
    'currentWeek': currentWeek,
    'completedDays': completedDays.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };

  int get totalDaysCompleted => completedDays.length;
  int get totalCaloriesBurned =>
      completedDays.values.fold(0, (sum, day) => sum + day.totalCaloriesBurned);
}

class DayProgress {
  final String date; // yyyy-MM-dd
  final int dayOfWeek;
  final List<ExerciseCompletion> exercises;
  final int totalCaloriesBurned;
  final DateTime completedAt;

  DayProgress({
    required this.date,
    required this.dayOfWeek,
    required this.exercises,
    required this.totalCaloriesBurned,
    required this.completedAt,
  });

  factory DayProgress.fromJson(Map<String, dynamic> json) => DayProgress(
    date: json['date'] as String,
    dayOfWeek: json['dayOfWeek'] as int,
    exercises:
        (json['exercises'] as List)
            .map((e) => ExerciseCompletion.fromJson(e as Map<String, dynamic>))
            .toList(),
    totalCaloriesBurned: json['totalCaloriesBurned'] as int,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'dayOfWeek': dayOfWeek,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'totalCaloriesBurned': totalCaloriesBurned,
    'completedAt': completedAt.toIso8601String(),
  };

  bool get isFullyCompleted => exercises.every((e) => e.fullyCompleted);
}

class ExerciseCompletion {
  final String exerciseId;
  final int setsCompleted;
  final int targetSets;

  ExerciseCompletion({
    required this.exerciseId,
    required this.setsCompleted,
    required this.targetSets,
  });

  factory ExerciseCompletion.fromJson(Map<String, dynamic> json) =>
      ExerciseCompletion(
        exerciseId: json['exerciseId'] as String,
        setsCompleted: json['setsCompleted'] as int,
        targetSets: json['targetSets'] as int,
      );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'setsCompleted': setsCompleted,
    'targetSets': targetSets,
  };

  bool get fullyCompleted => setsCompleted >= targetSets;
  double get completionPercentage =>
      (setsCompleted / targetSets * 100).clamp(0, 100);
}
