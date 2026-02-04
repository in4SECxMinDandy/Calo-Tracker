// Gamification Service
// Handles achievements, levels, and XP tracking
import '../models/achievement.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'insights_service.dart';

class GamificationService {
  // Storage keys
  static const String _keyTotalXP = 'total_xp';
  static const String _keyUnlockedAchievements = 'unlocked_achievements';
  static const String _keyLastAchievementCheck = 'last_achievement_check';

  /// Get total XP
  static int getTotalXP() {
    return StorageService.prefs.getInt(_keyTotalXP) ?? 0;
  }

  /// Add XP
  static Future<int> addXP(int xp) async {
    final current = getTotalXP();
    final newTotal = current + xp;
    await StorageService.prefs.setInt(_keyTotalXP, newTotal);
    return newTotal;
  }

  /// Get current user level
  static UserLevel getUserLevel() {
    return UserLevel.fromXP(getTotalXP());
  }

  /// Get unlocked achievement IDs
  static List<String> getUnlockedAchievementIds() {
    final stored = StorageService.prefs.getStringList(_keyUnlockedAchievements);
    return stored ?? [];
  }

  /// Get unlocked achievements with details
  static List<UserAchievement> getUnlockedAchievements() {
    final ids = getUnlockedAchievementIds();
    return ids.map((id) {
      final parts = id.split('|');
      return UserAchievement(
        achievementId: parts[0],
        unlockedAt: parts.length > 1
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]))
            : DateTime.now(),
        progressValue: parts.length > 2 ? int.parse(parts[2]) : 0,
      );
    }).toList();
  }

  /// Unlock an achievement
  static Future<bool> unlockAchievement(String achievementId) async {
    final unlockedIds = getUnlockedAchievementIds();

    // Check if already unlocked
    if (unlockedIds.any((id) => id.startsWith('$achievementId|'))) {
      return false;
    }

    final achievement = Achievement.getById(achievementId);
    if (achievement == null) return false;

    // Add to unlocked list with timestamp
    final entry = '$achievementId|${DateTime.now().millisecondsSinceEpoch}';
    unlockedIds.add(entry);
    await StorageService.prefs.setStringList(_keyUnlockedAchievements, unlockedIds);

    // Award XP
    await addXP(achievement.points);

    return true;
  }

  /// Check if achievement is unlocked
  static bool isAchievementUnlocked(String achievementId) {
    final ids = getUnlockedAchievementIds();
    return ids.any((id) => id.startsWith('$achievementId|'));
  }

  /// Get achievement progress (for locked achievements)
  static Future<Map<String, int>> getAchievementProgress() async {
    final stats = await InsightsService.getOverallStats();
    final progress = <String, int>{};

    // Streak progress
    final currentStreak = stats['currentStreak'] as int? ?? 0;
    progress['streak'] = currentStreak;

    // Calorie tracking progress (days with meals logged)
    final totalMeals = stats['totalMeals'] as int? ?? 0;
    progress['calorie'] = totalMeals;

    // Water progress (days reached goal) - estimate from total entries
    final waterRecords = await DatabaseService.getAllWaterRecords();
    final waterDays = waterRecords.map((r) => r.dateStr).toSet().length;
    progress['water'] = waterDays;

    // Workout progress
    final totalWorkouts = stats['totalWorkouts'] as int? ?? 0;
    progress['workout'] = totalWorkouts;

    // Weight tracking progress
    final weightRecords = await DatabaseService.getAllWeightRecords();
    progress['weight'] = weightRecords.length;

    return progress;
  }

  /// Check and unlock new achievements based on current progress
  static Future<List<Achievement>> checkAndUnlockAchievements() async {
    final newlyUnlocked = <Achievement>[];
    final progress = await getAchievementProgress();

    for (final achievement in Achievement.all) {
      if (isAchievementUnlocked(achievement.id)) continue;

      bool shouldUnlock = false;
      int currentValue = 0;

      switch (achievement.type) {
        case AchievementType.streak:
          currentValue = progress['streak'] ?? 0;
          shouldUnlock = currentValue >= achievement.requirement;
          break;

        case AchievementType.calorie:
          currentValue = progress['calorie'] ?? 0;
          shouldUnlock = currentValue >= achievement.requirement;
          break;

        case AchievementType.water:
          currentValue = progress['water'] ?? 0;
          shouldUnlock = currentValue >= achievement.requirement;
          break;

        case AchievementType.workout:
          currentValue = progress['workout'] ?? 0;
          shouldUnlock = currentValue >= achievement.requirement;
          break;

        case AchievementType.weight:
          currentValue = progress['weight'] ?? 0;
          shouldUnlock = currentValue >= achievement.requirement;
          break;

        case AchievementType.milestone:
          // Special milestones checked separately
          if (achievement.id == 'early_bird') {
            final hour = DateTime.now().hour;
            shouldUnlock = hour >= 5 && hour < 7 && (progress['calorie'] ?? 0) > 0;
          } else if (achievement.id == 'night_owl') {
            final hour = DateTime.now().hour;
            shouldUnlock = (hour >= 22 || hour < 2) && (progress['workout'] ?? 0) > 0;
          }
          break;

        case AchievementType.social:
          // Not implemented yet
          break;
      }

      if (shouldUnlock) {
        final unlocked = await unlockAchievement(achievement.id);
        if (unlocked) {
          newlyUnlocked.add(achievement);
        }
      }
    }

    return newlyUnlocked;
  }

  /// Get gamification summary
  static Future<Map<String, dynamic>> getGamificationSummary() async {
    final level = getUserLevel();
    final unlockedAchievements = getUnlockedAchievements();
    final progress = await getAchievementProgress();

    // Calculate completion percentage
    final totalAchievements = Achievement.all.where((a) => !a.isSecret).length;
    final unlockedCount = unlockedAchievements
        .where((ua) => ua.achievement != null && !ua.achievement!.isSecret)
        .length;
    final completionPercent = totalAchievements > 0
        ? (unlockedCount / totalAchievements * 100)
        : 0.0;

    return {
      'level': level,
      'totalXP': getTotalXP(),
      'unlockedAchievements': unlockedAchievements,
      'unlockedCount': unlockedAchievements.length,
      'totalAchievements': Achievement.all.length,
      'completionPercent': completionPercent,
      'progress': progress,
    };
  }

  /// Get recent achievements (last 7 days)
  static List<UserAchievement> getRecentAchievements() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return getUnlockedAchievements()
        .where((ua) => ua.unlockedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
  }

  /// Reset all gamification data
  static Future<void> resetAll() async {
    await StorageService.prefs.remove(_keyTotalXP);
    await StorageService.prefs.remove(_keyUnlockedAchievements);
    await StorageService.prefs.remove(_keyLastAchievementCheck);
  }
}
