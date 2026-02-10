// My Profile Screen
// User profile with tabs: My Posts, Liked Posts, Saved Posts
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/community_service.dart';
import '../../services/storage_service.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../community/widgets/post_card.dart';
import '../community/widgets/comment_sheet.dart';
import '../auth/login_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = SupabaseAuthService();
  final _communityService = CommunityService();
  late TabController _tabController;

  UserProfile? _userProfile;
  String? _displayName;
  String? _avatarUrl;
  bool _isAuthenticated = false;

  // Tab data
  List<Post> _myPosts = [];
  List<Post> _likedPosts = [];
  List<Post> _savedPosts = [];

  bool _isLoadingMyPosts = false;
  bool _isLoadingLiked = false;
  bool _isLoadingSaved = false;

  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAuth();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _checkAuth() {
    setState(() {
      _isAuthenticated = _authService.isAuthenticated;
    });

    if (_isAuthenticated) {
      _loadProfile();
      _loadTabData(0); // Load first tab
    } else {
      // Not authenticated, do nothing
    }
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((authState) {
      if (mounted) {
        setState(() {
          _isAuthenticated = authState.session != null;
        });

        if (_isAuthenticated) {
          _loadProfile();
          _loadTabData(_tabController.index);
        }
      }
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        _loadTabData(_tabController.index);
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      // Load local profile
      _userProfile = StorageService.getUserProfile();

      // Load Supabase profile for display name and avatar
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final profileData = await _authService.getUserProfileById(userId);
        if (profileData != null && mounted) {
          setState(() {
            _displayName = profileData['display_name'] ?? _userProfile?.name;
            _avatarUrl = profileData['avatar_url'];
          });
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadTabData(int tabIndex) async {
    switch (tabIndex) {
      case 0:
        await _loadMyPosts();
        break;
      case 1:
        await _loadLikedPosts();
        break;
      case 2:
        await _loadSavedPosts();
        break;
    }
  }

  Future<void> _loadMyPosts() async {
    if (_isLoadingMyPosts || !_isAuthenticated) return;

    setState(() => _isLoadingMyPosts = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final posts = await _communityService.getUserPosts(userId);
        if (mounted) {
          setState(() {
            _myPosts = posts;
            _isLoadingMyPosts = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading my posts: $e');
      if (mounted) {
        setState(() => _isLoadingMyPosts = false);
      }
    }
  }

  Future<void> _loadLikedPosts() async {
    if (_isLoadingLiked || !_isAuthenticated) return;

    setState(() => _isLoadingLiked = true);

    try {
      final posts = await _communityService.getLikedPosts();
      if (mounted) {
        setState(() {
          _likedPosts = posts;
          _isLoadingLiked = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading liked posts: $e');
      if (mounted) {
        setState(() => _isLoadingLiked = false);
      }
    }
  }

  Future<void> _loadSavedPosts() async {
    if (_isLoadingSaved || !_isAuthenticated) return;

    setState(() => _isLoadingSaved = true);

    try {
      final posts = await _communityService.getSavedPosts();
      if (mounted) {
        setState(() {
          _savedPosts = posts;
          _isLoadingSaved = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved posts: $e');
      if (mounted) {
        setState(() => _isLoadingSaved = false);
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
                _checkAuth();
              },
            ),
      ),
    );
  }

  void _openComments(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(post: post),
    );
  }

  Future<void> _handleLike(Post post) async {
    try {
      if (post.isLikedByMe == true) {
        await _communityService.unlikePost(post.id);
      } else {
        await _communityService.likePost(post.id);
      }

      // Refresh current tab
      _loadTabData(_tabController.index);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isAuthenticated) {
      return _buildNotLoggedIn(isDark);
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              _buildAppBar(isDark),
              SliverToBoxAdapter(child: _buildProfileHeader(isDark)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  tabBar: _buildTabBar(isDark),
                  isDark: isDark,
                ),
              ),
            ],
        body: _buildTabContent(isDark),
      ),
    );
  }

  Widget _buildNotLoggedIn(bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Trang cá nhân'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_crop_circle,
              size: 80,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text('Chưa đăng nhập', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để xem hồ sơ của bạn',
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
                  vertical: 12,
                ),
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.communityCardGradient,
            ),
          ),
        ),
        title: Text(
          'Trang cá nhân',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
            backgroundImage:
                _avatarUrl != null
                    ? CachedNetworkImageProvider(_avatarUrl!)
                    : null,
            child:
                _avatarUrl == null
                    ? Text(
                      (_displayName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            _displayName ?? _userProfile?.name ?? 'Người dùng',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 4),

        ],
      ),
    );
  }

  TabBar _buildTabBar(bool isDark) {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.primaryBlue,
      unselectedLabelColor:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      indicatorColor: AppColors.primaryBlue,
      indicatorWeight: 3,
      tabs: const [
        Tab(text: 'Bài viết'),
        Tab(text: 'Đã thích'),
        Tab(text: 'Đã lưu'),
      ],
    );
  }

  Widget _buildTabContent(bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPostsList(_myPosts, _isLoadingMyPosts, 'Chưa có bài viết nào'),
        _buildPostsList(
          _likedPosts,
          _isLoadingLiked,
          'Chưa thích bài viết nào',
        ),
        _buildPostsList(_savedPosts, _isLoadingSaved, 'Chưa lưu bài viết nào'),
      ],
    );
  }

  Widget _buildPostsList(
    List<Post> posts,
    bool isLoading,
    String emptyMessage,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTabData(_tabController.index),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PostCard(
              post: post,
              onComment: () => _openComments(post),
              onLike: () => _handleLike(post),
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// SLIVER TAB BAR DELEGATE
// ============================================

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate({required this.tabBar, required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || isDark != oldDelegate.isDark;
  }
}
