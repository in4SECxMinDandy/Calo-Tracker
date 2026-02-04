// Community Hub Screen - Modern Social Media Style
// Redesigned with Instagram/Facebook-like layout
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/unified_community_service.dart';
import '../../services/messaging_service.dart';
import '../../services/friends_service.dart';
import '../../models/post.dart';
import '../../models/community_group.dart';
import '../../models/challenge.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import '../auth/login_screen.dart';
import 'groups_screen.dart';
import 'challenges_screen.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';
import 'widgets/comment_sheet.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  final _communityService = UnifiedCommunityService();
  final _authService = SupabaseAuthService();
  final _messagingService = MessagingService();
  final _friendsService = FriendsService();
  final _scrollController = ScrollController();

  List<Post> _feedPosts = [];
  List<CommunityGroup> _myGroups = [];
  List<Challenge> _activeChallenges = [];
  bool _isLoading = true;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadMessageCount();
    _friendsService.goOnline();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _friendsService.goOffline();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _communityService.getFeedPosts(limit: 20),
        _communityService.getMyGroups(),
        _communityService.getActiveChallenges(limit: 5),
      ]);

      if (mounted) {
        setState(() {
          _feedPosts = results[0] as List<Post>;
          _myGroups = results[1] as List<CommunityGroup>;
          _activeChallenges = results[2] as List<Challenge>;
          _unreadNotifications = _communityService.isDemoMode ? 3 : 0;
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
        builder: (_) => LoginScreen(onLoginSuccess: _loadData),
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
    if (!_authService.isAuthenticated && !_communityService.isDemoMode) {
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
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.flame,
                          color: Colors.white,
                          size: 18,
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
                              Icon(
                                CupertinoIcons.sparkles,
                                size: 14,
                                color: AppColors.warningOrange,
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
          // Logo/Brand
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.heart_fill,
              color: Colors.white,
              size: 20,
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
        // Friends
        IconButton(
          icon: Icon(
            CupertinoIcons.person_2,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed:
              _authService.isAuthenticated || _communityService.isDemoMode
                  ? _openFriends
                  : _openLogin,
        ),
        // Messages
        IconButton(
          icon: Badge(
            isLabelVisible: _unreadMessages > 0,
            label: Text(_unreadMessages > 9 ? '9+' : '$_unreadMessages'),
            child: Icon(
              CupertinoIcons.chat_bubble,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          onPressed:
              _authService.isAuthenticated || _communityService.isDemoMode
                  ? _openMessages
                  : _openLogin,
        ),
        // Notifications
        IconButton(
          icon: Badge(
            isLabelVisible: _unreadNotifications > 0,
            label: Text('$_unreadNotifications'),
            child: Icon(
              CupertinoIcons.bell,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          onPressed:
              _authService.isAuthenticated || _communityService.isDemoMode
                  ? _openNotifications
                  : _openLogin,
        ),
        // Profile
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: _openLogin,
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
              color: const Color(0xFF6366f1),
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
              color: const Color(0xFFf59e0b),
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
              color: const Color(0xFF10b981),
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
                    colors: [Color(0xFFf59e0b), Color(0xFFef4444)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.flame_fill,
                  color: Colors.white,
                  size: 16,
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
            ElevatedButton.icon(
              onPressed: _createPost,
              icon: const Icon(CupertinoIcons.pencil),
              label: const Text('Tạo bài viết'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _createPost,
      backgroundColor: AppColors.primaryBlue,
      icon: const Icon(CupertinoIcons.pencil, color: Colors.white),
      label: const Text(
        'Đăng bài',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _handleLike(Post post) async {
    if (!_authService.isAuthenticated && !_communityService.isDemoMode) {
      _openLogin();
      return;
    }

    try {
      if (post.isLikedByMe == true) {
        await _communityService.unlikePost(post.id);
      } else {
        await _communityService.likePost(post.id);
      }
      _loadData();
    } catch (e) {
      // Handle error
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
