// Achievements Screen
// Displays user achievements, level, and XP progress
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../services/gamification_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Check for new achievements
    final newlyUnlocked = await GamificationService.checkAndUnlockAchievements();
    final summary = await GamificationService.getGamificationSummary();

    setState(() {
      _summary = summary;
      _isLoading = false;
    });

    // Show celebration for new achievements
    if (newlyUnlocked.isNotEmpty && mounted) {
      _showNewAchievementsDialog(newlyUnlocked);
    }
  }

  void _showNewAchievementsDialog(List<Achievement> achievements) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉 '),
            Text(achievements.length > 1
                ? 'Thành tựu mới!'
                : 'Thành tựu mới!'),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: 16),
            ...achievements.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAchievementTitle(a.titleKey),
                        style: AppTextStyles.cardTitle,
                      ),
                      Text(
                        '+${a.points} XP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tuyệt vời!'),
          ),
        ],
      ),
    );
  }

  String _getAchievementTitle(String key) {
    // Simplified localization - in production, use AppLocalizations
    final titles = {
      'achievementStreak3': '3 ngày liên tiếp',
      'achievementStreak7': '7 ngày liên tiếp',
      'achievementStreak14': '14 ngày liên tiếp',
      'achievementStreak30': '30 ngày liên tiếp',
      'achievementStreak100': '100 ngày liên tiếp',
      'achievementCalorieFirst': 'Bữa ăn đầu tiên',
      'achievementCalorie10': '10 bữa ăn',
      'achievementCalorie50': '50 bữa ăn',
      'achievementCalorie100': '100 bữa ăn',
      'achievementWaterFirst': 'Uống nước đầu tiên',
      'achievementWater7': '7 ngày uống đủ nước',
      'achievementWater30': '30 ngày uống đủ nước',
      'achievementWorkoutFirst': 'Buổi tập đầu tiên',
      'achievementWorkout10': '10 buổi tập',
      'achievementWorkout50': '50 buổi tập',
      'achievementWeightFirst': 'Cân đầu tiên',
      'achievementWeightGoal': 'Đạt mục tiêu cân nặng',
      'achievementEarlyBird': 'Chim sớm',
      'achievementNightOwl': 'Cú đêm',
    };
    return titles[key] ?? key;
  }

  String _getAchievementDesc(String key) {
    final descriptions = {
      'achievementStreak3Desc': 'Sử dụng app 3 ngày liên tiếp',
      'achievementStreak7Desc': 'Sử dụng app 7 ngày liên tiếp',
      'achievementStreak14Desc': 'Sử dụng app 14 ngày liên tiếp',
      'achievementStreak30Desc': 'Sử dụng app 30 ngày liên tiếp',
      'achievementStreak100Desc': 'Sử dụng app 100 ngày liên tiếp!',
      'achievementCalorieFirstDesc': 'Ghi nhận bữa ăn đầu tiên',
      'achievementCalorie10Desc': 'Ghi nhận 10 bữa ăn',
      'achievementCalorie50Desc': 'Ghi nhận 50 bữa ăn',
      'achievementCalorie100Desc': 'Ghi nhận 100 bữa ăn',
      'achievementWaterFirstDesc': 'Ghi nhận lần uống nước đầu tiên',
      'achievementWater7Desc': 'Uống đủ nước 7 ngày',
      'achievementWater30Desc': 'Uống đủ nước 30 ngày',
      'achievementWorkoutFirstDesc': 'Hoàn thành buổi tập đầu tiên',
      'achievementWorkout10Desc': 'Hoàn thành 10 buổi tập',
      'achievementWorkout50Desc': 'Hoàn thành 50 buổi tập',
      'achievementWeightFirstDesc': 'Cập nhật cân nặng lần đầu',
      'achievementWeightGoalDesc': 'Đạt được mục tiêu cân nặng',
      'achievementEarlyBirdDesc': 'Sử dụng app trước 7 giờ sáng',
      'achievementNightOwlDesc': 'Tập luyện sau 10 giờ tối',
    };
    return descriptions[key] ?? key;
  }

  String _getLevelTitle(String key) {
    final titles = {
      'levelBeginner': 'Người mới',
      'levelNovice': 'Tập sự',
      'levelIntermediate': 'Trung cấp',
      'levelAdvanced': 'Nâng cao',
      'levelExpert': 'Chuyên gia',
      'levelMaster': 'Bậc thầy',
      'levelLegend': 'Huyền thoại',
    };
    return titles[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành tựu'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildLevelCard()),
                  SliverToBoxAdapter(child: _buildStatsCard()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text('Tất cả thành tựu', style: AppTextStyles.heading3),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final achievement = Achievement.all[index];
                          final isUnlocked = GamificationService.isAchievementUnlocked(achievement.id);

                          // Hide secret achievements that are not unlocked
                          if (achievement.isSecret && !isUnlocked) {
                            return _buildSecretAchievementTile();
                          }

                          return _buildAchievementTile(achievement, isUnlocked);
                        },
                        childCount: Achievement.all.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelCard() {
    final level = _summary?['level'] as UserLevel?;
    if (level == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Level badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${level.level}',
                  style: AppTextStyles.heading1.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Level title
            Text(
              _getLevelTitle(level.title),
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              '${level.currentXP} XP',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Progress to next level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${level.level + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${level.xpToNextLevel} XP còn lại',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: level.progress,
                    minHeight: 10,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final unlockedCount = _summary?['unlockedCount'] as int? ?? 0;
    final totalCount = _summary?['totalAchievements'] as int? ?? 0;
    final completionPercent = _summary?['completionPercent'] as double? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: CupertinoIcons.star_fill,
                value: '$unlockedCount/$totalCount',
                label: 'Đã mở khóa',
                color: Colors.amber,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(
              child: _buildStatItem(
                icon: CupertinoIcons.chart_pie_fill,
                value: '${completionPercent.toInt()}%',
                label: 'Hoàn thành',
                color: AppColors.successGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.heading3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementTile(Achievement achievement, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? achievement.color.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? achievement.color.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isUnlocked
                ? achievement.color.withValues(alpha: 0.2)
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              isUnlocked ? achievement.icon : '🔒',
              style: TextStyle(
                fontSize: 24,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
        ),
        title: Text(
          _getAchievementTitle(achievement.titleKey),
          style: AppTextStyles.cardTitle.copyWith(
            color: isUnlocked
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          _getAchievementDesc(achievement.descriptionKey),
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+${achievement.points}',
              style: AppTextStyles.labelMedium.copyWith(
                color: isUnlocked ? AppColors.successGreen : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'XP',
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretAchievementTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('❓', style: TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          'Thành tựu bí mật',
          style: AppTextStyles.cardTitle.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          'Tiếp tục sử dụng app để khám phá',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(
          CupertinoIcons.question_circle,
          color: Colors.grey,
        ),
      ),
    );
  }
}
