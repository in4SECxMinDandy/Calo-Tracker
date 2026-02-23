// Home Screen - Modern Health & Social Wellness Ecosystem
// Redesigned with Apple Health + Strava + Instagram aesthetics
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/user_profile.dart';
import '../../models/calo_record.dart';
import '../../models/gym_session.dart';
import '../../models/friendship.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/friends_service.dart';
import '../../theme/colors.dart';
import '../chatbot/chatbot_screen.dart';
import '../camera/camera_scan_screen.dart';
import '../gym/gym_scheduler_screen.dart';
import '../history/history_screen.dart';
import '../workout/workout_program_screen.dart';

import 'widgets/settings_sheet.dart';
import 'widgets/water_intake_widget.dart';

import 'widgets/level_badge_widget.dart';

import 'widgets/meal_suggestion_widget.dart';
import 'widgets/sleep_widget.dart';
import '../community/community_hub_screen.dart';

import '../profile/profile_screen.dart';
import '../../widgets/redesign/health_rings.dart';
import '../../widgets/redesign/macro_bar.dart';

// Modern color palette
class WellnessColors {
  static const Color background = Color(0xFFF8F9FA);
  static const Color sageGreen = Color(0xFF8BC48A);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color lavender = Color(0xFFB4A7D6);
  static const Color peach = Color(0xFFFFB5A7);
  static const Color mint = Color(0xFF98D8C8);
  static const Color warmGray = Color(0xFF6B7280);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  UserProfile? _userProfile;
  CaloRecord? _todayRecord;
  GymSession? _nextGymSession;
  List<Friendship> _friends = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  final _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final profile = StorageService.getUserProfile();
      final todayRecord = await DatabaseService.getTodayRecord();
      final nextGym = await DatabaseService.getNextGymSession();

      // Load friends list
      List<Friendship> friends = [];
      try {
        if (_friendsService.isAvailable) {
          friends = await _friendsService.getFriends();
        }
      } catch (e) {
        // Silently fail if friends service is not available
      }

      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _todayRecord = todayRecord;
        _nextGymSession = nextGym;
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openChatbot() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => ChatbotScreen(onMealAdded: _loadData)),
    );
  }

  void _openCamera() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => CameraScanScreen(onMealAdded: _loadData),
      ),
    );
  }

  void _openGymScheduler() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder:
            (_) => GymSchedulerScreen(
              existingSession: _nextGymSession,
              onSessionUpdated: _loadData,
            ),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(onSettingsChanged: _loadData),
    );
  }

  void _openCommunity() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const CommunityHubScreen()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng ☀️';
    if (hour < 18) return 'Chào buổi chiều 🌤️';
    return 'Chào buổi tối 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyTarget = _userProfile?.dailyTarget ?? 2000;
    final intake = _todayRecord?.caloIntake ?? 0;
    final burned = _todayRecord?.caloBurned ?? 0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : WellnessColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(isDark, dailyTarget.toDouble(), intake, burned),
          const CommunityHubScreen(),
          const HistoryScreen(),
          const ChatbotScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
      // Floating Action Button - Only show on home tab
      floatingActionButton: _currentIndex == 0 ? _buildScannerFAB() : null,
    );
  }

  Widget _buildDashboard(
    bool isDark,
    double dailyTarget,
    double intake,
    double burned,
  ) {
    if (_isLoading) return const Center(child: CupertinoActivityIndicator());

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Compact Header
            SliverToBoxAdapter(child: _buildCompactHeader(isDark)),

            // Stories Bar - Horizontal challenges/friends
            SliverToBoxAdapter(child: _buildStoriesBar(isDark)),

            // Health Rings - Apple Watch style
            SliverToBoxAdapter(
              child: _buildHealthRings(isDark, intake, burned, dailyTarget),
            ),

            // Macro Bars - Daily nutrition breakdown
            SliverToBoxAdapter(child: _buildMacroBars(isDark)),

            // Quick Actions - Pill buttons
            SliverToBoxAdapter(child: _buildQuickActions(isDark)),

            // Social Activity Card
            SliverToBoxAdapter(child: _buildSocialActivityCard(isDark)),

            // Community Highlight
            SliverToBoxAdapter(child: _buildCommunityHighlight(isDark)),

            // Next Workout Card
            SliverToBoxAdapter(child: _buildNextWorkoutCard(isDark)),

            // Content Section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // Water & Sleep Row
                  Row(
                    children: [
                      Expanded(
                        child: WaterIntakeWidget(onWaterAdded: _loadData),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SleepWidget()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Level Badge
                  const LevelBadgeWidget(),
                  const SizedBox(height: 16),

                  // Meal Suggestion
                  MealSuggestionWidget(onMealAdded: _loadData),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final tabs = [
      {
        'icon': CupertinoIcons.house,
        'activeIcon': CupertinoIcons.house_fill,
        'label': 'Trang chủ',
      },
      {
        'icon': CupertinoIcons.person_3,
        'activeIcon': CupertinoIcons.person_3_fill,
        'label': 'Cộng đồng',
      },
      {
        'icon': CupertinoIcons.chart_bar,
        'activeIcon': CupertinoIcons.chart_bar_fill,
        'label': 'Lịch sử',
      },
      {
        'icon': CupertinoIcons.sparkles,
        'activeIcon': CupertinoIcons.sparkles,
        'label': 'AI',
      },
      {
        'icon': CupertinoIcons.person,
        'activeIcon': CupertinoIcons.person_fill,
        'label': 'Hồ sơ',
      },
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color:
                    isDark
                        ? AppColors.darkDivider.withValues(alpha: 0.3)
                        : AppColors.lightDivider.withValues(alpha: 0.3),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Stack(
                children: [
                  // Active pill indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    top: 8,
                    left:
                        (_currentIndex *
                            (MediaQuery.of(context).size.width / tabs.length)) +
                        (MediaQuery.of(context).size.width / tabs.length * 0.1),
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width / tabs.length * 0.8,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue.withValues(alpha: 0.1),
                            AppColors.primaryIndigo.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tab items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(tabs.length, (i) {
                      final tab = tabs[i];
                      final isSelected = _currentIndex == i;
                      final activeColor =
                          i == 1
                              ? AppColors.facebookBlue
                              : AppColors.primaryBlue;
                      final color =
                          isSelected
                              ? activeColor
                              : (isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _currentIndex = i),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSlide(
                                offset:
                                    isSelected
                                        ? const Offset(0, -0.05)
                                        : Offset.zero,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(
                                  isSelected
                                      ? tab['activeIcon'] as IconData
                                      : tab['icon'] as IconData,
                                  size: 22,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tab['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color: color,
                                ),
                              ),
                              // Active dot
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 4,
                                width: isSelected ? 4 : 0,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? activeColor
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkSurface.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? AppColors.darkDivider.withValues(alpha: 0.3)
                    : AppColors.lightDivider.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar & Greeting
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF06D6A0)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (_userProfile?.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      _userProfile?.name ?? 'Người dùng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notification Bell
          GestureDetector(
            onTap: _openSettings,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      CupertinoIcons.bell,
                      size: 18,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesBar(bool isDark) {
    final stories = [
      {
        'emoji': '🏆',
        'label': 'Thử thách',
        'colors': [const Color(0xFFF59E0B), const Color(0xFFFF7F50)],
      },
      {
        'emoji': '💪',
        'label': 'Mục tiêu',
        'colors': [const Color(0xFF10B981), const Color(0xFF06D6A0)],
      },
      {
        'emoji': '🔥',
        'label': 'Streak',
        'colors': [const Color(0xFFEF4444), const Color(0xFFF97316)],
      },
      {
        'emoji': '⭐',
        'label': 'Thành tích',
        'colors': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      },
      {
        'emoji': '👥',
        'label': 'Bạn bè',
        'colors': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final colors = story['colors'] as List<Color>;
          return GestureDetector(
            onTap: _openCommunity,
            child: Container(
              width: 72,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          story['emoji'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthRings(
    bool isDark,
    double intake,
    double burned,
    double target,
  ) {
    // Use redesigned HealthRings component
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: HealthRings(
        consumed: intake,
        burned: burned,
        target: target,
        size: 200,
      ),
    );
  }

  Widget _buildMacroBars(bool isDark) {
    // TODO: Get actual macros from meal tracking once implemented
    // For now, use example values based on total calories
    final todayCalories = _todayRecord?.caloIntake ?? 0.0;
    final dailyTarget = _userProfile?.dailyTarget ?? 2000;

    // Estimate macros from total calories (rough approximation)
    // Assuming standard macro split: 30% protein, 40% carbs, 30% fat
    final protein = (todayCalories * 0.30) / 4; // 4 cal per gram
    final carbs = (todayCalories * 0.40) / 4;
    final fat = (todayCalories * 0.30) / 9; // 9 cal per gram

    // Calculate targets
    final proteinTarget = (dailyTarget * 0.30) / 4;
    final carbsTarget = (dailyTarget * 0.40) / 4;
    final fatTarget = (dailyTarget * 0.30) / 9;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dinh dưỡng hôm nay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          MacroBar(
            label: 'Protein',
            value: protein,
            max: proteinTarget,
            color: AppColors.primaryIndigo,
            size: MacroBarSize.small,
          ),
          const SizedBox(height: 12),
          MacroBar(
            label: 'Carbs',
            value: carbs,
            max: carbsTarget,
            color: AppColors.successGreen,
            size: MacroBarSize.small,
          ),
          const SizedBox(height: 12),
          MacroBar(
            label: 'Fat',
            value: fat,
            max: fatTarget,
            color: AppColors.warningOrange,
            size: MacroBarSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {
        'icon': CupertinoIcons.camera_fill,
        'label': 'Scan',
        'gradient': [const Color(0xFF10B981), const Color(0xFF06D6A0)],
        'shadow': const Color(0xFF10B981),
        'onTap': _openCamera,
      },
      {
        'icon': CupertinoIcons.flame_fill,
        'label': 'Gym',
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFFF7F50)],
        'shadow': const Color(0xFFF59E0B),
        'onTap': _openGymScheduler,
      },
      {
        'icon': CupertinoIcons.sparkles,
        'label': 'AI Chat',
        'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        'shadow': const Color(0xFF6366F1),
        'onTap': _openChatbot,
      },
      {
        'icon': CupertinoIcons.drop_fill,
        'label': 'Nước',
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
        'shadow': const Color(0xFF3B82F6),
        'onTap': () {},
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành động nhanh',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(actions.length, (i) {
              final action = actions[i];
              final gradient = action['gradient'] as List<Color>;
              final shadowColor = action['shadow'] as Color;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i > 0 ? 6 : 0,
                    right: i < actions.length - 1 ? 6 : 0,
                  ),
                  child: GestureDetector(
                    onTap: action['onTap'] as VoidCallback,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            action['label'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialActivityCard(bool isDark) {
    // Show only if there are friends
    if (_friends.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get online friends (limit to 3 most recent)
    final onlineFriends = _friends.where((f) => f.isOnline).take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.person_2_fill,
                size: 16,
                color: AppColors.communityTeal,
              ),
              const SizedBox(width: 8),
              Text(
                'Bạn bè đang hoạt động',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openCommunity,
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show online friends or empty state
          if (onlineFriends.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Chưa có bạn bè nào đang online',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            ...onlineFriends.asMap().entries.map((entry) {
              final index = entry.key;
              final friend = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 20),
                  _buildFriendActivityItem(friend, isDark),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFriendActivityItem(Friendship friend, bool isDark) {
    final displayName =
        friend.friendDisplayName ?? friend.friendUsername ?? 'Bạn bè';
    final timeAgo = _getTimeAgo(friend.lastSeen);

    return Row(
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.communityTeal, AppColors.successGreen],
            ),
            shape: BoxShape.circle,
          ),
          child:
              friend.friendAvatarUrl != null
                  ? ClipOval(
                    child: Image.network(
                      friend.friendAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Center(
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                    ),
                  )
                  : Center(
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              children: [
                TextSpan(
                  text: displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const TextSpan(text: ' đang online '),
                const TextSpan(text: '🟢'),
              ],
            ),
          ),
        ),
        Text(
          timeAgo,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime? time) {
    if (time == null) return 'Vừa xong';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  Widget _buildCommunityHighlight(bool isDark) {
    // Note: Community highlights feature is intentionally hidden
    // Will be enabled when backend data integration is complete
    return const SizedBox.shrink();
  }

  Widget _buildNextWorkoutCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.darkCard, AppColors.darkCard]
                  : [
                    const Color(0xFFF59E0B).withValues(alpha: 0.05),
                    const Color(0xFFFF7F50).withValues(alpha: 0.05),
                  ],
        ),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        ),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.arrow_up_right,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buổi tập tiếp theo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _nextGymSession?.timeStr ?? '18:00',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _nextGymSession?.gymType ?? 'Tập gym toàn thân',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dự kiến đốt cháy ~400 kcal · 45 phút',
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const WorkoutProgramScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFF7F50)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.play_fill, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Bắt đầu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF06D6A0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openCamera,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Icon(
              CupertinoIcons.camera_fill,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
