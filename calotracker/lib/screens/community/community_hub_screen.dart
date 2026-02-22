// Community Hub Screen - Modern Social Media Style
// Redesigned with Instagram/Facebook-like layout
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/unified_community_service.dart';
import '../../services/messaging_service.dart';
import '../../services/presence_service.dart';
import '../../models/post.dart';
import '../../models/community_group.dart';
import '../../models/challenge.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../theme/animated_app_icons.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;
import '../../widgets/glass_card.dart';
import '../auth/login_screen.dart';
import '../profile/my_profile_screen.dart';
import 'groups_screen.dart';
import 'challenges_screen.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';
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
  final _messagingService = MessagingService();
  final _presenceService = PresenceService();
  final _scrollController = ScrollController();

  List<Post> _feedPosts = [];
  List<CommunityGroup> _myGroups = [];
  List<Challenge> _activeChallenges = [];
  bool _isLoading = true;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;

  // Auth state subscription
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
    _loadMessageCount();
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
          _unreadNotifications = results[3] as int;
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

  void _openMessages() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const ConversationsScreen()),
    ).then((_) => _loadMessageCount());
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

  Future<void> _loadMessageCount() async {
    if (!_authService.isAuthenticated) return;
    try {
      final count = await _messagingService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadMessages = count);
      }
    } catch (_) {}
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
              // Modern App Bar
              _buildAppBar(isDark),

              // Stories / Quick Groups
              SliverToBoxAdapter(child: _buildStoriesSection(isDark)),

              // Quick Actions Bar
              SliverToBoxAdapter(child: _buildQuickActions(isDark)),

              // Active Challenges Banner (Horizontal)
              if (_activeChallenges.isNotEmpty)
                SliverToBoxAdapter(child: _buildChallengesBanner(isDark)),

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
                              AppColors.communityOrange.withValues(alpha: 0.7),
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
                      Text('Bảng tin mới nhất', style: AppTextStyles.heading3),
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
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      toolbarHeight: 65,
      title: Row(
        children: [
          // Logo/Brand — Facebook-style community icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1877F2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.person_3_fill,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cộng đồng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Kết nối & chia sẻ',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(
              CupertinoIcons.search,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              debugPrint(
                'Search button pressed, isAuth: ${_authService.isAuthenticated}',
              );
              if (_authService.isAuthenticated) {
                _openSearch();
              } else {
                _openLogin();
              }
            },
            tooltip: 'Tìm kiếm',
          ),
        ),
        // Friends - Increased touch target
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(
              CupertinoIcons.person_2,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              debugPrint(
                'Friends button pressed, isAuth: ${_authService.isAuthenticated}',
              );
              if (_authService.isAuthenticated) {
                _openFriends();
              } else {
                _openLogin();
              }
            },
          ),
        ),
        // Messages - Increased touch target
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Badge(
              isLabelVisible: _unreadMessages > 0,
              label: Text(_unreadMessages > 9 ? '9+' : '$_unreadMessages'),
              child: AnimatedAppIcons.messageCircle(
                size: 24,
                color: isDark ? Colors.white70 : Colors.black54,
                trigger: lucide.AnimationTrigger.onTap,
              ),
            ),
            onPressed: () {
              debugPrint(
                'Messages button pressed, isAuth: ${_authService.isAuthenticated}',
              );
              if (_authService.isAuthenticated) {
                _openMessages();
              } else {
                _openLogin();
              }
            },
          ),
        ),
        // Notifications
        IconButton(
          icon: Badge(
            isLabelVisible: _unreadNotifications > 0,
            label: Text('$_unreadNotifications'),
            child: AnimatedAppIcons.bell(
              size: 24,
              color: isDark ? Colors.white70 : Colors.black54,
              trigger: lucide.AnimationTrigger.onTap,
            ),
          ),
          onPressed:
              _authService.isAuthenticated ? _openNotifications : _openLogin,
        ),
        // Profile
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (_authService.isAuthenticated) {
                // Navigate to profile screen
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const MyProfileScreen()),
                );
              } else {
                _openLogin();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient:
                    _authService.isAuthenticated
                        ? const LinearGradient(
                          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                        )
                        : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _authService.isAuthenticated
                    ? CupertinoIcons.person_fill
                    : CupertinoIcons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: CupertinoIcons.group_solid,
              label: 'Nhóm',
              color: AppColors.communityTeal,
              onTap:
                  () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const GroupsScreen()),
                  ),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildQuickActionButton(
              icon: CupertinoIcons.flag_fill,
              label: 'Thử thách',
              color: AppColors.communityOrange,
              onTap:
                  () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const ChallengesScreen(),
                    ),
                  ),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildQuickActionButton(
              icon: CupertinoIcons.chart_bar_alt_fill,
              label: 'Bảng xếp hạng',
              color: AppColors.primaryIndigo,
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const LeaderboardScreen()),
                );
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesBanner(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.communityOrange, AppColors.warningCoral],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedAppIcons.flame(
                  size: 16,
                  color: Colors.white,
                  trigger: lucide.AnimationTrigger.onTap,
                ),
              ),
              const SizedBox(width: 10),
              Text('Thử thách HOT', style: AppTextStyles.heading3),
              const Spacer(),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const ChallengesScreen(),
                      ),
                    ),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _activeChallenges.length,
            itemBuilder: (context, index) {
              return _buildChallengeCard(_activeChallenges[index], isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(Challenge challenge, bool isDark) {
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: GlassCard(
        onTap: () {
          // Navigate to challenge detail
        },
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: challenge.challengeType.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    challenge.challengeType.icon,
                    color: challenge.challengeType.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  CupertinoIcons.person_2_fill,
                  size: 14,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${challenge.participantCount} người',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: challenge.challengeType.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${challenge.remainingTime.inDays} ngày',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildFAB(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'community_fab',
        onPressed: _createPost,
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        icon: AnimatedAppIcons.plus(
          size: 22,
          color: Colors.white,
          trigger: lucide.AnimationTrigger.onTap,
        ),
        label: const Text(
          'Đăng bài',
          style: TextStyle(
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
