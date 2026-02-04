// Home Screen - Modern Health & Social Wellness Ecosystem
// Redesigned with Apple Health + Strava + Instagram aesthetics
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import '../../models/user_profile.dart';
import '../../models/calo_record.dart';
import '../../models/gym_session.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';
import '../chatbot/chatbot_screen.dart';
import '../camera/camera_scan_screen.dart';
import '../gym/gym_scheduler_screen.dart';
import '../history/history_screen.dart';
import '../workout/workout_program_screen.dart';
import '../healthy_food/healthy_food_screen.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/water_intake_widget.dart';
import 'widgets/weight_progress_widget.dart';
import 'widgets/level_badge_widget.dart';
import '../barcode/barcode_scanner_screen.dart';
import 'widgets/meal_suggestion_widget.dart';
import 'widgets/sleep_widget.dart';
import '../community/community_hub_screen.dart';
import '../../theme/app_icons.dart';
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
  bool _isLoading = true;
  int _currentIndex = 0;

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

      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _todayRecord = todayRecord;
        _nextGymSession = nextGym;
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

  void _openHistory() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const HistoryScreen()),
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

                  // Weight Progress
                  WeightProgressWidget(onWeightAdded: _loadData),
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
                AppIcons.home,
                AppIcons.homeOutline,
                'Trang chủ',
                isDark,
              ),
              _buildNavItem(
                1,
                AppIcons.community,
                AppIcons.communityOutline,
                'Cộng đồng',
                isDark,
              ),
              _buildNavItem(
                2,
                AppIcons.statistics,
                AppIcons.statisticsOutline,
                'Lịch sử',
                isDark,
              ),
              _buildNavItem(3, AppIcons.ai, AppIcons.ai, 'AI', isDark),
              _buildNavItem(
                4,
                AppIcons.profile,
                AppIcons.profileOutline,
                'Hồ sơ',
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
    IconData iconActive,
    IconData iconInactive,
    String label,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    final color =
        isSelected
            ? WellnessColors.sageGreen
            : (isDark ? Colors.white54 : Colors.black45);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? iconActive : iconInactive,
                color: color,
                size: 24,
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
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 16,
                    color: WellnessColors.lavender,
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

          // Settings
          GestureDetector(
            onTap: _openSettings,
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
              child: Icon(
                CupertinoIcons.gear,
                size: 18,
                color: isDark ? Colors.white70 : WellnessColors.warmGray,
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
        'color': WellnessColors.coral,
      },
      {
        'icon': AppIcons.group,
        'label': 'Bạn bè tập',
        'color': WellnessColors.skyBlue,
      },
      {
        'icon': AppIcons.heart,
        'label': 'Giảm cân',
        'color': WellnessColors.peach,
      },
      {
        'icon': AppIcons.calories,
        'label': 'Trending',
        'color': WellnessColors.lavender,
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
                  WellnessColors.coral,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildRingLegend(
                  'Vận động',
                  '${burned.toInt()}/500 kcal',
                  WellnessColors.sageGreen,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildRingLegend(
                  'Hoạt động',
                  '7/10 giờ',
                  WellnessColors.skyBlue,
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
      {'icon': AppIcons.statistics, 'label': 'Thống kê', 'onTap': _openHistory},
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
                color: WellnessColors.skyBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Hoạt động bạn bè',
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
          // Activity items
          _buildActivityItem(
            'Minh',
            'vừa chạy 5km',
            '🏃',
            '2 phút trước',
            isDark,
          ),
          const Divider(height: 20),
          _buildActivityItem(
            'Lan',
            'đạt mục tiêu 10k bước',
            '🎯',
            '15 phút trước',
            isDark,
          ),
          const Divider(height: 20),
          _buildActivityItem(
            'Hùng',
            'hoàn thành thử thách giảm cân',
            '🏆',
            '1 giờ trước',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String name,
    String action,
    String emoji,
    String time,
    bool isDark,
  ) {
    return Row(
      children: [
        // Avatar stack simulation
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [WellnessColors.mint, WellnessColors.sageGreen],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name[0],
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
                  text: name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextSpan(text: ' $action '),
                TextSpan(text: emoji),
              ],
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityHighlight(bool isDark) {
    return GestureDetector(
      onTap: _openCommunity,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WellnessColors.lavender.withValues(alpha: 0.8),
              WellnessColors.peach.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.flame_fill,
                        size: 14,
                        color: WellnessColors.coral,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Trending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thử thách Đón Tết Healthy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Avatar stack
                      SizedBox(
                        width: 60,
                        height: 24,
                        child: Stack(
                          children: List.generate(
                            3,
                            (i) => Positioned(
                              left: i * 18.0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color:
                                      [
                                        WellnessColors.coral,
                                        WellnessColors.skyBlue,
                                        WellnessColors.mint,
                                      ][i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ['A', 'B', 'C'][i],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '234 người tham gia',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
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
      onPressed: _openCamera,
      backgroundColor: WellnessColors.sageGreen,
      child: const Icon(
        CupertinoIcons.leaf_arrow_circlepath,
        color: Colors.white,
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
        'color': WellnessColors.coral,
      },
      {
        'radius': size.width / 2 - 20,
        'progress': exerciseProgress,
        'color': WellnessColors.sageGreen,
      },
      {
        'radius': size.width / 2 - 35,
        'progress': standProgress,
        'color': WellnessColors.skyBlue,
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
