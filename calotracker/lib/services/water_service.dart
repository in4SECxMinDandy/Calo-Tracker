// Water Service
// Business logic for water intake tracking
import '../models/water_record.dart';
import 'database_service.dart';
import 'storage_service.dart';

class WaterService {
  // Default daily water target in ml (2000ml = 2L)
  static const int defaultDailyTarget = 2000;

  // Common water amounts for quick add (in ml)
  static const List<int> quickAddAmounts = [100, 200, 250, 300, 500];

  // Storage key for water target
  static const String _keyWaterTarget = 'water_daily_target';

  /// Get daily water target
  static int getDailyTarget() {
    return StorageService.prefs.getInt(_keyWaterTarget) ?? defaultDailyTarget;
  }

  /// Set daily water target
  static Future<bool> setDailyTarget(int targetMl) async {
    return await StorageService.prefs.setInt(_keyWaterTarget, targetMl);
  }

  /// Add water intake
  static Future<void> addWaterIntake(int amountMl, {String? note}) async {
    final record = WaterRecord(
      dateTime: DateTime.now(),
      amount: amountMl,
      note: note,
    );
    await DatabaseService.insertWaterRecord(record);
  }

  /// Get today's water summary
  static Future<DailyWaterSummary> getTodaySummary() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return await getWaterSummaryForDate(dateStr);
  }

  /// Get water summary for a specific date
  static Future<DailyWaterSummary> getWaterSummaryForDate(String date) async {
    final entries = await DatabaseService.getWaterRecordsForDate(date);
    final totalAmount = entries.fold<int>(0, (sum, r) => sum + r.amount);
    final target = getDailyTarget();

    return DailyWaterSummary(
      date: date,
      totalAmount: totalAmount,
      targetAmount: target,
      entryCount: entries.length,
      entries: entries,
    );
  }

  /// Delete water record
  static Future<void> deleteWaterRecord(String id) async {
    await DatabaseService.deleteWaterRecord(id);
  }

  /// Get water records for date range (for charts)
  static Future<List<DailyWaterSummary>> getWaterSummariesRange(
    DateTime start,
    DateTime end,
  ) async {
    final summaries = <DailyWaterSummary>[];
    final target = getDailyTarget();

    for (var date = start;
        date.isBefore(end) || date.isAtSameMomentAs(end);
        date = date.add(const Duration(days: 1))) {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final entries = await DatabaseService.getWaterRecordsForDate(dateStr);
      final totalAmount = entries.fold<int>(0, (sum, r) => sum + r.amount);

      summaries.add(DailyWaterSummary(
        date: dateStr,
        totalAmount: totalAmount,
        targetAmount: target,
        entryCount: entries.length,
        entries: entries,
      ));
    }

    return summaries;
  }

  /// Get weekly water stats
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final summaries = await getWaterSummariesRange(weekStart, weekEnd);
    final totalWeekAmount =
        summaries.fold<int>(0, (sum, s) => sum + s.totalAmount);
    final daysReachedTarget =
        summaries.where((s) => s.isTargetReached).length;
    final averageDaily =
        summaries.isNotEmpty ? totalWeekAmount ~/ summaries.length : 0;

    return {
      'totalAmount': totalWeekAmount,
      'averageDaily': averageDaily,
      'daysReachedTarget': daysReachedTarget,
      'totalDays': summaries.length,
      'summaries': summaries,
    };
  }

  /// Calculate recommended water intake based on weight (30-35ml per kg)
  static int calculateRecommendedIntake(double weightKg) {
    return (weightKg * 33).round(); // 33ml per kg is a good average
  }

  /// Get hydration tips based on current progress
  static String getHydrationTip(DailyWaterSummary summary) {
    final hour = DateTime.now().hour;
    final progress = summary.progressPercent;

    if (progress >= 100) {
      return 'waterTipGoalReached';
    } else if (hour < 12 && progress < 30) {
      return 'waterTipMorning';
    } else if (hour >= 12 && hour < 18 && progress < 60) {
      return 'waterTipAfternoon';
    } else if (hour >= 18 && progress < 80) {
      return 'waterTipEvening';
    } else {
      return 'waterTipKeepGoing';
    }
  }

  /// Get all water records
  static Future<List<WaterRecord>> getAllWaterRecords() async {
    return await DatabaseService.getAllWaterRecords();
  }
}
