// Achievements Screen - Redesigned based on steak_UI
// Dark theme with tab bar, rarity badges, and progress indicators
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../services/gamification_service.dart';

// ─── Steak-UI color palette ───────────────────────────────────────────────────
const _bg = Color(0xFF0F1419);
const _surface = Color(0xFF1A1F2E);
const _surfaceLight = Color(0xFF2A3040);
const _orange = Color(0xFFFF9500);
const _orangeDark = Color(0xFFFF6B00);
const _green = Color(0xFF4CAF50);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFF9CA3AF);

// Rarity colors
const _rarityCommon = Color(0xFF6B7280);
const _rarityRare = Color(0xFF3B82F6);
const _rarityEpic = Color(0xFF8B5CF6);
const _rarityLegendary = Color(0xFFF59E0B);
// ─────────────────────────────────────────────────────────────────────────────

/// Maps Achievement types/requirements to a rarity level.
AchievementRarity _rarityFor(Achievement a) {
  if (a.points >= 500) return AchievementRarity.legendary;
  if (a.points >= 200) return AchievementRarity.epic;
  if (a.points >= 100) return AchievementRarity.rare;
  return AchievementRarity.common;
}

enum AchievementRarity { common, rare, epic, legendary }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final newlyUnlocked =
        await GamificationService.checkAndUnlockAchievements();
    final summary = await GamificationService.getGamificationSummary();
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
    if (newlyUnlocked.isNotEmpty && mounted) {
      _showNewAchievementsDialog(newlyUnlocked);
    }
  }

  void _showNewAchievementsDialog(List<Achievement> achievements) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('🎉 Thành tựu mới!'),
            content: Column(
              children: [
                const SizedBox(height: 12),
                ...achievements.map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title(a.titleKey),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '+${a.points} XP',
                              style: const TextStyle(
                                color: _green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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

  // ─── Localization helpers ──────────────────────────────────────────────────
  String _title(String key) {
    const map = {
      'achievementStreak3': '3 ngày liên tiếp',
      'achievementStreak7': '7 ngày liên tiếp',
      'achievementStreak14': '14 ngày liên tiếp',
      'achievementStreak30': '30 ngày liên tiếp',
      'achievementStreak100': '100 ngày liên tiếp',
      'achievementCalorieFirst': 'Khởi đầu tốt lành',
      'achievementCalorie10': '10 bữa ăn',
      'achievementCalorie50': '50 bữa ăn',
      'achievementCalorie100': 'Master Chef 100',
      'achievementWaterFirst': 'Uống nước đầu tiên',
      'achievementWater7': '7 ngày đủ nước',
      'achievementWater30': '30 ngày đủ nước',
      'achievementWorkoutFirst': 'Buổi tập đầu tiên',
      'achievementWorkout10': '10 buổi tập',
      'achievementWorkout50': 'Gym Rat',
      'achievementWeightFirst': 'Theo dõi cân nặng',
      'achievementWeightGoal': 'Đạt mục tiêu',
      'achievementEarlyBird': 'Chim sớm',
      'achievementNightOwl': 'Cú đêm',
    };
    return map[key] ?? key;
  }

  String _desc(String key) {
    const map = {
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
    return map[key] ?? key;
  }

  String _levelTitle(String key) {
    const map = {
      'levelBeginner': 'Người mới',
      'levelNovice': 'Tập sự',
      'levelIntermediate': 'Trung cấp',
      'levelAdvanced': 'Nâng cao',
      'levelExpert': 'Chuyên gia',
      'levelMaster': 'Bậc thầy',
      'levelLegend': 'Huyền thoại',
    };
    return map[key] ?? key;
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────
  int get _unlockedCount =>
      Achievement.all
          .where((a) => GamificationService.isAchievementUnlocked(a.id))
          .length;

  /// Returns the current progress value for a locked achievement.
  int _progressFor(Achievement a) {
    final progress = _summary?['progress'] as Map<String, int>? ?? {};
    switch (a.type) {
      case AchievementType.streak:
        return progress['streak'] ?? 0;
      case AchievementType.calorie:
        return progress['calorie'] ?? 0;
      case AchievementType.water:
        return progress['water'] ?? 0;
      case AchievementType.workout:
        return progress['workout'] ?? 0;
      case AchievementType.weight:
        return progress['weight'] ?? 0;
      default:
        return 0;
    }
  }

  List<Achievement> _getList(int tabIndex) {
    final all = Achievement.all;
    switch (tabIndex) {
      case 1:
        return all
            .where((a) => GamificationService.isAchievementUnlocked(a.id))
            .toList();
      case 2:
        return all
            .where((a) => !GamificationService.isAchievementUnlocked(a.id))
            .toList();
      default:
        return all;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CupertinoActivityIndicator(color: _orange),
                )
                : Column(
                  children: [
                    _buildHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children:
                            [
                              0,
                              1,
                              2,
                            ].map((i) => _buildList(_getList(i))).toList(),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: _textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thành tựu',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_unlockedCount/${Achievement.all.length} đã mở khóa',
                style: const TextStyle(
                  color: _green,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tab bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: _textPrimary,
          unselectedLabelColor: _textSecondary,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đã mở'),
            Tab(text: 'Chưa mở'),
          ],
        ),
      ),
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────
  Widget _buildList(List<Achievement> achievements) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _orange,
      backgroundColor: _surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: achievements.length + 1, // +1 for summary card
        itemBuilder: (context, index) {
          if (index == 0) return _buildSummaryCard();
          final a = achievements[index - 1];
          final isUnlocked = GamificationService.isAchievementUnlocked(a.id);
          if (a.isSecret && !isUnlocked) return _buildSecretCard();
          return _buildAchievementCard(a, isUnlocked);
        },
      ),
    );
  }

  // ─── Summary card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final level = _summary?['level'] as UserLevel?;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_orange, _orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: count + trophy icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thành tựu',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_unlockedCount',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'trên ${Achievement.all.length} thành tựu',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: _textPrimary,
                  size: 32,
                ),
              ),
            ],
          ),

          // Level info if available
          if (level != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${level.level} · ${_levelTitle(level.title)}',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${level.currentXP} XP · còn ${level.xpToNextLevel} XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(level.progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: level.progress,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Achievement card ─────────────────────────────────────────────────────
  Widget _buildAchievementCard(Achievement a, bool isUnlocked) {
    final rarity = _rarityFor(a);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      isUnlocked
                          ? _orange.withValues(alpha: 0.2)
                          : _surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? a.icon : '🔒',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title + rarity badge + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _title(a.titleKey),
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRarityBadge(rarity),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _desc(a.descriptionKey),
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isUnlocked
                          ? _green.withValues(alpha: 0.15)
                          : _surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${a.points} XP',
                  style: TextStyle(
                    color: isUnlocked ? _green : _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Unlocked indicator OR progress bar
          if (isUnlocked)
            Row(
              children: [
                const Icon(Icons.check_box, color: _green, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Đã mở khóa',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else ...[
            Builder(
              builder: (_) {
                final current = _progressFor(a).clamp(0, a.requirement);
                final pct = a.requirement > 0 ? current / a.requirement : 0.0;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$current/${a.requirement}',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(pct * 100).toInt()}%',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: _surfaceLight,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_orange),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── Secret card ──────────────────────────────────────────────────────────
  Widget _buildSecretCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('❓', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thành tựu bí mật',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tiếp tục sử dụng app để khám phá',
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.question_circle,
            color: _textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ─── Rarity badge ─────────────────────────────────────────────────────────
  Widget _buildRarityBadge(AchievementRarity rarity) {
    String label;
    Color color;
    switch (rarity) {
      case AchievementRarity.common:
        label = 'Common';
        color = _rarityCommon;
      case AchievementRarity.rare:
        label = 'Rare';
        color = _rarityRare;
      case AchievementRarity.epic:
        label = 'Epic';
        color = _rarityEpic;
      case AchievementRarity.legendary:
        label = 'Legendary';
        color = _rarityLegendary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
