// Level Badge Widget
// Displays user level and XP progress on home screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/achievement.dart';
import '../../../services/gamification_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/glass_card.dart';
import '../../achievements/achievements_screen.dart';

class LevelBadgeWidget extends StatefulWidget {
  const LevelBadgeWidget({super.key});

  @override
  State<LevelBadgeWidget> createState() => _LevelBadgeWidgetState();
}

class _LevelBadgeWidgetState extends State<LevelBadgeWidget> {
  UserLevel? _level;
  int _unlockedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final summary = await GamificationService.getGamificationSummary();
    if (mounted) {
      setState(() {
        _level = summary['level'] as UserLevel?;
        _unlockedCount = summary['unlockedCount'] as int? ?? 0;
        _totalCount = summary['totalAchievements'] as int? ?? 0;
      });
    }
  }

  void _openAchievements() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const AchievementsScreen()),
    ).then((_) => _loadData());
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
    if (_level == null) {
      return const SizedBox();
    }

    return GlassCard(
      onTap: _openAchievements,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${_level!.level}',
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Level info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getLevelTitle(_level!.title),
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_level!.currentXP} XP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _level!.progress,
                          minHeight: 6,
                          backgroundColor: Theme.of(context).dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber.shade400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_unlockedCount/$_totalCount',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.star_fill,
                      size: 14,
                      color: Colors.amber.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow
          Icon(
            CupertinoIcons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }
}
