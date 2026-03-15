// Community Hub Screen - Complete Redesign
// Modern social fitness community with full feature set
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/unified_community_service.dart';
import '../../services/presence_service.dart';
import '../../services/gamification_service.dart';
import '../../models/post.dart';
import '../../models/community_group.dart';
import '../../models/challenge.dart';
import '../../models/achievement.dart';
import '../../theme/colors.dart';
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
import 'post_detail_screen.dart';

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
  List<UserAchievement> _recentAchievements = [];
  bool _isLoading = true;
  int _unreadNotifications = 0;

  // Tab state: 0=Feed, 1=Challenges, 2=Groups, 3=Leaderboard
  int _selectedTab = 0;

  StreamSubscription<AuthState>? _authSubscription;

  static const _tabs = [
    {'icon': CupertinoIcons.house_fill, 'label': 'Bảng tin'},
    {'icon': CupertinoIcons.flag_fill, 'label': 'Thử thách'},
    {'icon': CupertinoIcons.person_3_fill, 'label': 'Nhóm'},
    {'icon': CupertinoIcons.chart_bar_alt_fill, 'label': 'Xếp hạng'},
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
    _presenceService.goOnline();

    _authSubscription = _authService.authStateChanges.listen((authState) {
      if (mounted) _checkAuthAndLoadData();
    });
  }

  Future<void> _checkAuthAndLoadData() async {
    if (!_authService.isAuthenticated) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
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
      await GamificationService.checkAndUnlockAchievements();
      final results = await Future.wait([
        _communityService.getFeedPosts(limit: 20),
        _communityService.getMyGroups(),
        _communityService.getActiveChallenges(limit: 5),
        _communityService.getUnreadNotificationCount(),
      ]);
      final recentAchievements = GamificationService.getRecentAchievements();

      if (mounted) {
        setState(() {
          _feedPosts = results[0] as List<Post>;
          _myGroups = results[1] as List<CommunityGroup>;
          _activeChallenges = results[2] as List<Challenge>;
          _unreadNotifications = results[3] as int;
          _recentAchievements = recentAchievements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openLogin() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => LoginScreen(onLoginSuccess: _loadData),
      ),
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
      builder: (_) => CreatePostSheet(
        onPostCreated: (post) {
          setState(() => _feedPosts.insert(0, post));
        },
      ),
    );
  }

  void _handleLike(Post post) async {
    try {
      final idx = _feedPosts.indexWhere((p) => p.id == post.id);
      if (idx == -1) return;
      final wasLiked = _feedPosts[idx].isLikedByMe ?? false;
      // Optimistic update
      if (mounted) {
        setState(() {
          _feedPosts[idx] = _feedPosts[idx].copyWith(
            isLikedByMe: !wasLiked,
            likeCount: _feedPosts[idx].likeCount + (wasLiked ? -1 : 1),
          );
        });
      }
      if (wasLiked) {
        await _communityService.unlikePost(post.id);
      } else {
        await _communityService.likePost(post.id);
      }
    } catch (_) {}
  }

  void _handleComment(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(post: post),
    ).then((_) {
      // Refresh comment count after sheet closes
      final idx = _feedPosts.indexWhere((p) => p.id == post.id);
      if (idx != -1 && mounted) {
        setState(() {
          _feedPosts[idx] = _feedPosts[idx].copyWith(
            commentCount: _feedPosts[idx].commentCount + 1,
          );
        });
      }
    });
  }

  void _switchTab(int index) {
    if (_selectedTab == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = index);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar ──
            _buildTopBar(isDark),

            // ── Tab Navigation ──
            _buildTabBar(isDark),

            // ── Content ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primaryBlue,
                child: _buildContent(isDark),
              ),
            ),
          ],
        ),
      ),
      // FAB removed - create post prompt in feed is sufficient
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════
  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo + Title
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.person_3_fill,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cộng đồng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  _communityService.isDemoMode
                      ? 'Chế độ demo'
                      : 'Kết nối & chia sẻ',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Search
          _buildIconButton(
            icon: CupertinoIcons.search,
            isDark: isDark,
            onTap: () {
              if (_authService.isAuthenticated) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const GlobalSearchScreen(),
                  ),
                );
              } else {
                _openLogin();
              }
            },
          ),
          const SizedBox(width: 8),

          // Friends
          _buildIconButton(
            icon: CupertinoIcons.person_badge_plus,
            isDark: isDark,
            onTap: () {
              if (_authService.isAuthenticated) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const FriendsScreen()),
                );
              } else {
                _openLogin();
              }
            },
          ),
          const SizedBox(width: 8),

          // Notifications
          _buildIconButton(
            icon: CupertinoIcons.bell,
            isDark: isDark,
            badge: _unreadNotifications > 0 ? _unreadNotifications : null,
            onTap: () {
              if (_authService.isAuthenticated) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ).then((_) => _loadData());
              } else {
                _openLogin();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB BAR
  // ══════════════════════════════════════════════════════════════
  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 52,
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppColors.primaryBlue
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabs[i]['icon'] as IconData,
                      size: 18,
                      color: isActive
                          ? AppColors.primaryBlue
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tabs[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.primaryBlue
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // CONTENT SWITCHER
  // ══════════════════════════════════════════════════════════════
  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_authService.isAuthenticated) {
      return _buildLoginRequired(isDark);
    }

    switch (_selectedTab) {
      case 0:
        return _buildFeedTab(isDark);
      case 1:
        return _buildChallengesTab(isDark);
      case 2:
        return _buildGroupsTab(isDark);
      case 3:
        return _buildLeaderboardTab(isDark);
      default:
        return _buildFeedTab(isDark);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // FEED TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildFeedTab(bool isDark) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Stories / Quick Groups
        SliverToBoxAdapter(child: _buildStoriesRow(isDark)),

        // Create Post Prompt
        SliverToBoxAdapter(child: _buildCreatePostPrompt(isDark)),

        // Achievement Highlights
        if (_recentAchievements.isNotEmpty)
          SliverToBoxAdapter(child: _buildAchievementHighlights(isDark)),

        // Feed Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.square_stack_3d_up_fill,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Bảng tin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                if (_communityService.isDemoMode) _buildDemoBadge(),
              ],
            ),
          ),
        ),

        // Posts
        _feedPosts.isEmpty
            ? SliverFillRemaining(child: _buildEmptyFeed(isDark))
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: PostCard(
                      post: _feedPosts[index],
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => PostDetailScreen(
                            postId: _feedPosts[index].id,
                            initialPost: _feedPosts[index],
                          ),
                        ),
                      ),
                      onLike: () => _handleLike(_feedPosts[index]),
                      onComment: () => _handleComment(_feedPosts[index]),
                      onDelete: (postId) {
                        setState(() {
                          _feedPosts.removeWhere((p) => p.id == postId);
                        });
                      },
                      onEdit: (updatedPost) {
                        setState(() {
                          final idx = _feedPosts.indexWhere(
                            (p) => p.id == updatedPost.id,
                          );
                          if (idx != -1) _feedPosts[idx] = updatedPost;
                        });
                      },
                    ),
                  ),
                  childCount: _feedPosts.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStoriesRow(bool isDark) {
    final items = [
      {'type': 'add', 'name': 'Đăng bài'},
      ..._myGroups.take(6).map((g) => {
            'type': 'group',
            'group': g,
            'name': g.name,
          }),
    ];

    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item['type'] == 'add') {
            return _buildAddStoryItem(isDark);
          }
          return _buildStoryItem(item, isDark);
        },
      ),
    );
  }

  Widget _buildAddStoryItem(bool isDark) {
    return GestureDetector(
      onTap: _createPost,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Đăng bài',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
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
  }

  Widget _buildStoryItem(Map<String, dynamic> item, bool isDark) {
    Color bgColor;
    IconData icon;

    if (item['type'] == 'group') {
      final group = item['group'] as CommunityGroup;
      bgColor = group.category.color;
      icon = group.category.icon;
    } else {
      final category = item['category'] as GroupCategory;
      bgColor = category.color;
      icon = category.icon;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const GroupsScreen()),
      ),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor, bgColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: bgColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              item['name'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
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
  }

  Widget _buildCreatePostPrompt(bool isDark) {
    final user = _authService.currentUser;
    return GestureDetector(
      onTap: _createPost,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE9EEF5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chia sẻ điều mới hôm nay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thành tích · Bữa ăn · Buổi tập · Ảnh',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.add_circled_solid,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Đăng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
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
  // CHALLENGES TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildChallengesTab(bool isDark) {
    return CustomScrollView(
      slivers: [
        // Featured Challenge Banner
        SliverToBoxAdapter(child: _buildFeaturedChallengeBanner(isDark)),

        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.flag_fill,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thử thách đang diễn ra',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const ChallengesScreen(),
                    ),
                  ),
                  child: const Text(
                    'Xem tất cả →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Challenge Cards
        _activeChallenges.isEmpty
            ? SliverFillRemaining(child: _buildEmptyChallenges(isDark))
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: _buildChallengeCard(
                      _activeChallenges[index],
                      isDark,
                    ),
                  ),
                  childCount: _activeChallenges.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildFeaturedChallengeBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔥 Thử thách nổi bật',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '30 ngày\nThay đổi thói quen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const ChallengesScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tham gia ngay',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_activeChallenges.length} thử thách',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, bool isDark) {
    final progress = challenge.participantCount > 0
        ? (challenge.participantCount / 100).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const ChallengesScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        challenge.challengeType.color,
                        challenge.challengeType.color.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    challenge.challengeType.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${challenge.participantCount} người tham gia',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: challenge.challengeType.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    challenge.challengeType.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: challenge.challengeType.color,
                    ),
                  ),
                ),
              ],
            ),
            if (challenge.description != null) ...[
              const SizedBox(height: 10),
              Text(
                challenge.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  challenge.challengeType.color,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${challenge.participantCount} người tham gia',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  _getDaysLeft(challenge.endDate),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  String _getDaysLeft(DateTime? endDate) {
    if (endDate == null) return 'Không giới hạn';
    final diff = endDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Đã kết thúc';
    if (diff == 0) return 'Hôm nay kết thúc';
    return 'Còn $diff ngày';
  }

  // ══════════════════════════════════════════════════════════════
  // GROUPS TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildGroupsTab(bool isDark) {
    return CustomScrollView(
      slivers: [
        // My Groups Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_3_fill,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Nhóm của tôi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const GroupsScreen()),
                  ),
                  child: const Text(
                    'Xem tất cả →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // My Groups List
        _myGroups.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyGroups(isDark))
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: _buildGroupCard(_myGroups[index], isDark),
                  ),
                  childCount: _myGroups.length,
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildGroupCard(CommunityGroup group, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const GroupsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    group.category.color,
                    group.category.color.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(group.category.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} thành viên • ${group.category.label}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: group.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Xem',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: group.category.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // LEADERBOARD TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildLeaderboardTab(bool isDark) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.star_fill,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Bảng xếp hạng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const LeaderboardScreen(),
                  ),
                ),
                child: const Text(
                  'Xem đầy đủ →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Open Full Leaderboard Button
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bảng xếp hạng cộng đồng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Xem thứ hạng của bạn so với\ncộng đồng CaloTracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      '🏆 Xem bảng xếp hạng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementHighlights(bool isDark) {
    final displayAchievements = _recentAchievements.take(6).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE9EEF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.rosette,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Huy hiệu mới mở',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                '${_recentAchievements.length} huy hiệu',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayAchievements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final achievement = displayAchievements[index].achievement;
                if (achievement == null) return const SizedBox.shrink();
                return _AchievementChip(
                  achievement: achievement,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // EMPTY STATES
  // ══════════════════════════════════════════════════════════════
  Widget _buildLoginRequired(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
                CupertinoIcons.person_3_fill,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tham gia cộng đồng',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Đăng nhập để kết nối với hàng nghìn\nngười dùng CaloTracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // Feature list
            ...[
              '🏆 Chia sẻ thành tích & tiến độ',
              '👥 Kết bạn & theo dõi nhau',
              '🎯 Tham gia thử thách cộng đồng',
              '📊 Xem bảng xếp hạng',
            ].map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        feature,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeed(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.bubble_left_bubble_right_fill,
                size: 48,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có bài viết nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy là người đầu tiên chia sẻ\ncâu chuyện của bạn!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createPost,
              icon: const Icon(CupertinoIcons.pencil),
              label: const Text('Đăng bài đầu tiên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChallenges(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.flag_fill,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có thử thách',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo thử thách đầu tiên\ncho cộng đồng!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const ChallengesScreen()),
              ),
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Tạo thử thách'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGroups(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.person_3_fill,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa tham gia nhóm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khám phá và tham gia các nhóm\nphù hợp với bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const GroupsScreen()),
            ),
            icon: const Icon(CupertinoIcons.search),
            label: const Text('Khám phá nhóm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'Demo',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.warningOrange,
        ),
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final Achievement achievement;
  final bool isDark;

  const _AchievementChip({required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: achievement.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _titleForAchievement(achievement.titleKey),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _titleForAchievement(String key) {
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
}

