// Sleep Service
// Manages sleep tracking, insights, and bedtime reminders
import '../models/sleep_record.dart';
import 'database_service.dart';
import 'notification_service.dart';

class SleepService {
  static const double _recommendedMinHours = 7.0;
  static const double _recommendedMaxHours = 9.0;

  // ==================== CRUD OPERATIONS ====================

  /// Add a new sleep record
  static Future<void> addSleepRecord(SleepRecord record) async {
    await DatabaseService.insertSleepRecord(record);
  }

  /// Update an existing sleep record
  static Future<void> updateSleepRecord(SleepRecord record) async {
    await DatabaseService.updateSleepRecord(record);
  }

  /// Delete a sleep record
  static Future<void> deleteSleepRecord(String id) async {
    await DatabaseService.deleteSleepRecord(id);
  }

  /// Get sleep record for a specific date
  static Future<SleepRecord?> getSleepRecordForDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return await DatabaseService.getSleepRecordForDate(dateStr);
  }

  /// Get today's sleep record
  static Future<SleepRecord?> getTodaySleepRecord() async {
    return await DatabaseService.getTodaySleepRecord();
  }

  /// Get last night's sleep record
  static Future<SleepRecord?> getLastNightSleepRecord() async {
    return await DatabaseService.getLastNightSleepRecord();
  }

  /// Get all sleep records
  static Future<List<SleepRecord>> getAllSleepRecords() async {
    return await DatabaseService.getAllSleepRecords();
  }

  /// Get sleep records for the last N days
  static Future<List<SleepRecord>> getRecentSleepRecords(int days) async {
    return await DatabaseService.getRecentSleepRecords(days);
  }

  // ==================== INSIGHTS & ANALYTICS ====================

  /// Get average sleep duration for last N days
  static Future<double> getAverageSleepDuration({int days = 7}) async {
    return await DatabaseService.getAverageSleepDuration(days);
  }

  /// Get sleep statistics for a given period
  static Future<SleepStats> getSleepStats({int days = 7}) async {
    final records = await getRecentSleepRecords(days);

    if (records.isEmpty) {
      return SleepStats(
        averageDuration: 0,
        averageQuality: 0,
        totalRecorded: 0,
        longestSleep: 0,
        shortestSleep: 0,
        averageBedTime: null,
        averageWakeTime: null,
        sleepDebt: 0,
        consistencyScore: 0,
      );
    }

    // Calculate average duration
    double totalDuration = 0;
    double totalQuality = 0;
    int qualityCount = 0;
    double maxDuration = 0;
    double minDuration = double.infinity;
    int totalBedMinutes = 0;
    int totalWakeMinutes = 0;

    for (final record in records) {
      totalDuration += record.durationHours;

      if (record.durationHours > maxDuration) {
        maxDuration = record.durationHours;
      }
      if (record.durationHours < minDuration) {
        minDuration = record.durationHours;
      }

      if (record.quality != null) {
        totalQuality += record.quality!.value;
        qualityCount++;
      }

      // Convert time to minutes from midnight
      int bedMinutes = record.bedTime.hour * 60 + record.bedTime.minute;
      if (bedMinutes > 720) {
        bedMinutes -= 1440; // Handle after midnight as negative
      }
      totalBedMinutes += bedMinutes;

      int wakeMinutes = record.wakeTime.hour * 60 + record.wakeTime.minute;
      totalWakeMinutes += wakeMinutes;
    }

    final avgDuration = totalDuration / records.length;
    final avgQuality = qualityCount > 0 ? totalQuality / qualityCount : 0.0;

    // Calculate average bed/wake times
    final avgBedMinutes = totalBedMinutes ~/ records.length;
    final avgWakeMinutes = totalWakeMinutes ~/ records.length;

    // Convert back to DateTime
    int normalizedBedMinutes =
        avgBedMinutes < 0 ? avgBedMinutes + 1440 : avgBedMinutes;
    final avgBedTime = DateTime(
      2000,
      1,
      1,
      normalizedBedMinutes ~/ 60,
      normalizedBedMinutes % 60,
    );
    final avgWakeTime = DateTime(
      2000,
      1,
      1,
      avgWakeMinutes ~/ 60,
      avgWakeMinutes % 60,
    );

    // Calculate sleep debt (hours below recommended)
    double sleepDebt = 0;
    for (final record in records) {
      if (record.durationHours < _recommendedMinHours) {
        sleepDebt += _recommendedMinHours - record.durationHours;
      }
    }

    // Calculate consistency score (based on variance in bed/wake times)
    double bedTimeVariance = 0;
    double wakeTimeVariance = 0;
    for (final record in records) {
      int bedMinutes = record.bedTime.hour * 60 + record.bedTime.minute;
      if (bedMinutes > 720) {
        bedMinutes -= 1440;
      }
      bedTimeVariance += (bedMinutes - avgBedMinutes).abs();

      int wakeMinutes = record.wakeTime.hour * 60 + record.wakeTime.minute;
      wakeTimeVariance += (wakeMinutes - avgWakeMinutes).abs();
    }
    final avgVariance =
        (bedTimeVariance + wakeTimeVariance) / (2 * records.length);
    // Low variance = high consistency (max 100 when variance is 0)
    final consistencyScore =
        ((1 - (avgVariance / 120).clamp(0, 1)) * 100).round();

    return SleepStats(
      averageDuration: avgDuration,
      averageQuality: avgQuality,
      totalRecorded: records.length,
      longestSleep: maxDuration,
      shortestSleep: minDuration == double.infinity ? 0 : minDuration,
      averageBedTime: avgBedTime,
      averageWakeTime: avgWakeTime,
      sleepDebt: sleepDebt,
      consistencyScore: consistencyScore,
    );
  }

  /// Get sleep trend (improving, declining, or stable)
  static Future<SleepTrend> getSleepTrend() async {
    final recentWeek = await getRecentSleepRecords(7);
    final previousWeek = await DatabaseService.getSleepRecordsRange(
      DateTime.now().subtract(const Duration(days: 14)),
      DateTime.now().subtract(const Duration(days: 7)),
    );

    if (recentWeek.isEmpty || previousWeek.isEmpty) {
      return SleepTrend.stable;
    }

    final recentAvg =
        recentWeek.fold<double>(0, (sum, r) => sum + r.durationHours) /
        recentWeek.length;
    final previousAvg =
        previousWeek.fold<double>(0, (sum, r) => sum + r.durationHours) /
        previousWeek.length;

    final difference = recentAvg - previousAvg;
    if (difference > 0.5) return SleepTrend.improving;
    if (difference < -0.5) return SleepTrend.declining;
    return SleepTrend.stable;
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get personalized sleep recommendations
  static Future<List<SleepRecommendation>> getRecommendations() async {
    final stats = await getSleepStats(days: 7);
    final recommendations = <SleepRecommendation>[];

    // Check average duration
    if (stats.averageDuration < _recommendedMinHours) {
      recommendations.add(
        SleepRecommendation(
          title: 'Ngủ thêm',
          description:
              'Bạn đang ngủ trung bình ${stats.averageDuration.toStringAsFixed(1)} giờ/đêm. Hãy cố gắng ngủ ít nhất $_recommendedMinHours giờ.',
          icon: '😴',
          priority: RecommendationPriority.high,
        ),
      );
    } else if (stats.averageDuration > _recommendedMaxHours) {
      recommendations.add(
        SleepRecommendation(
          title: 'Giảm giờ ngủ',
          description:
              'Ngủ quá nhiều (${stats.averageDuration.toStringAsFixed(1)} giờ) có thể gây mệt mỏi. Mục tiêu là 7-9 giờ.',
          icon: '⏰',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    // Check consistency
    if (stats.consistencyScore < 60) {
      recommendations.add(
        SleepRecommendation(
          title: 'Duy trì lịch ngủ đều đặn',
          description:
              'Đi ngủ và thức dậy cùng giờ mỗi ngày giúp cải thiện chất lượng giấc ngủ.',
          icon: '📅',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    // Check sleep debt
    if (stats.sleepDebt > 7) {
      recommendations.add(
        SleepRecommendation(
          title: 'Bù nợ giấc ngủ',
          description:
              'Bạn đang thiếu ${stats.sleepDebt.toStringAsFixed(1)} giờ ngủ tuần này. Hãy ngủ sớm hơn vài ngày tới.',
          icon: '💤',
          priority: RecommendationPriority.high,
        ),
      );
    }

    // Check quality
    if (stats.averageQuality > 0 && stats.averageQuality < 3) {
      recommendations.add(
        SleepRecommendation(
          title: 'Cải thiện chất lượng giấc ngủ',
          description:
              'Thử giảm caffeine, tập thể dục đều đặn và hạn chế sử dụng điện thoại trước khi ngủ.',
          icon: '✨',
          priority: RecommendationPriority.high,
        ),
      );
    }

    // Add general tips if no issues
    if (recommendations.isEmpty) {
      recommendations.add(
        SleepRecommendation(
          title: 'Giấc ngủ tốt!',
          description:
              'Bạn đang duy trì thói quen ngủ lành mạnh. Tiếp tục phát huy!',
          icon: '🌟',
          priority: RecommendationPriority.low,
        ),
      );
    }

    return recommendations;
  }

  // ==================== BEDTIME REMINDERS ====================

  /// Schedule bedtime reminder notification
  static Future<void> scheduleBedtimeReminder({
    required int hour,
    required int minute,
  }) async {
    await NotificationService.scheduleBedtimeReminder(
      hour: hour,
      minute: minute,
    );
  }

  /// Cancel bedtime reminder
  static Future<void> cancelBedtimeReminder() async {
    await NotificationService.cancelBedtimeReminder();
  }

  // ==================== UTILITY METHODS ====================

  /// Check if sleep duration is within healthy range
  static bool isHealthyDuration(double hours) {
    return hours >= _recommendedMinHours && hours <= _recommendedMaxHours;
  }

  /// Get recommended sleep duration message
  static String getSleepDurationMessage(double hours) {
    if (hours < 5) return 'Rất thiếu ngủ';
    if (hours < 7) return 'Hơi thiếu ngủ';
    if (hours <= 9) return 'Đủ giấc';
    if (hours <= 10) return 'Hơi nhiều';
    return 'Ngủ quá nhiều';
  }
}

// ==================== DATA CLASSES ====================

/// Sleep statistics for a given period
class SleepStats {
  final double averageDuration;
  final double averageQuality;
  final int totalRecorded;
  final double longestSleep;
  final double shortestSleep;
  final DateTime? averageBedTime;
  final DateTime? averageWakeTime;
  final double sleepDebt;
  final int consistencyScore;

  SleepStats({
    required this.averageDuration,
    required this.averageQuality,
    required this.totalRecorded,
    required this.longestSleep,
    required this.shortestSleep,
    this.averageBedTime,
    this.averageWakeTime,
    required this.sleepDebt,
    required this.consistencyScore,
  });

  String get averageBedTimeFormatted {
    if (averageBedTime == null) return '--:--';
    return '${averageBedTime!.hour.toString().padLeft(2, '0')}:${averageBedTime!.minute.toString().padLeft(2, '0')}';
  }

  String get averageWakeTimeFormatted {
    if (averageWakeTime == null) return '--:--';
    return '${averageWakeTime!.hour.toString().padLeft(2, '0')}:${averageWakeTime!.minute.toString().padLeft(2, '0')}';
  }
}

/// Sleep trend indicator
enum SleepTrend { improving, stable, declining }

/// Priority level for recommendations
enum RecommendationPriority { low, medium, high }

/// Sleep recommendation
class SleepRecommendation {
  final String title;
  final String description;
  final String icon;
  final RecommendationPriority priority;

  SleepRecommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
  });
}
