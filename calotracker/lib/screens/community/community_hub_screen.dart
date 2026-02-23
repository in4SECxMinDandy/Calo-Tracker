// Community Hub Screen - Modern Social Media Style
// Redesigned with Instagram/Facebook-like layout
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/unified_community_service.dart';

import '../../services/presence_service.dart';
import '../../models/post.dart';
import '../../models/community_group.dart';
import '../../models/challenge.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../theme/animated_app_icons.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;

import '../auth/login_screen.dart';
import 'groups_screen.dart';
import 'challenges_screen.dart';
import 'notifications_screen.dart';

import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';
import 'widgets/comment_sheet.dart';
import '../search/global_search_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  final _communityService = UnifiedCommunityService();
  final _authService = SupabaseAuthService();

  final _presenceService = PresenceService();
  final _scrollController = ScrollController();

  List<Post> _feedPosts = [];
  List<CommunityGroup> _myGroups = [];
  List<Challenge> _activeChallenges = [];
  bool _isLoading = true;

  // Tab state: 0 = Feed, 1 = Challenges
  int _selectedTab = 0;

  // Auth state subscription
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
    _presenceService.goOnline();

    // Listen for auth state changes
    _authSubscription = _authService.authStateChanges.listen((authState) {
      if (mounted) {
        // Reload when auth state changes
        _checkAuthAndLoadData();
      }
    });
  }

  Future<void> _checkAuthAndLoadData() async {
    // Check if user is authenticated
    if (!_authService.isAuthenticated) {
      // User is not authenticated, require login
      // Set loading to false to show empty state
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    // User is authenticated, load data
    _loadData();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _scrollController.dispose();
    _presenceService.goOffline();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _communityService.getFeedPosts(limit: 20),
        _communityService.getMyGroups(),
        _communityService.getActiveChallenges(limit: 5),
        _communityService.getUnreadNotificationCount(),
      ]);

      if (mounted) {
        setState(() {
          _feedPosts = results[0] as List<Post>;
          _myGroups = results[1] as List<CommunityGroup>;
          _activeChallenges = results[2] as List<Challenge>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLogin() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder:
            (_) => LoginScreen(
              onLoginSuccess: () {
                // Reload data after successful login
                _loadData();
              },
            ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openFriends() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const FriendsScreen()),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const GlobalSearchScreen()),
    );
  }

  void _createPost() {
    if (!_authService.isAuthenticated) {
      _openLogin();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CreatePostSheet(
            onPostCreated: (post) {
              setState(() {
                _feedPosts.insert(0, post);
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar (always visible)
              _buildAppBar(isDark),

              // ── Feed Tab Content (index 0) ──
              if (_selectedTab == 0) ...[
                // Stories / Quick Groups
                SliverToBoxAdapter(child: _buildStoriesSection(isDark)),

                // Quick Actions Bar
                SliverToBoxAdapter(child: _buildQuickActions(isDark)),

                // Feed Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.communityOrange,
                                AppColors.communityOrange.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AnimatedAppIcons.flame(
                            size: 18,
                            color: Colors.white,
                            trigger: lucide.AnimationTrigger.onTap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Bảng tin mới nhất',
                          style: AppTextStyles.heading3,
                        ),
                        const Spacer(),
                        if (_communityService.isDemoMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedAppIcons.ai(
                                  size: 14,
                                  color: AppColors.warningOrange,
                                  trigger: lucide.AnimationTrigger.onHover,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Demo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warningOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Feed Posts
                _isLoading
                    ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : !_authService.isAuthenticated
                    ? SliverFillRemaining(child: _buildLoginRequired(isDark))
                    : _feedPosts.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyFeed(isDark))
                    : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: PostCard(
                            post: _feedPosts[index],
                            onLike: () => _handleLike(_feedPosts[index]),
                            onComment: () => _handleComment(_feedPosts[index]),
                          ),
                        ),
                        childCount: _feedPosts.length,
                      ),
                    ),
              ],

              // ── Challenges Tab Content (index 1) ──
              if (_selectedTab == 1) ...[
                // Featured Challenge Banner
                SliverToBoxAdapter(
                  child: _buildFeaturedChallengeBanner(isDark),
                ),

                // Active Challenges Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.flag_fill,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Thử thách đang diễn ra',
                          style: AppTextStyles.heading3,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => const ChallengesScreen(),
                                ),
                              ),
                          child: Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Challenge Items List
                _isLoading
                    ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                    : !_authService.isAuthenticated
                    ? SliverFillRemaining(child: _buildLoginRequired(isDark))
                    : _activeChallenges.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyChallenges(isDark))
                    : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: _buildChallengeListItem(
                            _activeChallenges[index],
                            isDark,
                          ),
                        ),
                        childCount: _activeChallenges.length,
                      ),
                    ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.darkCard.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
          border: Border(
            bottom: BorderSide(
              color:
                  isDark
                      ? AppColors.darkDivider.withValues(alpha: 0.3)
                      : AppColors.lightDivider.withValues(alpha: 0.6),
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  // Top row: Title + Actions
                  Row(
                    children: [
                      // Title & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cộng đồng',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.025 * 24,
                                color:
                                    isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1,234 thành viên đang hoạt động',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color:
                                    isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search button
                      GestureDetector(
                        onTap: () {
                          if (_authService.isAuthenticated) {
                            _openSearch();
                          } else {
                            _openLogin();
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkMuted : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppColors.darkDivider
                                      : AppColors.lightDivider,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            CupertinoIcons.search,
                            size: 18,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bell button
                      GestureDetector(
                        onTap:
                            _authService.isAuthenticated
                                ? _openNotifications
                                : _openLogin,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkMuted : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppColors.darkDivider
                                      : AppColors.lightDivider,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.bell,
                                size: 18,
                                color:
                                    isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                              ),
                              // Red dot badge
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
                                      color:
                                          isDark
                                              ? AppColors.darkCard
                                              : Colors.white,
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
                  const SizedBox(height: 12),
                  // Tab Switcher — Segmented control
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Bảng tin', 0, isDark),
                        _buildTabButton('Thử thách', 1, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int tabIndex, bool isDark) {
    final isActive = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != tabIndex) {
            setState(() => _selectedTab = tabIndex);
            // Scroll to top when switching tabs
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive
                    ? (isDark ? AppColors.darkCard : Colors.white)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color:
                  isActive
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesSection(bool isDark) {
    // Combine groups as "stories" - removed 'Thêm mới' button
    final items = [
      ..._myGroups
          .take(6)
          .map((g) => {'type': 'group', 'group': g, 'name': g.name}),
      ...GroupCategory.values
          .take(5)
          .map((c) => {'type': 'category', 'category': c, 'name': c.label}),
    ];

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildStoryItem(item, isDark, index == 0);
        },
      ),
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> item, bool isDark, bool isFirst) {
    final isGroup = item['type'] == 'group';

    Color bgColor;
    IconData icon;

    if (isGroup) {
      final group = item['group'] as CommunityGroup;
      bgColor = group.category.color;
      icon = group.category.icon;
    } else {
      final category = item['category'] as GroupCategory;
      bgColor = category.color;
      icon = category.icon;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const GroupsScreen()),
        );
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient:
                    isFirst
                        ? null
                        : LinearGradient(
                          colors: [bgColor, bgColor.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                color: isFirst ? null : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isFirst
                          ? AppColors.primaryBlue
                          : bgColor.withValues(alpha: 0.3),
                  width: isFirst ? 2 : 3,
                  style: isFirst ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bgColor, bgColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['name'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final stats = [
      {
        'icon': CupertinoIcons.person_2_fill,
        'label': 'Bạn bè',
        'value': '12',
        'color': const Color(0xFF3B82F6),
        'onTap': () {
          if (_authService.isAuthenticated) {
            _openFriends();
          } else {
            _openLogin();
          }
        },
      },
      {
        'icon': CupertinoIcons.flag_fill,
        'label': 'Thử thách',
        'value': '3 đang diễn ra',
        'color': const Color(0xFFF59E0B),
        'onTap':
            () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const ChallengesScreen()),
            ),
      },
      {
        'icon': CupertinoIcons.chart_bar_alt_fill,
        'label': 'Xếp hạng',
        'value': 'Top 5',
        'color': const Color(0xFF10B981),
        'onTap':
            () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children:
            stats.map((stat) {
              final color = stat['color'] as Color;
              final icon = stat['icon'] as IconData;
              return Expanded(
                child: GestureDetector(
                  onTap: stat['onTap'] as VoidCallback,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                stat['value'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDark
                                          ? AppColors.darkTextTertiary
                                          : AppColors.lightTextTertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLoginRequired(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.lock_shield,
                size: 48,
                color: AppColors.warningOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text('Cần đăng nhập', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đăng nhập để xem\nvà tương tác với cộng đồng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _openLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 2,
                shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.person_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeed(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.bubble_left_bubble_right,
                size: 48,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text('Chưa có bài viết nào', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Hãy là người đầu tiên chia sẻ\ncâu chuyện của bạn!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 2,
                shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.pencil, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tạo bài viết',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── CHALLENGES TAB — Featured Banner
  // ══════════════════════════════════════════════════════════════
  Widget _buildFeaturedChallengeBanner(bool isDark) {
    // Use first active challenge as featured, or show a demo banner
    final featured =
        _activeChallenges.isNotEmpty ? _activeChallenges.first : null;
    final title = featured?.title ?? '30 Ngày Ăn Sạch';
    final description =
        featured?.description ??
        'Thử thách bạn ăn sạch trong 30 ngày liên tiếp. Ghi lại mỗi bữa ăn để hoàn thành mục tiêu!';
    final participants = featured?.participantCount ?? 1234;
    final daysLeft = featured?.remainingTime.inDays ?? 25;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF0D9488), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.star_fill,
                          size: 12,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Thử thách nổi bật',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_2_fill,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$participants người tham gia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$daysLeft ngày còn lại',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Join button
                  GestureDetector(
                    onTap: () {
                      if (featured != null) {
                        _joinChallengeFromHub(featured);
                      } else {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const ChallengesScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.bolt_fill,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tham gia ngay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── CHALLENGES TAB — Challenge List Item with Progress Bar
  // ══════════════════════════════════════════════════════════════
  Widget _buildChallengeListItem(Challenge challenge, bool isDark) {
    final daysLeft = challenge.remainingTime.inDays;
    final progress = challenge.progressPercentage;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ChallengesScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: icon + title + days badge
            Row(
              children: [
                // Category icon with circular bg
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        challenge.challengeType.color,
                        challenge.challengeType.color.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: challenge.challengeType.color.withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    challenge.challengeType.icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + participant count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.person_2_fill,
                            size: 13,
                            color:
                                isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${challenge.participantCount} người tham gia',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Days remaining badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: challenge.challengeType.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: challenge.challengeType.color.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Text(
                    daysLeft > 0 ? '$daysLeft ngày còn lại' : 'Hôm nay',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: challenge.challengeType.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (progress / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              challenge.challengeType.color,
                              challenge.challengeType.color.withValues(
                                alpha: 0.7,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: challenge.challengeType.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── CHALLENGES TAB — Empty State
  // ══════════════════════════════════════════════════════════════
  Widget _buildEmptyChallenges(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.flag_fill,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text('Chưa có thử thách', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Hãy khám phá và tham gia các\nthử thách từ cộng đồng!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ChallengesScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 2,
                shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.flag_fill, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Khám phá thử thách',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── JOIN CHALLENGE (from Hub)
  // ══════════════════════════════════════════════════════════════
  Future<void> _joinChallengeFromHub(Challenge challenge) async {
    if (!_authService.isAuthenticated) {
      _openLogin();
      return;
    }

    try {
      final result = await _communityService.joinChallenge(challenge.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Đã tham gia "${challenge.title}"',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildFAB(bool isDark) {
    final isFeedTab = _selectedTab == 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isFeedTab ? AppColors.primaryBlue : const Color(0xFF4F46E5))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'community_fab',
        onPressed:
            isFeedTab
                ? _createPost
                : () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ChallengesScreen()),
                ),
        backgroundColor:
            isFeedTab ? AppColors.primaryBlue : const Color(0xFF4F46E5),
        elevation: 0,
        icon: AnimatedAppIcons.plus(
          size: 22,
          color: Colors.white,
          trigger: lucide.AnimationTrigger.onTap,
        ),
        label: Text(
          isFeedTab ? 'Đăng bài' : 'Tạo thử thách',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleLike(Post post) async {
    if (!_authService.isAuthenticated) {
      _openLogin();
      return;
    }

    // Optimistic update
    final postIndex = _feedPosts.indexWhere((p) => p.id == post.id);
    if (postIndex == -1) return;

    final isLiked = post.isLikedByMe == true;
    setState(() {
      _feedPosts[postIndex] = post.copyWith(
        isLikedByMe: !isLiked,
        likeCount: isLiked ? post.likeCount - 1 : post.likeCount + 1,
      );
    });

    try {
      if (isLiked) {
        await _communityService.unlikePost(post.id);
      } else {
        await _communityService.likePost(post.id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _feedPosts[postIndex] = post;
      });
    }
  }

  void _handleComment(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(post: post),
    );
  }
}
