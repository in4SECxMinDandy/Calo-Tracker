// Insights Service
// Advanced analytics and statistics for nutrition & workout tracking
import '../models/insights_data.dart';
import '../models/calo_record.dart';
import '../models/meal.dart';
import '../models/gym_session.dart';
import 'database_service.dart';
import 'storage_service.dart';

class InsightsService {
  /// Get weekly report for a specific week
  /// [weekStart] should be a Monday
  static Future<WeeklyReport> getWeeklyReport(DateTime weekStart) async {
    // Normalize to start of week (Monday)
    final monday = weekStart.subtract(Duration(days: weekStart.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    // Get all data for the week
    final records = await DatabaseService.getCaloRecordsRange(monday, sunday);
    final meals = await _getMealsForRange(monday, sunday);
    final sessions = await _getGymSessionsForRange(monday, sunday);
    final userProfile = StorageService.getUserProfile();
    final dailyTarget = userProfile?.dailyTarget ?? 2000;

    // Calculate statistics
    double totalIntake = 0;
    double totalBurned = 0;
    int daysTracked = 0;
    int daysMetTarget = 0;
    double bestDayBurned = 0;
    String bestDayName = '';

    // Macro tracking
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    // Process records
    for (final record in records) {
      if (record.caloIntake > 0 || record.caloBurned > 0) {
        daysTracked++;
        totalIntake += record.caloIntake;
        totalBurned += record.caloBurned;

        // Check if met target
        if (record.caloIntake <= dailyTarget * 1.1 &&
            record.caloIntake >= dailyTarget * 0.8) {
          daysMetTarget++;
        }

        // Track best day
        if (record.caloBurned > bestDayBurned) {
          bestDayBurned = record.caloBurned;
          bestDayName = _getDayName(record.dateTime);
        }
      }
    }

    // Process meals for macros
    for (final meal in meals) {
      totalProtein += meal.protein ?? 0;
      totalCarbs += meal.carbs ?? 0;
      totalFat += meal.fat ?? 0;
    }

    // Calculate averages
    final avgDays = daysTracked > 0 ? daysTracked : 1;
    final avgIntake = totalIntake / avgDays;
    final avgBurned = totalBurned / avgDays;
    final targetAdherence =
        daysTracked > 0 ? (daysMetTarget / daysTracked) * 100 : 0.0;

    // Calculate average macros per day
    final avgMacros = MacroDistribution(
      protein: totalProtein / avgDays,
      carbs: totalCarbs / avgDays,
      fat: totalFat / avgDays,
    );

    return WeeklyReport(
      weekStart: monday,
      weekEnd: sunday,
      totalCaloriesIntake: totalIntake,
      totalCaloriesBurned: totalBurned,
      avgDailyIntake: avgIntake,
      avgDailyBurned: avgBurned,
      daysTracked: daysTracked,
      mealsLogged: meals.length,
      workoutsCompleted: sessions.where((s) => s.isCompleted).length,
      targetAdherence: targetAdherence,
      bestDay: bestDayBurned,
      bestDayName: bestDayName,
      avgMacros: avgMacros,
    );
  }

  /// Get monthly insight for a specific month
  static Future<MonthlyInsight> getMonthlyInsight(int year, int month) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0); // Last day of month

    // Get all data for the month
    final records = await DatabaseService.getCaloRecordsRange(
      firstDay,
      lastDay,
    );
    final meals = await _getMealsForRange(firstDay, lastDay);
    final sessions = await _getGymSessionsForRange(firstDay, lastDay);
    final userProfile = StorageService.getUserProfile();
    final dailyTarget = userProfile?.dailyTarget ?? 2000;

    // Calculate statistics
    double totalIntake = 0;
    double totalBurned = 0;
    int daysTracked = 0;
    int daysMetTarget = 0;

    // Macro tracking
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final record in records) {
      if (record.caloIntake > 0 || record.caloBurned > 0) {
        daysTracked++;
        totalIntake += record.caloIntake;
        totalBurned += record.caloBurned;

        if (record.caloIntake <= dailyTarget * 1.1 &&
            record.caloIntake >= dailyTarget * 0.8) {
          daysMetTarget++;
        }
      }
    }

    // Process meals for macros
    for (final meal in meals) {
      totalProtein += meal.protein ?? 0;
      totalCarbs += meal.carbs ?? 0;
      totalFat += meal.fat ?? 0;
    }

    // Calculate averages
    final avgDays = daysTracked > 0 ? daysTracked : 1;
    final avgIntake = totalIntake / avgDays;
    final avgBurned = totalBurned / avgDays;
    final targetAdherence =
        daysTracked > 0 ? (daysMetTarget / daysTracked) * 100 : 0.0;

    // Get weekly breakdown
    final weeklyBreakdown = await _getWeeklyBreakdownForMonth(year, month);

    // Calculate trends (compare with previous month)
    final calorieTrend = await _calculateCalorieTrend(year, month, avgIntake);
    final workoutTrend = await _calculateWorkoutTrend(
      year,
      month,
      sessions.where((s) => s.isCompleted).length,
    );

    // Calculate average macros per day
    final avgMacros = MacroDistribution(
      protein: totalProtein / avgDays,
      carbs: totalCarbs / avgDays,
      fat: totalFat / avgDays,
    );

    return MonthlyInsight(
      year: year,
      month: month,
      totalCaloriesIntake: totalIntake,
      totalCaloriesBurned: totalBurned,
      avgDailyIntake: avgIntake,
      avgDailyBurned: avgBurned,
      daysTracked: daysTracked,
      totalMeals: meals.length,
      totalWorkouts: sessions.where((s) => s.isCompleted).length,
      targetAdherence: targetAdherence,
      calorieTrend: calorieTrend,
      workoutTrend: workoutTrend,
      weeklyBreakdown: weeklyBreakdown,
      avgMacros: avgMacros,
    );
  }

  /// Get daily summaries for date range (for charts)
  static Future<List<DailySummary>> getDailySummaries(
    DateTime start,
    DateTime end,
  ) async {
    final records = await DatabaseService.getCaloRecordsRange(start, end);
    final userProfile = StorageService.getUserProfile();
    final dailyTarget = userProfile?.dailyTarget ?? 2000;

    final summaries = <DailySummary>[];

    // Fill in all days in range
    for (
      var date = start;
      date.isBefore(end.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))
    ) {
      final dateStr = _formatDate(date);
      final record = records.firstWhere(
        (r) => r.date == dateStr,
        orElse: () => CaloRecord.empty(dateStr),
      );

      // Get meals for this day
      final meals = await DatabaseService.getMealsForDate(dateStr);

      // Calculate macros
      double protein = 0;
      double carbs = 0;
      double fat = 0;
      for (final meal in meals) {
        protein += meal.protein ?? 0;
        carbs += meal.carbs ?? 0;
        fat += meal.fat ?? 0;
      }

      summaries.add(
        DailySummary(
          date: date,
          caloriesIntake: record.caloIntake,
          caloriesBurned: record.caloBurned,
          targetProgress:
              dailyTarget > 0 ? (record.caloIntake / dailyTarget) * 100 : 0,
          mealsCount: meals.length,
          macros: MacroDistribution(protein: protein, carbs: carbs, fat: fat),
        ),
      );
    }

    return summaries;
  }

  /// Get today's progress summary
  static Future<Map<String, dynamic>> getTodaySummary() async {
    final today = DateTime.now();
    final dateStr = _formatDate(today);

    final record = await DatabaseService.getCaloRecord(dateStr);
    final meals = await DatabaseService.getMealsForDate(dateStr);
    final sessions = await DatabaseService.getTodayGymSessions();
    final userProfile = StorageService.getUserProfile();
    final dailyTarget = userProfile?.dailyTarget ?? 2000;

    // Calculate macros
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final meal in meals) {
      protein += meal.protein ?? 0;
      carbs += meal.carbs ?? 0;
      fat += meal.fat ?? 0;
    }

    return {
      'caloriesIntake': record.caloIntake,
      'caloriesBurned': record.caloBurned,
      'netCalories': record.netCalo,
      'targetProgress':
          dailyTarget > 0 ? (record.caloIntake / dailyTarget) * 100 : 0.0,
      'mealsCount': meals.length,
      'workoutsCompleted': sessions.where((s) => s.isCompleted).length,
      'macros': MacroDistribution(protein: protein, carbs: carbs, fat: fat),
      'dailyTarget': dailyTarget,
    };
  }

  /// Calculate streak (consecutive days of tracking)
  static Future<int> getCurrentStreak() async {
    int streak = 0;
    var date = DateTime.now();

    while (true) {
      final dateStr = _formatDate(date);
      final record = await DatabaseService.getCaloRecord(dateStr);

      if (record.caloIntake > 0 || record.caloBurned > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }

      // Prevent infinite loop
      if (streak > 365) break;
    }

    return streak;
  }

  /// Get best streak ever
  static Future<int> getBestStreak() async {
    final allRecords = await _getAllRecordsSorted();

    int bestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (final record in allRecords) {
      if (record.caloIntake > 0 || record.caloBurned > 0) {
        if (lastDate == null) {
          currentStreak = 1;
        } else {
          final diff = lastDate.difference(record.dateTime).inDays;
          if (diff == 1) {
            currentStreak++;
          } else {
            if (currentStreak > bestStreak) {
              bestStreak = currentStreak;
            }
            currentStreak = 1;
          }
        }
        lastDate = record.dateTime;
      }
    }

    return bestStreak > currentStreak ? bestStreak : currentStreak;
  }

  /// Get overall statistics
  static Future<Map<String, dynamic>> getOverallStats() async {
    final stats = await DatabaseService.getStats();
    final currentStreak = await getCurrentStreak();
    final bestStreak = await getBestStreak();

    // Get total calories consumed and burned all time
    final allRecords = await _getAllRecordsSorted();
    double totalIntake = 0;
    double totalBurned = 0;

    for (final record in allRecords) {
      totalIntake += record.caloIntake;
      totalBurned += record.caloBurned;
    }

    return {
      ...stats,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'totalCaloriesIntake': totalIntake,
      'totalCaloriesBurned': totalBurned,
    };
  }

  // ==================== HELPER METHODS ====================

  static Future<List<Meal>> _getMealsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final allMeals = await DatabaseService.getAllMeals();
    return allMeals.where((meal) {
      return meal.dateTime.isAfter(start.subtract(const Duration(days: 1))) &&
          meal.dateTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  static Future<List<GymSession>> _getGymSessionsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final allSessions = await DatabaseService.getAllGymSessions();
    return allSessions.where((session) {
      return session.scheduledTime.isAfter(
            start.subtract(const Duration(days: 1)),
          ) &&
          session.scheduledTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  static Future<List<WeeklyReport>> _getWeeklyBreakdownForMonth(
    int year,
    int month,
  ) async {
    final reports = <WeeklyReport>[];
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    // Start from first Monday on or before the first day
    var weekStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    while (weekStart.isBefore(lastDay)) {
      final report = await getWeeklyReport(weekStart);
      reports.add(report);
      weekStart = weekStart.add(const Duration(days: 7));
    }

    return reports;
  }

  static Future<TrendDirection> _calculateCalorieTrend(
    int year,
    int month,
    double currentAvg,
  ) async {
    // Get previous month data
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;

    final prevFirstDay = DateTime(prevYear, prevMonth, 1);
    final prevLastDay = DateTime(prevYear, prevMonth + 1, 0);

    final prevRecords = await DatabaseService.getCaloRecordsRange(
      prevFirstDay,
      prevLastDay,
    );

    double prevTotal = 0;
    int prevDays = 0;
    for (final record in prevRecords) {
      if (record.caloIntake > 0) {
        prevTotal += record.caloIntake;
        prevDays++;
      }
    }

    if (prevDays == 0) return TrendDirection.stable;

    final prevAvg = prevTotal / prevDays;
    final diff = ((currentAvg - prevAvg) / prevAvg) * 100;

    if (diff > 5) return TrendDirection.up;
    if (diff < -5) return TrendDirection.down;
    return TrendDirection.stable;
  }

  static Future<TrendDirection> _calculateWorkoutTrend(
    int year,
    int month,
    int currentWorkouts,
  ) async {
    // Get previous month workouts
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;

    final prevFirstDay = DateTime(prevYear, prevMonth, 1);
    final prevLastDay = DateTime(prevYear, prevMonth + 1, 0);

    final prevSessions = await _getGymSessionsForRange(
      prevFirstDay,
      prevLastDay,
    );
    final prevWorkouts = prevSessions.where((s) => s.isCompleted).length;

    if (prevWorkouts == 0) {
      return currentWorkouts > 0 ? TrendDirection.up : TrendDirection.stable;
    }

    final diff = ((currentWorkouts - prevWorkouts) / prevWorkouts) * 100;

    if (diff > 10) return TrendDirection.up;
    if (diff < -10) return TrendDirection.down;
    return TrendDirection.stable;
  }

  static Future<List<CaloRecord>> _getAllRecordsSorted() async {
    final db = await DatabaseService.database;
    final results = await db.query('calo_records', orderBy: 'date DESC');
    return results.map((m) => CaloRecord.fromMap(m)).toList();
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _getDayName(DateTime date) {
    const days = [
      'Chủ nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
    ];
    return days[date.weekday % 7];
  }
}
