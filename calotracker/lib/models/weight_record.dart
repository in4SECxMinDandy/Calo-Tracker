// Weight Record Model
// Stores weight entries for progress tracking
import 'package:uuid/uuid.dart';

class WeightRecord {
  final String id;
  final DateTime dateTime;
  final double weight; // in kg
  final String? note;

  WeightRecord({
    String? id,
    required this.dateTime,
    required this.weight,
    this.note,
  }) : id = id ?? const Uuid().v4();

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_time': dateTime.millisecondsSinceEpoch,
      'weight': weight,
      'note': note,
    };
  }

  /// Create from database Map
  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      weight: (map['weight'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }

  /// Create copy with modifications
  WeightRecord copyWith({
    String? id,
    DateTime? dateTime,
    double? weight,
    String? note,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }

  /// Get date string (YYYY-MM-DD) for grouping
  String get dateStr {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'WeightRecord(id: $id, weight: ${weight}kg, dateTime: $dateTime)';
  }
}

/// Weight progress statistics
class WeightProgress {
  final WeightRecord? latestRecord;
  final WeightRecord? previousRecord;
  final WeightRecord? firstRecord;
  final double? startWeight;
  final double? currentWeight;
  final double? goalWeight;
  final List<WeightRecord> history;

  WeightProgress({
    this.latestRecord,
    this.previousRecord,
    this.firstRecord,
    this.startWeight,
    this.currentWeight,
    this.goalWeight,
    required this.history,
  });

  /// Weight change from previous record
  double? get changeFromPrevious {
    if (latestRecord == null || previousRecord == null) return null;
    return latestRecord!.weight - previousRecord!.weight;
  }

  /// Total weight change from start
  double? get totalChange {
    if (currentWeight == null || startWeight == null) return null;
    return currentWeight! - startWeight!;
  }

  /// Progress towards goal (percentage)
  double? get goalProgress {
    if (startWeight == null || currentWeight == null || goalWeight == null) {
      return null;
    }
    final totalToLose = startWeight! - goalWeight!;
    if (totalToLose == 0) return 100;
    final lost = startWeight! - currentWeight!;
    return (lost / totalToLose * 100).clamp(0, 100);
  }

  /// Remaining weight to goal
  double? get remainingToGoal {
    if (currentWeight == null || goalWeight == null) return null;
    return (currentWeight! - goalWeight!).abs();
  }

  /// Trend direction
  WeightTrend get trend {
    final change = changeFromPrevious;
    if (change == null) return WeightTrend.stable;
    if (change > 0.1) return WeightTrend.up;
    if (change < -0.1) return WeightTrend.down;
    return WeightTrend.stable;
  }

  /// Create empty progress
  factory WeightProgress.empty() {
    return WeightProgress(history: []);
  }
}

/// Weight trend enum
enum WeightTrend { up, down, stable }

/// BMI calculation helper
class BMICalculator {
  /// Calculate BMI from weight (kg) and height (cm)
  static double calculate(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI category
  static String getCategory(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  /// Get BMI category display name (Vietnamese)
  static String getCategoryNameVi(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  /// Get BMI category display name (English)
  static String getCategoryNameEn(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get healthy weight range for a given height
  static Map<String, double> getHealthyWeightRange(double heightCm) {
    final heightM = heightCm / 100;
    return {
      'min': 18.5 * heightM * heightM,
      'max': 24.9 * heightM * heightM,
    };
  }
}
