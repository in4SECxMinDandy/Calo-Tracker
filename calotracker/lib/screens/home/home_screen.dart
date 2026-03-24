// ============================================================
// HomeScreen - Trang chủ CaloTracker
// Modern Clean UI với Material 3 + Glassmorphism
// Hệ thống lưới 8pt, Scale transitions, Animated icons
// ============================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../models/calo_record.dart';
import '../../models/friendship.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/friends_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/biometric_service.dart';
import '../../theme/colors.dart';

import '../chatbot/chatbot_screen.dart';
import '../camera/camera_scan_screen.dart';
import '../gym/gym_premium_ui.dart';
import '../history/history_screen.dart';
import '../workout/workout_program_screen.dart';
import '../community/community_hub_screen.dart';
import '../community/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../achievements/achievements_screen.dart';
import '../insights/insights_screen.dart';

import 'widgets/water_intake_widget.dart';
import 'widgets/level_badge_widget.dart';
import 'widgets/meal_suggestion_widget.dart';
import 'widgets/sleep_widget.dart';
import 'widgets/nutrition_progress_ring_widget.dart';
import 'widgets/nutrition_macros_bar_widget.dart';

import '../../services/unified_community_service.dart';
import '../../services/messaging_service.dart';
import '../../services/presence_service.dart';
import '../../models/user_presence.dart';
import '../../utils/time_formatter.dart';

// ── Hằng số thiết kế (8pt grid system) ───────────────────────────────────────
class _DS {
  // Spacing (bội số của 8)
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s48 = 48.0;
  static const double s56 = 56.0;

  // Border radius
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;

  // Màu nền
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color bgDark = Color(0xFF0F0F1A);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1A1B2E);
}

// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
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

  // HistoryRefreshController để có thể gọi refresh HistoryScreen từ bên ngoài
  final HistoryRefreshController _historyRefreshCtrl = HistoryRefreshController();

  // ── Timer (để cancel Future.delayed khi dispose) ──────────────────────────
  Timer? _animTimer;

  // ── Services ──────────────────────────────────────────────────────────────
  final _friendsService = FriendsService();
  final _communityService = UnifiedCommunityService();
  final _messagingService = MessagingService();
  final _presenceService = PresenceService();

  Map<String, UserPresence> _presenceMap = {};
  StreamSubscription? _presenceSubscription;

  // ── Animation Controllers ─────────────────────────────────────────────────
  late AnimationController _headerAnimCtrl;
  late AnimationController _cardsAnimCtrl;
  late AnimationController _fabAnimCtrl;

  late Animation<double> _headerFadeAnim;
  late Animation<Offset> _headerSlideAnim;
  late Animation<double> _cardsFadeAnim;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    // Header animation: fade + slide từ trên xuống
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOut,
    );
    _headerSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOutCubic),
    );

    // Cards animation: fade in
    _cardsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardsFadeAnim = CurvedAnimation(
      parent: _cardsAnimCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    // FAB animation: scale bounce
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _headerAnimCtrl.dispose();
    _cardsAnimCtrl.dispose();
    _fabAnimCtrl.dispose();
    _presenceSubscription?.cancel();
    _presenceService.unsubscribeFromPresence();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────
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
          friends = await _friendsService.getFriends();

          if (friends.isNotEmpty) {
            final friendIds = friends.map((f) => f.friendId).toList();
            final pm = await _presenceService.getBatchPresence(friendIds);
            if (mounted) {
              setState(() => _presenceMap = pm);
            }
            
            _presenceSubscription?.cancel();
            _presenceSubscription = _presenceService.presenceStream.listen((p) {
              if (mounted) setState(() => _presenceMap[p.userId] = p);
            });
            _presenceService.subscribeToPresence(friendIds);
          }
        }
      } catch (e) {
        debugPrint('Lỗi tải dữ liệu xã hội: $e');
      }

      Map<String, double> macros = {'protein': 0, 'carbs': 0, 'fat': 0};
      try {
        macros = await DatabaseService.getDailyMacros();
      } catch (e) {
        debugPrint('Lỗi tải macros: $e');
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

      // Khởi động animations sau khi dữ liệu đã load
      // Reset trước để hỗ trợ pull-to-refresh chạy lại animation
      _headerAnimCtrl.reset();
      _headerAnimCtrl.forward();
      _animTimer?.cancel();
      _animTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          _cardsAnimCtrl.reset();
          _cardsAnimCtrl.forward();
          _fabAnimCtrl.reset();
          _fabAnimCtrl.forward();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Refresh dữ liệu nhẹ (không show loading spinner) — dùng khi thêm nước/bữa ăn
  /// để tránh làm toàn bộ dashboard biến mất.
  Future<void> _refreshDataSilently() async {
    if (!mounted) return;
    try {
      final todayRecord = await DatabaseService.getTodayRecord();
      Map<String, double> macros = {'protein': 0, 'carbs': 0, 'fat': 0};
      try {
        macros = await DatabaseService.getDailyMacros();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _todayRecord = todayRecord;
        _protein = macros['protein'] ?? 0;
        _carbs = macros['carbs'] ?? 0;
        _fat = macros['fat'] ?? 0;
      });

      // Refresh HistoryScreen để đồng bộ dữ liệu
      _historyRefreshCtrl.refresh();
    } catch (e) {
      debugPrint('Silent refresh error: $e');
    }
  }

  // ── Navigation Helpers ────────────────────────────────────────────────────
  void _openChatbot() => Navigator.push(
    context,
    _buildPageRoute(ChatbotScreen(
      onMealAdded: _refreshDataSilently,
      onSleepAdded: _refreshDataSilently,
      onWaterAdded: _refreshDataSilently,
    )),
  );

  void _openCamera() => Navigator.push(
    context,
    _buildPageRoute(CameraScanScreen(onMealAdded: _loadData)),
  );

  void _openGymScheduler() =>
      Navigator.push(context, _buildPageRoute(const GymSchedulePage()));

  void _openNotifications() => Navigator.push(
    context,
    _buildPageRoute(const NotificationsScreen()),
  ).then((_) => _loadData());

  Future<void> _openCommunity() async {
    final biometricEnabled = StorageService.isBiometricEnabled();
    if (biometricEnabled) {
      final result = await BiometricService.authenticate(
        reason: 'Xác thực sinh trắc học để mở Cộng đồng',
      );
      if (!result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ?? 'Xác thực sinh trắc học thất bại',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(context, _buildPageRoute(const CommunityHubScreen()));
  }

  /// Tạo CupertinoPageRoute với hiệu ứng chuyển cảnh mượt mà
  CupertinoPageRoute<T> _buildPageRoute<T>(Widget page) {
    return CupertinoPageRoute<T>(builder: (_) => page);
  }

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

    return Scaffold(
      backgroundColor: isDark ? _DS.bgDark : _DS.bgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(isDark),
          const CommunityHubScreen(),
          HistoryScreen(controller: _historyRefreshCtrl),
          // Truyền callback để refresh HomeScreen và HistoryScreen khi thêm dữ liệu từ AI
          ChatbotScreen(
            onMealAdded: _refreshDataSilently,
            onSleepAdded: _refreshDataSilently,
            onWaterAdded: _refreshDataSilently,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
      floatingActionButton:
          _currentIndex == 0 ? _buildScannerFAB(isDark) : null,
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Widget _buildDashboard(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 16),
            const SizedBox(height: _DS.s16),
            Text(
              'Đang tải dữ liệu...',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final dailyTarget = _userProfile?.dailyTarget ?? 2000;
    final intake = _todayRecord?.caloIntake ?? 0;
    final burned = _todayRecord?.caloBurned ?? 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _headerSlideAnim,
                child: FadeTransition(
                  opacity: _headerFadeAnim,
                  child: _buildCompactHeader(isDark),
                ),
              ),
            ),

            // ── Health Rings ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _cardsFadeAnim,
                child: _buildHealthRings(
                  isDark,
                  intake,
                  burned,
                  dailyTarget.toDouble(),
                ),
              ),
            ),

            // ── Macro Bars ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _cardsFadeAnim,
                child: _buildMacroBars(isDark),
              ),
            ),

            // ── Quick Actions ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _cardsFadeAnim,
                child: _buildQuickActions(isDark),
              ),
            ),

            // ── Social Activity ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _cardsFadeAnim,
                child: _buildSocialActivityCard(isDark),
              ),
            ),

            // ── Next Workout ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _cardsFadeAnim,
                child: _buildNextWorkoutCard(isDark),
              ),
            ),

            // ── Water & Sleep + Level + Meal Suggestion ──────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: _DS.s20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: _DS.s16),
                  FadeTransition(
                    opacity: _cardsFadeAnim,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: WaterIntakeWidget(onWaterAdded: _refreshDataSilently),
                          ),
                          const SizedBox(width: _DS.s12),
                          const Expanded(child: SleepWidget()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: _DS.s16),
                  FadeTransition(
                    opacity: _cardsFadeAnim,
                    child: const LevelBadgeWidget(),
                  ),
                  const SizedBox(height: _DS.s16),
                  FadeTransition(
                    opacity: _cardsFadeAnim,
                    child: MealSuggestionWidget(onMealAdded: _loadData),
                  ),
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
    // Định nghĩa các tab với icon đồng bộ (CupertinoIcons)
    const tabs = [
      (
        icon: CupertinoIcons.house,
        activeIcon: CupertinoIcons.house_fill,
        label: 'Trang chủ',
      ),
      (
        icon: CupertinoIcons.person_3,
        activeIcon: CupertinoIcons.person_3_fill,
        label: 'Cộng đồng',
      ),
      (
        icon: CupertinoIcons.chart_bar,
        activeIcon: CupertinoIcons.chart_bar_fill,
        label: 'Lịch sử',
      ),
      (
        icon: CupertinoIcons.sparkles,
        activeIcon: CupertinoIcons.sparkles,
        label: 'AI',
      ),
      (
        icon: CupertinoIcons.person_circle,
        activeIcon: CupertinoIcons.person_circle_fill,
        label: 'Hồ sơ',
      ),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color:
                    isDark
                        ? AppColors.darkDivider.withValues(alpha: 0.4)
                        : AppColors.lightDivider.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  final tab = tabs[i];
                  final isSelected = _currentIndex == i;
                  final activeColor =
                      i == 1 ? AppColors.facebookBlue : AppColors.primaryBlue;
                  final inactiveColor =
                      isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary;

                  return Expanded(
                    child: _AnimatedTabItem(
                      icon: tab.icon,
                      activeIcon: tab.activeIcon,
                      label: tab.label,
                      isSelected: isSelected,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = i);
                        // Khi chuyển sang tab Lịch sử (index 2), tự động refresh
                        if (i == 2) {
                          _historyRefreshCtrl.refresh();
                        }
                      },
                    ),
                  );
                }),
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
      padding: const EdgeInsets.fromLTRB(_DS.s20, _DS.s12, _DS.s20, _DS.s12),
      decoration: BoxDecoration(
        color:
            isDark
                ? _DS.cardDark.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? AppColors.darkDivider.withValues(alpha: 0.3)
                    : AppColors.lightDivider.withValues(alpha: 0.4),
            width: 0.5,
          ),
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
      child: Row(
        children: [
          // ── Avatar & Greeting ──────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Avatar với gradient và shadow
                _ScaleTapWidget(
                  onTap: () => setState(() => _currentIndex = 4),
                  child: Container(
                    width: _DS.s48,
                    height: _DS.s48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1FBF8C), Color(0xFF06D6A0)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1FBF8C,
                          ).withValues(alpha: 0.35),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _DS.s12),
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
                    const SizedBox(height: 2),
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

          // ── Action Buttons ─────────────────────────────────────────────
          Row(
            children: [
              // Nút Thành tích
              _ScaleTapWidget(
                onTap:
                    () => Navigator.push(
                      context,
                      _buildPageRoute(const AchievementsScreen()),
                    ),
                child: _HeaderIconButton(
                  isDark: isDark,
                  child: Icon(
                    CupertinoIcons.rosette,
                    size: 18,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: _DS.s8),

              // Nút Thống kê
              _ScaleTapWidget(
                onTap:
                    () => Navigator.push(
                      context,
                      _buildPageRoute(const InsightsScreen()),
                    ),
                child: _HeaderIconButton(
                  isDark: isDark,
                  child: Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    size: 18,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: _DS.s8),

              // Nút thông báo với badge
              _ScaleTapWidget(
                onTap: _openNotifications,
                child: _HeaderIconButton(
                  isDark: isDark,
                  badge: _totalUnreadCount > 0 ? _totalUnreadCount : null,
                  child: Icon(
                    CupertinoIcons.bell,
                    size: 18,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
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
    return _GlassCard(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(_DS.s20, _DS.s16, _DS.s20, 0),
      padding: const EdgeInsets.all(_DS.s20),
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

    return _GlassCard(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(_DS.s20, _DS.s16, _DS.s20, 0),
      padding: const EdgeInsets.all(_DS.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(_DS.r8),
                ),
                child: const Icon(
                  CupertinoIcons.chart_pie_fill,
                  size: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: _DS.s8),
              Text(
                'Dinh dưỡng hôm nay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: _DS.s16),
          if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: _DS.s12),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      size: 32,
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(height: _DS.s8),
                    Text(
                      'Chưa có dữ liệu hôm nay',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            NutritionMacrosBarWidget(
              label: 'Protein',
              current: _protein,
              target: proteinTarget,
              barColor: AppColors.errorRed,
            ),
            const SizedBox(height: _DS.s12),
            NutritionMacrosBarWidget(
              label: 'Carbs',
              current: _carbs,
              target: carbsTarget,
              barColor: AppColors.warningOrange,
            ),
            const SizedBox(height: _DS.s12),
            NutritionMacrosBarWidget(
              label: 'Fat',
              current: _fat,
              target: fatTarget,
              barColor: AppColors.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      _QuickAction(
        icon: CupertinoIcons.camera_fill,
        label: 'Scan',
        gradient: const [Color(0xFF10B981), Color(0xFF06D6A0)],
        shadowColor: const Color(0xFF10B981),
        onTap: _openCamera,
      ),
      _QuickAction(
        icon: CupertinoIcons.flame_fill,
        label: 'Gym',
        gradient: const [Color(0xFFF59E0B), Color(0xFFFF7F50)],
        shadowColor: const Color(0xFFF59E0B),
        onTap: _openGymScheduler,
      ),
      _QuickAction(
        icon: CupertinoIcons.sparkles,
        label: 'AI Chat',
        gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        shadowColor: const Color(0xFF6366F1),
        onTap: _openChatbot,
      ),
      _QuickAction(
        icon: CupertinoIcons.doc_richtext,
        label: 'Báo cáo',
        gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        shadowColor: const Color(0xFF3B82F6),
        onTap: () => _showPdfExportSheet(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s20, _DS.s16, _DS.s20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành động nhanh',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: _DS.s12),
          Row(
            children: List.generate(actions.length, (i) {
              final action = actions[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? _DS.s8 : 0),
                  child: _ScaleTapWidget(
                    onTap: action.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: _DS.s16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: action.gradient,
                        ),
                        borderRadius: BorderRadius.circular(_DS.r16),
                        boxShadow: [
                          BoxShadow(
                            color: action.shadowColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(action.icon, size: 22, color: Colors.white),
                          const SizedBox(height: _DS.s4),
                          Text(
                            action.label,
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

    final onlineFriends = _friends.where((f) {
      final presence = _presenceMap[f.friendId];
      return presence?.isOnline ?? f.isOnline;
    }).take(3).toList();

    return _GlassCard(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(_DS.s20, _DS.s16, _DS.s20, 0),
      padding: const EdgeInsets.all(_DS.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.communityTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(_DS.r8),
                ),
                child: const Icon(
                  CupertinoIcons.person_2_fill,
                  size: 14,
                  color: AppColors.communityTeal,
                ),
              ),
              const SizedBox(width: _DS.s8),
              Text(
                'Bạn bè đang hoạt động',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              _ScaleTapWidget(
                onTap: _openCommunity,
                child: Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _DS.s12),
          if (onlineFriends.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: _DS.s16),
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
                  if (entry.key > 0)
                    Divider(
                      height: _DS.s20,
                      color:
                          isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                    ),
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
    
    final presence = _presenceMap[friend.friendId];
    final isOnline = presence?.isOnline ?? friend.isOnline;
    final timeAgo = isOnline ? 'Đang online' : _getTimeAgo(presence, friend);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
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
        const SizedBox(width: _DS.s12),
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
                TextSpan(
                  text: isOnline ? ' đang online 🟢' : ' ⚪',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
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

  String _getTimeAgo(UserPresence? presence, Friendship friend) {
    if (presence != null) {
      final diff = DateTime.now().difference(presence.lastSeen);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      return '${diff.inDays} ngày trước';
    }
    
    if (friend.lastSeen != null) {
      return formatTimeAgo(friend.lastSeen!);
    }
    
    return 'Gần đây';
  }

  // ── Next Workout Card ─────────────────────────────────────────────────────
  Widget _buildNextWorkoutCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(_DS.s20, _DS.s16, _DS.s20, 0),
      padding: const EdgeInsets.all(_DS.s20),
      decoration: BoxDecoration(
        color: isDark ? _DS.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(_DS.r20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [_DS.cardDark, _DS.cardDark]
                  : [const Color(0xFFFFFBEB), const Color(0xFFFFF7ED)],
        ),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFF7F50)],
                  ),
                  borderRadius: BorderRadius.circular(_DS.r12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.flame_fill,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: _DS.s12),
              Expanded(
                child: Text(
                  'Buổi tập tiếp theo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _DS.s12,
                  vertical: _DS.s4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(_DS.r20),
                ),
                child: Text(
                  _nextGymSession?.timeStr ?? '18:00',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _DS.s12),
          Text(
            _nextGymSession?.gymType ?? 'Tập gym toàn thân',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: _DS.s4),
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
          const SizedBox(height: _DS.s16),
          _ScaleTapWidget(
            onTap:
                () => Navigator.push(
                  context,
                  _buildPageRoute(const WorkoutProgramScreen()),
                ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: _DS.s12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFF7F50)],
                ),
                borderRadius: BorderRadius.circular(_DS.r12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.play_fill, size: 16, color: Colors.white),
                  SizedBox(width: _DS.s8),
                  Text(
                    'Bắt đầu tập',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
  Widget _buildScannerFAB(bool isDark) {
    return ScaleTransition(
      scale: _fabScaleAnim,
      child: _ScaleTapWidget(
        onTap: _openCamera,
        child: Container(
          width: _DS.s56,
          height: _DS.s56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF06D6A0)],
            ),
            borderRadius: BorderRadius.circular(_DS.r16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Widget tab item với animation khi chọn
class _AnimatedTabItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedTabItem> createState() => _AnimatedTabItemState();
}

class _AnimatedTabItemState extends State<_AnimatedTabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(_AnimatedTabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder:
                  (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                widget.isSelected ? widget.activeIcon : widget.icon,
                key: ValueKey(widget.isSelected),
                size: 22,
                color:
                    widget.isSelected
                        ? widget.activeColor
                        : widget.inactiveColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  widget.isSelected ? FontWeight.w700 : FontWeight.normal,
              color:
                  widget.isSelected ? widget.activeColor : widget.inactiveColor,
            ),
            child: Text(widget.label),
          ),
          // Dot indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 3,
            width: widget.isSelected ? 16 : 0,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color:
                  widget.isSelected ? widget.activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget với hiệu ứng Scale khi nhấn (thay thế InkWell)
class _ScaleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTapWidget({required this.child, required this.onTap});

  @override
  State<_ScaleTapWidget> createState() => _ScaleTapWidgetState();
}

class _ScaleTapWidgetState extends State<_ScaleTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95, // Scale factor for tap animation
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
  }
}

/// Card với hiệu ứng Glassmorphism
class _GlassCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const _GlassCard({
    required this.isDark,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? _DS.cardDark : _DS.cardLight,
        borderRadius: BorderRadius.circular(_DS.r20),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkDivider.withValues(alpha: 0.3)
                  : AppColors.lightDivider.withValues(alpha: 0.5),
          width: 0.5,
        ),
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
      child: child,
    );
  }
}

/// Icon button trong header
class _HeaderIconButton extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final int? badge;

  const _HeaderIconButton({
    required this.isDark,
    required this.child,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            borderRadius: BorderRadius.circular(_DS.r12),
          ),
          child: Center(child: child),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.errorRed,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge! > 9 ? '9+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS (internal)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF EXPORT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

void _showPdfExportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => _PdfExportSheet(
          isDark: Theme.of(context).brightness == Brightness.dark,
          onExport: (type, start, end) async {
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Đang tạo báo cáo PDF...'),
                duration: Duration(seconds: 2),
              ),
            );
            try {
              final pdfService = PdfExportService();
              await pdfService.exportAndShare(
                type: type,
                startDate: start,
                endDate: end,
              );
            } catch (e) {
              if (!context.mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Lỗi xuất PDF: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
  );
}

/// Bottom sheet chọn loại báo cáo PDF và khoảng thời gian
class _PdfExportSheet extends StatefulWidget {
  final bool isDark;
  final void Function(PdfReportType type, DateTime start, DateTime end)
  onExport;

  const _PdfExportSheet({required this.isDark, required this.onExport});

  @override
  State<_PdfExportSheet> createState() => _PdfExportSheetState();
}

class _PdfExportSheetState extends State<_PdfExportSheet> {
  PdfReportType _selectedType = PdfReportType.fullHealth;
  int _selectedPeriod = 0; // 0=tuần này, 1=tháng này, 2=3 tháng

  final _periods = [('7 ngày qua', 7), ('Tháng này', 30), ('3 tháng', 90)];

  final _reportTypes = [
    (
      PdfReportType.fullHealth,
      'Sức khỏe toàn diện',
      CupertinoIcons.heart_fill,
      Color(0xFF6366F1),
    ),
    (
      PdfReportType.nutrition,
      'Dinh dưỡng',
      CupertinoIcons.chart_pie_fill,
      Color(0xFF10B981),
    ),
    (
      PdfReportType.meals,
      'Chi tiết bữa ăn',
      CupertinoIcons.cart_fill,
      Color(0xFFF59E0B),
    ),
    (
      PdfReportType.workouts,
      'Lịch tập gym',
      CupertinoIcons.flame_fill,
      Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF1A1B2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF2D2D4A) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tiêu đề
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_richtext,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xuất báo cáo PDF',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Hỗ trợ đầy đủ tiếng Việt',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: dividerColor),

          // Chọn loại báo cáo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Loại báo cáo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.2,
              children:
                  _reportTypes.map((item) {
                    final isSelected = _selectedType == item.$1;
                    return _ScaleTapWidget(
                      onTap: () => setState(() => _selectedType = item.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? item.$4.withValues(alpha: 0.12)
                                  : (isDark
                                      ? const Color(0xFF252640)
                                      : const Color(0xFFF9FAFB)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? item.$4 : dividerColor,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.$3,
                              size: 16,
                              color: isSelected ? item.$4 : textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                  color: isSelected ? item.$4 : textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Chọn khoảng thời gian
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Khoảng thời gian',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_periods.length, (i) {
                final isSelected = _selectedPeriod == i;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                    child: _ScaleTapWidget(
                      onTap: () => setState(() => _selectedPeriod = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primaryBlue
                                  : (isDark
                                      ? const Color(0xFF252640)
                                      : const Color(0xFFF9FAFB)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primaryBlue
                                    : dividerColor,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _periods[i].$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Nút xuất
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ScaleTapWidget(
              onTap: () {
                final now = DateTime.now();
                final days = _periods[_selectedPeriod].$2;
                final startDate = now.subtract(Duration(days: days));
                widget.onExport(_selectedType, startDate, now);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.doc_richtext,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Xuất PDF ngay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
