// Workout Service
// Handles loading exercises and workout programs
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';

class WorkoutService {
  static List<Exercise>? _cachedExercises;
  static WorkoutProgram? _cachedProgram;

  /// Load all exercises from JSON
  static Future<List<Exercise>> loadExercises() async {
    if (_cachedExercises != null) return _cachedExercises!;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/exercises.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final exercisesJson = jsonData['exercises'] as List;

      _cachedExercises =
          exercisesJson.map((e) => Exercise.fromJson(e)).toList();

      return _cachedExercises!;
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      return [];
    }
  }

  /// Load workout program from JSON
  static Future<WorkoutProgram?> loadWorkoutProgram() async {
    if (_cachedProgram != null) return _cachedProgram;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/workout_program.json',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      _cachedProgram = WorkoutProgram.fromJson(jsonData);
      return _cachedProgram;
    } catch (e) {
      debugPrint('Error loading workout program: $e');
      return null;
    }
  }

  /// Get exercise by ID
  static Future<Exercise?> getExerciseById(String id) async {
    final exercises = await loadExercises();
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get exercises by category
  static Future<List<Exercise>> getExercisesByCategory(String category) async {
    final exercises = await loadExercises();
    return exercises.where((e) => e.category == category).toList();
  }

  /// Get exercises for a specific day
  static Future<List<Exercise>> getExercisesForDay(int dayOfWeek) async {
    final program = await loadWorkoutProgram();
    if (program == null) return [];

    final dayProgram = program.weeklySchedule[dayOfWeek];
    if (dayProgram == null) return [];

    final allExercises = await loadExercises();
    return allExercises
        .where((e) => dayProgram.exerciseIds.contains(e.id))
        .toList();
  }

  /// Calculate total calories for exercises
  static int calculateTotalCalories(List<Exercise> exercises) {
    return exercises.fold(0, (sum, ex) => sum + ex.totalCalories);
  }

  /// Get motivation quote based on week number
  static String getMotivationQuote(int weekNumber) {
    if (weekNumber <= 2) {
      return "Tại sao mình tập vậy? Mệt quá!\n→ BÌNH THƯỜNG! Cơ thể đang thích nghi.";
    } else if (weekNumber <= 4) {
      return "Vẫn chưa thấy giảm cân!\n→ KIÊN TRÌ! Mỡ giảm từ trong ra ngoài.";
    } else if (weekNumber <= 6) {
      return "Ồ, quần áo rộng hơn rồi!\n→ ĐÚNG HƯỚNG! Cơ thể đang thay đổi.";
    } else if (weekNumber <= 8) {
      return "Mọi người nhận xét mình khác đi!\n→ THÀNH CÔNG! Tiếp tục là được.";
    } else {
      return "Mình đã làm được!\n→ TỰ HÀO! Giờ là lúc duy trì và phát triển.";
    }
  }
}
