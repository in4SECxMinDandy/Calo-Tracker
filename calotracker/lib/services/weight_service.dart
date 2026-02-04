// Weight Service
// Business logic for weight tracking and BMI calculations
import '../models/weight_record.dart';
import 'database_service.dart';
import 'storage_service.dart';

class WeightService {
  // Storage key for goal weight
  static const String _keyGoalWeight = 'goal_weight';

  /// Get goal weight
  static double? getGoalWeight() {
    final value = StorageService.prefs.getDouble(_keyGoalWeight);
    return value;
  }

  /// Set goal weight
  static Future<bool> setGoalWeight(double weightKg) async {
    return await StorageService.prefs.setDouble(_keyGoalWeight, weightKg);
  }

  /// Add weight record
  static Future<void> addWeightRecord(double weightKg, {String? note}) async {
    final record = WeightRecord(
      dateTime: DateTime.now(),
      weight: weightKg,
      note: note,
    );
    await DatabaseService.insertWeightRecord(record);

    // Update user profile with new weight
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(weight: weightKg);
      await StorageService.saveUserProfile(updatedProfile);
      await DatabaseService.saveUser(updatedProfile);
    }
  }

  /// Get latest weight record
  static Future<WeightRecord?> getLatestWeight() async {
    return await DatabaseService.getLatestWeightRecord();
  }

  /// Get weight progress
  static Future<WeightProgress> getWeightProgress() async {
    final history = await DatabaseService.getAllWeightRecords();
    final profile = StorageService.getUserProfile();
    final goalWeight = getGoalWeight();

    if (history.isEmpty) {
      return WeightProgress(
        history: [],
        startWeight: profile?.weight,
        currentWeight: profile?.weight,
        goalWeight: goalWeight,
      );
    }

    // Sort by date (newest first)
    history.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final latestRecord = history.first;
    final previousRecord = history.length > 1 ? history[1] : null;
    final firstRecord = history.last;

    return WeightProgress(
      latestRecord: latestRecord,
      previousRecord: previousRecord,
      firstRecord: firstRecord,
      startWeight: firstRecord.weight,
      currentWeight: latestRecord.weight,
      goalWeight: goalWeight,
      history: history,
    );
  }

  /// Get weight history for chart (last N days)
  static Future<List<WeightRecord>> getWeightHistory({int days = 30}) async {
    final records = await DatabaseService.getAllWeightRecords();
    final cutoff = DateTime.now().subtract(Duration(days: days));

    return records
        .where((r) => r.dateTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Get weight records for date range
  static Future<List<WeightRecord>> getWeightRecordsRange(
    DateTime start,
    DateTime end,
  ) async {
    return await DatabaseService.getWeightRecordsRange(start, end);
  }

  /// Delete weight record
  static Future<void> deleteWeightRecord(String id) async {
    await DatabaseService.deleteWeightRecord(id);
  }

  /// Calculate current BMI
  static double? getCurrentBMI() {
    final profile = StorageService.getUserProfile();
    if (profile == null) return null;
    return BMICalculator.calculate(profile.weight, profile.height);
  }

  /// Get BMI from weight and user height
  static double? getBMIForWeight(double weight) {
    final profile = StorageService.getUserProfile();
    if (profile == null) return null;
    return BMICalculator.calculate(weight, profile.height);
  }

  /// Get weight statistics
  static Future<Map<String, dynamic>> getWeightStats() async {
    final progress = await getWeightProgress();
    final profile = StorageService.getUserProfile();

    double? bmi;
    String? bmiCategory;
    Map<String, double>? healthyRange;

    if (profile != null && progress.currentWeight != null) {
      bmi = BMICalculator.calculate(progress.currentWeight!, profile.height);
      bmiCategory = BMICalculator.getCategory(bmi);
      healthyRange = BMICalculator.getHealthyWeightRange(profile.height);
    }

    // Calculate average weekly change
    double? weeklyChange;
    if (progress.history.length >= 2) {
      final sortedHistory = List<WeightRecord>.from(progress.history)
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final firstDate = sortedHistory.first.dateTime;
      final lastDate = sortedHistory.last.dateTime;
      final daysDiff = lastDate.difference(firstDate).inDays;

      if (daysDiff > 0) {
        final totalChange =
            sortedHistory.last.weight - sortedHistory.first.weight;
        weeklyChange = (totalChange / daysDiff) * 7;
      }
    }

    return {
      'progress': progress,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'healthyRange': healthyRange,
      'weeklyChange': weeklyChange,
      'totalRecords': progress.history.length,
    };
  }

  /// Calculate ideal weight based on height (using Devine formula)
  static Map<String, double> calculateIdealWeight(
    double heightCm,
    String gender,
  ) {
    // Devine formula
    double idealWeight;
    if (gender == 'male') {
      idealWeight = 50 + 2.3 * ((heightCm / 2.54) - 60);
    } else {
      idealWeight = 45.5 + 2.3 * ((heightCm / 2.54) - 60);
    }

    // Range is typically ±10%
    return {
      'ideal': idealWeight,
      'min': idealWeight * 0.9,
      'max': idealWeight * 1.1,
    };
  }
}
