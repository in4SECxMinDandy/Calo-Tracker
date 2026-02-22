// Home Screen - Modern Health & Social Wellness Ecosystem
// Redesigned with Apple Health + Strava + Instagram aesthetics
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
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
import '../healthy_food/healthy_food_screen.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/water_intake_widget.dart';

import 'widgets/level_badge_widget.dart';
import '../barcode/barcode_scanner_screen.dart';
import 'widgets/meal_suggestion_widget.dart';
import 'widgets/sleep_widget.dart';
import '../community/community_hub_screen.dart';
import '../../theme/app_icons.dart';
import '../../theme/animated_app_icons.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;
import '../profile/profile_screen.dart';

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

  late AnimationController _ringAnimationController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringAnimationController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _ringAnimationController.dispose();
    super.dispose();
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
      _ringAnimationController.forward(from: 0);
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
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                CupertinoIcons.house,
                CupertinoIcons.house_fill,
                'Trang chủ',
                isDark,
              ),
              _buildNavItem(
                1,
                CupertinoIcons.person_3,
                CupertinoIcons.person_3_fill,
                'Cộng đồng',
                isDark,
                activeColor: const Color(0xFF1877F2), // Facebook blue
              ),
              _buildNavItem(
                2,
                CupertinoIcons.chart_bar,
                CupertinoIcons.chart_bar_fill,
                'Lịch sử',
                isDark,
              ),
              _buildNavItem(
                3,
                CupertinoIcons.sparkles,
                CupertinoIcons.sparkles,
                'AI',
                isDark,
              ),
              _buildNavItem(
                4,
                CupertinoIcons.person,
                CupertinoIcons.person_fill,
                'Cá nhân',
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    bool isDark, {
    Color? activeColor,
  }) {
    final isSelected = _currentIndex == index;
    final selectedColor = activeColor ?? WellnessColors.sageGreen;
    final color =
        isSelected ? selectedColor : (isDark ? Colors.white54 : Colors.black45);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
            // Active indicator bar (Facebook-style)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 20 : 0,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                    gradient: LinearGradient(
                      colors: [WellnessColors.sageGreen, WellnessColors.mint],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (_userProfile?.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        fontSize: 13,
                        color:
                            isDark ? Colors.white60 : WellnessColors.warmGray,
                      ),
                    ),
                    Text(
                      _userProfile?.name ?? 'Bạn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // AI Assistant Badge
          GestureDetector(
            onTap: _openChatbot,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(12),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedAppIcons.ai(
                    size: 16,
                    color: WellnessColors.lavender,
                    trigger: lucide.AnimationTrigger.onTap,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Settings - Increased touch target
          GestureDetector(
            onTap: _openSettings,
            behavior: HitTestBehavior.opaque,
            child: Container(
              // Ensure minimum 44x44 touch target
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                child: AnimatedAppIcons.settings(
                  size: 18,
                  color: isDark ? Colors.white70 : WellnessColors.warmGray,
                  trigger: lucide.AnimationTrigger.onTap,
                ),
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
        'icon': AppIcons.flag,
        'label': 'Thử thách tuần',
        'color': AppColors.communityOrange,
      },
      {
        'icon': AppIcons.group,
        'label': 'Bạn bè tập',
        'color': AppColors.communityTeal,
      },
      {
        'icon': AppIcons.heart,
        'label': 'Giảm cân',
        'color': AppColors.successGreen,
      },
      {
        'icon': AppIcons.calories,
        'label': 'Trending',
        'color': AppColors.primaryIndigo,
      },
      {
        'icon': AppIcons.star,
        'label': 'Thành tích',
        'color': WellnessColors.mint,
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
          return GestureDetector(
            onTap: _openCommunity,
            child: Container(
              width: 72,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (story['color'] as Color),
                          (story['color'] as Color).withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (story['color'] as Color).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      story['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
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
    final moveProgress = (intake / target).clamp(0.0, 1.0);
    final exerciseProgress = (burned / 500).clamp(
      0.0,
      1.0,
    ); // 500 cal exercise goal
    final standProgress = 0.7; // Mock: 7/10 hours standing

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
      child: Row(
        children: [
          // Three rings - Apple Watch style
          AnimatedBuilder(
            animation: _ringAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: HealthRingsPainter(
                    moveProgress: moveProgress * _ringAnimation.value,
                    exerciseProgress: exerciseProgress * _ringAnimation.value,
                    standProgress: standProgress * _ringAnimation.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(moveProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'mục tiêu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 20),

          // Ring legends
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRingLegend(
                  'Calories',
                  '${intake.toInt()}/${target.toInt()} kcal',
                  AppColors.primaryIndigo,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildRingLegend(
                  'Vận động',
                  '${burned.toInt()}/500 kcal',
                  AppColors.successGreen,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildRingLegend(
                  'Hoạt động',
                  '7/10 giờ',
                  AppColors.communityTeal,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingLegend(
    String title,
    String value,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'icon': AppIcons.scan, 'label': 'Scan', 'onTap': _openCamera},
      {
        'icon': AppIcons.barcode,
        'label': 'Mã vạch',
        'onTap': () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => BarcodeScannerScreen(onMealAdded: _loadData),
            ),
          );
        },
      },
      {
        'icon': AppIcons.calendar,
        'label': 'Lịch tập',
        'onTap': _openGymScheduler,
      },
      {
        'icon': AppIcons.leaf,
        'label': 'Dinh dưỡng',
        'onTap': () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const HealthyFoodScreen()),
          );
        },
      },
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: action['onTap'] as VoidCallback,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(22),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    action['icon'] as IconData,
                    size: 16,
                    color: isDark ? Colors.white70 : WellnessColors.warmGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    action['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const WorkoutProgramScreen()),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [WellnessColors.coral, WellnessColors.peach],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.flame_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bài tập tiếp theo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _nextGymSession?.gymType ?? 'Cardio buổi sáng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: WellnessColors.mint.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _nextGymSession?.timeStr ?? '7:00',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: WellnessColors.sageGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerFAB() {
    return FloatingActionButton(
      heroTag: 'home_scanner_fab',
      onPressed: _openCamera,
      backgroundColor: WellnessColors.sageGreen,
      child: AnimatedAppIcons.leaf(
        size: 24,
        color: Colors.white,
        trigger: lucide.AnimationTrigger.onTap,
      ),
    );
  }
}

// Custom painter for Apple Watch-style health rings
class HealthRingsPainter extends CustomPainter {
  final double moveProgress;
  final double exerciseProgress;
  final double standProgress;

  HealthRingsPainter({
    required this.moveProgress,
    required this.exerciseProgress,
    required this.standProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;

    // Colors for each ring
    final rings = [
      {
        'radius': size.width / 2 - 5,
        'progress': moveProgress,
        'color': AppColors.primaryIndigo,
      },
      {
        'radius': size.width / 2 - 20,
        'progress': exerciseProgress,
        'color': AppColors.successGreen,
      },
      {
        'radius': size.width / 2 - 35,
        'progress': standProgress,
        'color': AppColors.communityTeal,
      },
    ];

    for (final ring in rings) {
      final radius = ring['radius'] as double;
      final progress = ring['progress'] as double;
      final color = ring['color'] as Color;

      // Background ring
      final bgPaint =
          Paint()
            ..color = color.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bgPaint);

      // Progress arc
      final progressPaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HealthRingsPainter oldDelegate) {
    return oldDelegate.moveProgress != moveProgress ||
        oldDelegate.exerciseProgress != exerciseProgress ||
        oldDelegate.standProgress != standProgress;
  }
}
