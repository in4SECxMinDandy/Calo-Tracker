// User Profile Screen
// View and edit community profile
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/community_service.dart';
import '../../services/friends_service.dart';
import '../../models/community_profile.dart';
import '../../models/post.dart';
import '../../models/friendship.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import 'widgets/post_card.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;

  const UserProfileScreen({super.key, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = SupabaseAuthService();
  final _communityService = CommunityService();
  final _friendsService = FriendsService();
  final _imagePicker = ImagePicker();

  late TabController _tabController;
  CommunityProfile? _profile;
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isOwnProfile = false;
  FriendshipStatus? _friendshipStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = _authService.currentUser?.id;
      final targetUserId = widget.userId ?? currentUserId;

      if (targetUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      _isOwnProfile = currentUserId == targetUserId;

      // Load profile
      final profile = await _authService.getProfile();
      if (profile != null) {
        _profile = CommunityProfile.fromJson(profile);
      }

      // Load posts
      _posts = await _communityService.getUserPosts(targetUserId);

      // Check if following
      if (!_isOwnProfile && currentUserId != null) {
        _isFollowing = await _communityService.isFollowing(targetUserId);
        _friendshipStatus = await _friendsService.getFriendshipStatus(
          targetUserId,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;

    if (_isFollowing) {
      await _communityService.unfollowUser(widget.userId!);
    } else {
      await _communityService.followUser(widget.userId!);
    }

    setState(() => _isFollowing = !_isFollowing);
    _loadProfile();
  }

  Future<void> _changeAvatar() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    try {
      await _authService.updateAvatar(File(image.path));
      _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (_profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _EditProfileSheet(profile: _profile!, onSaved: _loadProfile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profile == null
              ? _buildNotLoggedIn(isDark)
              : CustomScrollView(
                slivers: [
                  _buildAppBar(isDark),
                  SliverToBoxAdapter(child: _buildProfileHeader(isDark)),
                  SliverToBoxAdapter(child: _buildStats(isDark)),
                  SliverToBoxAdapter(child: _buildTabBar(isDark)),
                  SliverFillRemaining(child: _buildTabContent(isDark)),
                ],
              ),
    );
  }

  Widget _buildNotLoggedIn(bool isDark) {
    return Center(
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
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
      ),
      actions: [
        if (_isOwnProfile)
          IconButton(
            icon: const Icon(CupertinoIcons.gear, color: Colors.white),
            onPressed: _editProfile,
          ),
      ],
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      width: 4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child:
                        _profile?.avatarUrl != null
                            ? CachedNetworkImage(
                              imageUrl: _profile!.avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _buildAvatarPlaceholder(),
                              errorWidget:
                                  (_, __, ___) => _buildAvatarPlaceholder(),
                            )
                            : _buildAvatarPlaceholder(),
                  ),
                ),
                if (_isOwnProfile)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _changeAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.camera,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Name and username
            Text(
              _profile?.displayName ?? 'Người dùng',
              style: AppTextStyles.heading2,
            ),
            if (_profile?.username != null)
              Text(
                '@${_profile!.username}',
                style: TextStyle(
                  fontSize: 15,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
              ),
            const SizedBox(height: 8),

            // Bio
            if (_profile?.bio != null && _profile!.bio!.isNotEmpty)
              Text(
                _profile!.bio!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),

            // Level badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.communityCardGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${_profile?.level ?? 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_profile?.totalPoints ?? 0} điểm',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            if (!_isOwnProfile) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isFriend = _friendshipStatus == FriendshipStatus.accepted;
    final isPending = _friendshipStatus == FriendshipStatus.pending;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Follow/Unfollow button
        ElevatedButton.icon(
          onPressed: _toggleFollow,
          icon: Icon(
            _isFollowing
                ? CupertinoIcons.person_badge_minus
                : CupertinoIcons.person_badge_plus,
          ),
          label: Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFollowing ? Colors.grey : AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),

        // Friend button
        if (isFriend)
          ElevatedButton.icon(
            onPressed: _openChat,
            icon: const Icon(CupertinoIcons.chat_bubble_fill),
            label: const Text('Nhắn tin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          )
        else if (isPending)
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(CupertinoIcons.clock),
            label: const Text('Đã gửi lời mời'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _sendFriendRequest,
            icon: const Icon(CupertinoIcons.person_add_solid),
            label: const Text('Kết bạn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Future<void> _sendFriendRequest() async {
    if (widget.userId == null) return;

    try {
      await _friendsService.sendFriendRequest(widget.userId!);
      setState(() => _friendshipStatus = FriendshipStatus.pending);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lời mời kết bạn'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _openChat() {
    if (_profile == null || widget.userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              otherUserId: widget.userId!,
              otherUsername: _profile?.username ?? 'user',
              otherDisplayName: _profile?.displayName,
              otherAvatarUrl: _profile?.avatarUrl,
            ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        CupertinoIcons.person_fill,
        size: 50,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('${_posts.length}', 'Bài viết'),
              _buildStatDivider(isDark),
              _buildStatItem(
                '${_profile?.followersCount ?? 0}',
                'Người theo dõi',
              ),
              _buildStatDivider(isDark),
              _buildStatItem(
                '${_profile?.followingCount ?? 0}',
                'Đang theo dõi',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor:
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
          ),
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.square_grid_2x2)),
            Tab(icon: Icon(CupertinoIcons.heart_fill)),
            Tab(icon: Icon(CupertinoIcons.bookmark_fill)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Posts tab
        _posts.isEmpty
            ? _buildEmptyTab('Chưa có bài viết nào', CupertinoIcons.doc_text)
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: _posts[index]);
              },
            ),

        // Likes tab (placeholder)
        _buildEmptyTab('Bài viết đã thích', CupertinoIcons.heart),

        // Saved tab (placeholder)
        _buildEmptyTab('Bài viết đã lưu', CupertinoIcons.bookmark),
      ],
    );
  }

  Widget _buildEmptyTab(String message, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
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
}

// Edit Profile Bottom Sheet
class _EditProfileSheet extends StatefulWidget {
  final CommunityProfile profile;
  final VoidCallback onSaved;

  const _EditProfileSheet({required this.profile, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _authService = SupabaseAuthService();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      await _authService.updateProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hồ sơ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text('Chỉnh sửa hồ sơ', style: AppTextStyles.heading3),
          const SizedBox(height: 24),

          // Display name
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: 'Tên hiển thị',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bio
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Tiểu sử',
              hintText: 'Viết đôi dòng về bản thân...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                      : const Text('Lưu thay đổi'),
            ),
          ),
        ],
      ),
    );
  }
}
