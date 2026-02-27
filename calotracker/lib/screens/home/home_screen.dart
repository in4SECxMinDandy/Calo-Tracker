// Home Screen - Modern Health & Social Wellness Ecosystem
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

import 'widgets/water_intake_widget.dart';
import 'widgets/level_badge_widget.dart';
import 'widgets/meal_suggestion_widget.dart';
import 'widgets/sleep_widget.dart';
import 'widgets/gamification_row.dart';
import 'widgets/nutrition_progress_ring_widget.dart';
import 'widgets/nutrition_macros_bar_widget.dart';
import '../community/community_hub_screen.dart';
import '../community/notifications_screen.dart';
import '../community/conversations_screen.dart';
import '../profile/profile_screen.dart';
import '../achievements/achievements_screen.dart';
import '../insights/insights_screen.dart';
import '../../services/unified_community_service.dart';
import '../../services/messaging_service.dart';

// ── Color palette ─────────────────────────────────────────────────────────────
class _WC {
  static const Color background = Color(0xFFF8F9FA);
}

// ─────────────────────────────────────────────────────────────────────────────
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
  int _totalUnreadCount = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;

  final _friendsService = FriendsService();
  final _communityService = UnifiedCommunityService();
  final _messagingService = MessagingService();

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

      int unreadCount = 0;
      List<Friendship> friends = [];

      try {
        if (_communityService.isAvailable) {
          final communityUnread =
              await _communityService.getUnreadNotificationCount();
          final messageUnread = await _messagingService.getUnreadCount();
          final pendingFriends = await _friendsService.getPendingRequests();
          unreadCount = communityUnread + messageUnread + pendingFriends.length;
          final loadedFriends = await _friendsService.getFriends();
          friends = loadedFriends;
        }
      } catch (e) {
        debugPrint('Error loading social data: $e');
      }

      Map<String, double> macros = {'protein': 0, 'carbs': 0, 'fat': 0};
      try {
        macros = await DatabaseService.getDailyMacros();
      } catch (e) {
        debugPrint('Error loading macros: $e');
      }

      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _todayRecord = todayRecord;
        _nextGymSession = nextGym;
        _friends = friends;
        _totalUnreadCount = unreadCount;
        _protein = macros['protein'] ?? 0;
        _carbs = macros['carbs'] ?? 0;
        _fat = macros['fat'] ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _openChatbot() => Navigator.push(
    context,
    CupertinoPageRoute(builder: (_) => ChatbotScreen(onMealAdded: _loadData)),
  );

  void _openCamera() => Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (_) => CameraScanScreen(onMealAdded: _loadData),
    ),
  );

  void _openGymScheduler() => Navigator.push(
    context,
    CupertinoPageRoute(
      builder:
          (_) => GymSchedulerScreen(
            existingSession: _nextGymSession,
            onSessionUpdated: _loadData,
          ),
    ),
  );

  void _openNotifications() => Navigator.push(
    context,
    CupertinoPageRoute(builder: (_) => const NotificationsScreen()),
  ).then((_) => _loadData());

  void _openConversations() => Navigator.push(
    context,
    CupertinoPageRoute(builder: (_) => const ConversationsScreen()),
  ).then((_) => _loadData());

  void _openCommunity() => Navigator.push(
    context,
    CupertinoPageRoute(builder: (_) => const CommunityHubScreen()),
  );

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng ☀️';
    if (h < 18) return 'Chào buổi chiều 🌤️';
    return 'Chào buổi tối 🌙';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyTarget = _userProfile?.dailyTarget ?? 2000;
    final intake = _todayRecord?.caloIntake ?? 0;
    final burned = _todayRecord?.caloBurned ?? 0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1B2E) : _WC.background,
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
      floatingActionButton: _currentIndex == 0 ? _buildScannerFAB() : null,
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
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
            SliverToBoxAdapter(child: _buildCompactHeader(isDark)),

            // ── Gamification Row (new, clean, neon-glow) ──────────────────
            SliverToBoxAdapter(
              child: GamificationRow(
                onItemTaps: [
                  _openCommunity,           // Thử thách
                  _openCommunity,           // Mục tiêu
                  _openCommunity,           // Streak
                  () => Navigator.push(     // Thành tích
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  ),
                  () => Navigator.push(     // Thống kê
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const InsightsScreen(),
                    ),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: _buildHealthRings(isDark, intake, burned, dailyTarget),
            ),
            SliverToBoxAdapter(child: _buildMacroBars(isDark)),
            SliverToBoxAdapter(child: _buildQuickActions(isDark)),
            SliverToBoxAdapter(child: _buildSocialActivityCard(isDark)),
            SliverToBoxAdapter(child: _buildNextWorkoutCard(isDark)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
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
                  const LevelBadgeWidget(),
                  const SizedBox(height: 16),
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

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark) {
    const tabs = [
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
                  // Animated active pill
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

  // ── Compact Header ────────────────────────────────────────────────────────
  Widget _buildCompactHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF2D2E47).withValues(alpha: 0.9)
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
          // Avatar & greeting
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1FBF8C),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1FBF8C).withValues(alpha: 0.3),
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
                        fontSize: 24,
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

          // Messages
          GestureDetector(
            onTap: _openConversations,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      CupertinoIcons.chat_bubble_2,
                      size: 20,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Notification Bell
          GestureDetector(
            onTap: _openNotifications,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      CupertinoIcons.bell,
                      size: 20,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (_totalUnreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _totalUnreadCount > 9 ? '9+' : '$_totalUnreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
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

  // ── Health Rings ──────────────────────────────────────────────────────────
  Widget _buildHealthRings(
    bool isDark,
    double intake,
    double burned,
    double target,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2E47) : Colors.white,
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
      child: NutritionProgressRingWidget(
        intake: intake,
        burned: burned,
        target: target,
      ),
    );
  }

  // ── Macro Bars ────────────────────────────────────────────────────────────
  Widget _buildMacroBars(bool isDark) {
    final dailyTarget = _userProfile?.dailyTarget ?? 2000;
    final proteinTarget = (dailyTarget * 0.30) / 4;
    final carbsTarget = (dailyTarget * 0.40) / 4;
    final fatTarget = (dailyTarget * 0.30) / 9;
    final hasData = _protein > 0 || _carbs > 0 || _fat > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2E47) : Colors.white,
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
          if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Chưa có dữ liệu hôm nay',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else ...[
            NutritionMacrosBarWidget(
              label: 'Protein',
              current: _protein,
              target: proteinTarget,
              barColor: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            NutritionMacrosBarWidget(
              label: 'Carbs',
              current: _carbs,
              target: carbsTarget,
              barColor: const Color(0xFFFFA500),
            ),
            const SizedBox(height: 12),
            NutritionMacrosBarWidget(
              label: 'Fat',
              current: _fat,
              target: fatTarget,
              barColor: const Color(0xFF7C3AED),
            ),
          ],
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
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

  // ── Social Activity Card ──────────────────────────────────────────────────
  Widget _buildSocialActivityCard(bool isDark) {
    if (_friends.isEmpty) return const SizedBox.shrink();

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
              return Column(
                children: [
                  if (entry.key > 0) const Divider(height: 20),
                  _buildFriendItem(entry.value, isDark),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Friendship friend, bool isDark) {
    final name = friend.friendDisplayName ?? friend.friendUsername ?? 'Bạn bè';
    final timeAgo = _getTimeAgo(friend.lastSeen);
    return Row(
      children: [
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
                              name[0].toUpperCase(),
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
                      name[0].toUpperCase(),
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
                const TextSpan(text: ' đang online 🟢'),
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
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  // ── Next Workout Card ─────────────────────────────────────────────────────
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
            onTap:
                () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const WorkoutProgramScreen(),
                  ),
                ),
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

  // ── Scanner FAB ───────────────────────────────────────────────────────────
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
