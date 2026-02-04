// Insights Data Models
// Models for analytics dashboard and reporting features

/// Weekly calorie and nutrition summary
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalCaloriesIntake;
  final double totalCaloriesBurned;
  final double avgDailyIntake;
  final double avgDailyBurned;
  final int daysTracked;
  final int mealsLogged;
  final int workoutsCompleted;
  final double targetAdherence; // Percentage of days meeting target
  final double bestDay; // Highest calories burned
  final String bestDayName;
  final MacroDistribution avgMacros;

  WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalCaloriesIntake,
    required this.totalCaloriesBurned,
    required this.avgDailyIntake,
    required this.avgDailyBurned,
    required this.daysTracked,
    required this.mealsLogged,
    required this.workoutsCompleted,
    required this.targetAdherence,
    required this.bestDay,
    required this.bestDayName,
    required this.avgMacros,
  });

  /// Create empty report for a week
  factory WeeklyReport.empty(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalCaloriesIntake: 0,
      totalCaloriesBurned: 0,
      avgDailyIntake: 0,
      avgDailyBurned: 0,
      daysTracked: 0,
      mealsLogged: 0,
      workoutsCompleted: 0,
      targetAdherence: 0,
      bestDay: 0,
      bestDayName: '',
      avgMacros: MacroDistribution.empty(),
    );
  }

  /// Get net calories (intake - burned)
  double get netCalories => totalCaloriesIntake - totalCaloriesBurned;

  /// Get week number of the year
  int get weekNumber {
    final firstDayOfYear = DateTime(weekStart.year, 1, 1);
    final days = weekStart.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Format date range for display
  String get dateRangeStr {
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';
  }

  Map<String, dynamic> toMap() {
    return {
      'week_start': weekStart.millisecondsSinceEpoch,
      'week_end': weekEnd.millisecondsSinceEpoch,
      'total_intake': totalCaloriesIntake,
      'total_burned': totalCaloriesBurned,
      'avg_daily_intake': avgDailyIntake,
      'avg_daily_burned': avgDailyBurned,
      'days_tracked': daysTracked,
      'meals_logged': mealsLogged,
      'workouts_completed': workoutsCompleted,
      'target_adherence': targetAdherence,
      'best_day': bestDay,
      'best_day_name': bestDayName,
      'avg_macros': avgMacros.toMap(),
    };
  }
}

/// Monthly insights with trends
class MonthlyInsight {
  final int year;
  final int month;
  final double totalCaloriesIntake;
  final double totalCaloriesBurned;
  final double avgDailyIntake;
  final double avgDailyBurned;
  final int daysTracked;
  final int totalMeals;
  final int totalWorkouts;
  final double targetAdherence;
  final TrendDirection calorieTrend;
  final TrendDirection workoutTrend;
  final List<WeeklyReport> weeklyBreakdown;
  final MacroDistribution avgMacros;

  MonthlyInsight({
    required this.year,
    required this.month,
    required this.totalCaloriesIntake,
    required this.totalCaloriesBurned,
    required this.avgDailyIntake,
    required this.avgDailyBurned,
    required this.daysTracked,
    required this.totalMeals,
    required this.totalWorkouts,
    required this.targetAdherence,
    required this.calorieTrend,
    required this.workoutTrend,
    required this.weeklyBreakdown,
    required this.avgMacros,
  });

  /// Get month name in Vietnamese
  String get monthName {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[month - 1];
  }

  /// Get net calories
  double get netCalories => totalCaloriesIntake - totalCaloriesBurned;

  /// Create empty monthly insight
  factory MonthlyInsight.empty(int year, int month) {
    return MonthlyInsight(
      year: year,
      month: month,
      totalCaloriesIntake: 0,
      totalCaloriesBurned: 0,
      avgDailyIntake: 0,
      avgDailyBurned: 0,
      daysTracked: 0,
      totalMeals: 0,
      totalWorkouts: 0,
      targetAdherence: 0,
      calorieTrend: TrendDirection.stable,
      workoutTrend: TrendDirection.stable,
      weeklyBreakdown: [],
      avgMacros: MacroDistribution.empty(),
    );
  }
}

/// Macro nutrient distribution
class MacroDistribution {
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams

  MacroDistribution({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Create empty distribution
  factory MacroDistribution.empty() {
    return MacroDistribution(protein: 0, carbs: 0, fat: 0);
  }

  /// Get total grams
  double get total => protein + carbs + fat;

  /// Get total calories from macros
  /// Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
  double get totalCalories => (protein * 4) + (carbs * 4) + (fat * 9);

  /// Get percentage breakdown
  Map<String, double> get percentages {
    if (total == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }
    return {
      'protein': (protein / total) * 100,
      'carbs': (carbs / total) * 100,
      'fat': (fat / total) * 100,
    };
  }

  /// Get calorie percentage breakdown
  Map<String, double> get caloriePercentages {
    if (totalCalories == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }
    return {
      'protein': ((protein * 4) / totalCalories) * 100,
      'carbs': ((carbs * 4) / totalCalories) * 100,
      'fat': ((fat * 9) / totalCalories) * 100,
    };
  }

  Map<String, dynamic> toMap() {
    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  factory MacroDistribution.fromMap(Map<String, dynamic> map) {
    return MacroDistribution(
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Combine multiple distributions (for averaging)
  static MacroDistribution combine(List<MacroDistribution> distributions) {
    if (distributions.isEmpty) return MacroDistribution.empty();

    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final dist in distributions) {
      totalProtein += dist.protein;
      totalCarbs += dist.carbs;
      totalFat += dist.fat;
    }

    return MacroDistribution(
      protein: totalProtein / distributions.length,
      carbs: totalCarbs / distributions.length,
      fat: totalFat / distributions.length,
    );
  }
}

/// Trend direction indicator
enum TrendDirection { up, down, stable }

/// Extension to get trend icon and color
extension TrendDirectionExt on TrendDirection {
  String get icon {
    switch (this) {
      case TrendDirection.up:
        return '↑';
      case TrendDirection.down:
        return '↓';
      case TrendDirection.stable:
        return '→';
    }
  }

  String get description {
    switch (this) {
      case TrendDirection.up:
        return 'Tăng';
      case TrendDirection.down:
        return 'Giảm';
      case TrendDirection.stable:
        return 'Ổn định';
    }
  }
}

/// Daily summary for charts
class DailySummary {
  final DateTime date;
  final double caloriesIntake;
  final double caloriesBurned;
  final double targetProgress; // Percentage
  final int mealsCount;
  final MacroDistribution macros;

  DailySummary({
    required this.date,
    required this.caloriesIntake,
    required this.caloriesBurned,
    required this.targetProgress,
    required this.mealsCount,
    required this.macros,
  });

  double get netCalories => caloriesIntake - caloriesBurned;

  String get dayName {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[date.weekday % 7];
  }

  String get dateStr {
    return '${date.day}/${date.month}';
  }
}

/// Export data container
class ExportData {
  final UserExportInfo userInfo;
  final List<DailySummary> dailyData;
  final WeeklyReport? weeklyReport;
  final MonthlyInsight? monthlyInsight;
  final DateTime exportedAt;
  final String exportFormat; // 'pdf' or 'csv'

  ExportData({
    required this.userInfo,
    required this.dailyData,
    this.weeklyReport,
    this.monthlyInsight,
    required this.exportedAt,
    required this.exportFormat,
  });
}

/// User info for export headers
class UserExportInfo {
  final String name;
  final double height;
  final double weight;
  final String goal;
  final double dailyTarget;

  UserExportInfo({
    required this.name,
    required this.height,
    required this.weight,
    required this.goal,
    required this.dailyTarget,
  });

  String get goalDisplayName {
    switch (goal) {
      case 'lose':
        return 'Giảm cân';
      case 'gain':
        return 'Tăng cân';
      case 'maintain':
      default:
        return 'Duy trì';
    }
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }
}
