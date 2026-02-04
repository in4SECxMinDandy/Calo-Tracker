// Group Detail Screen
// View group info, members, and posts
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/community_service.dart';
import '../../models/community_group.dart';
import '../../models/post.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final CommunityGroup? initialGroup;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.initialGroup,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  late TabController _tabController;

  CommunityGroup? _group;
  List<Post> _posts = [];
  List<GroupMember> _members = [];
  bool _isLoading = true;
  bool _isMember = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _group = widget.initialGroup;
    _loadGroup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);

    try {
      // Load group details
      final group = await _communityService.getGroup(widget.groupId);
      if (group != null) {
        _group = group;
      }

      // Load posts
      _posts = await _communityService.getGroupPosts(widget.groupId);

      // Load members
      _members = await _communityService.getGroupMembers(widget.groupId);

      // Check if current user is a member
      final myGroups = await _communityService.getMyGroups();
      _isMember = myGroups.any((g) => g.id == widget.groupId);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinGroup() async {
    setState(() => _isJoining = true);

    try {
      await _communityService.joinGroup(widget.groupId);
      setState(() => _isMember = true);
      _loadGroup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tham gia nhóm!'),
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
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Rời nhóm'),
            content: const Text('Bạn có chắc muốn rời khỏi nhóm này?'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Rời nhóm'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _communityService.leaveGroup(widget.groupId);
      setState(() => _isMember = false);
      _loadGroup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã rời khỏi nhóm'),
            backgroundColor: Colors.orange,
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

  void _createPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CreatePostSheet(
            groupId: widget.groupId,
            onPostCreated: (post) {
              setState(() {
                _posts.insert(0, post);
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
      body:
          _isLoading && _group == null
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  _buildAppBar(isDark),
                  SliverToBoxAdapter(child: _buildGroupInfo(isDark)),
                  SliverToBoxAdapter(child: _buildTabBar(isDark)),
                  SliverFillRemaining(child: _buildTabContent(isDark)),
                ],
              ),
      floatingActionButton:
          _isMember
              ? FloatingActionButton.extended(
                onPressed: _createPost,
                icon: const Icon(CupertinoIcons.pencil),
                label: const Text('Đăng bài'),
                backgroundColor: AppColors.primaryBlue,
              )
              : null,
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _group?.name ?? 'Nhóm',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        background:
            _group?.coverImageUrl != null
                ? CachedNetworkImage(
                  imageUrl: _group!.coverImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildCoverPlaceholder(),
                  errorWidget: (_, __, ___) => _buildCoverPlaceholder(),
                )
                : _buildCoverPlaceholder(),
      ),
      actions: [
        if (_isMember)
          PopupMenuButton<String>(
            icon: const Icon(CupertinoIcons.ellipsis, color: Colors.white),
            onSelected: (value) {
              if (value == 'leave') _leaveGroup();
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.xmark_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Rời nhóm', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
      ],
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              _group?.category.color != null
                  ? [
                    _group!.category.color,
                    _group!.category.color.withValues(alpha: 0.7),
                  ]
                  : AppColors.communityCardGradient,
        ),
      ),
      child: Center(
        child: Icon(
          _group?.category.icon ?? CupertinoIcons.person_3,
          size: 64,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildGroupInfo(bool isDark) {
    if (_group == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and visibility
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _group!.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _group!.category.icon,
                      size: 14,
                      color: _group!.category.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _group!.category.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: _group!.category.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _group!.visibility.icon,
                size: 16,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _group!.visibility.label,
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
          const SizedBox(height: 12),

          // Description
          if (_group!.description != null &&
              _group!.description!.isNotEmpty) ...[
            Text(
              _group!.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Stats row
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  '${_group!.memberCount}',
                  'Thành viên',
                  CupertinoIcons.person_2_fill,
                ),
                _buildStatDivider(isDark),
                _buildStatItem(
                  '${_posts.length}',
                  'Bài viết',
                  CupertinoIcons.doc_text_fill,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Join/Leave button
          if (!_isMember)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isJoining ? null : _joinGroup,
                icon:
                    _isJoining
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(CupertinoIcons.person_badge_plus),
                label: Text(_isJoining ? 'Đang tham gia...' : 'Tham gia nhóm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(value, style: AppTextStyles.heading3),
          ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor:
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
        ),
        tabs: const [
          Tab(text: 'Bài viết'),
          Tab(text: 'Thành viên'),
          Tab(text: 'Giới thiệu'),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Posts tab
        _posts.isEmpty
            ? _buildEmptyTab(
              'Chưa có bài viết nào',
              CupertinoIcons.doc_text,
              isDark,
            )
            : RefreshIndicator(
              onRefresh: _loadGroup,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: _posts[index]);
                },
              ),
            ),

        // Members tab
        _members.isEmpty
            ? _buildEmptyTab(
              'Chưa có thành viên',
              CupertinoIcons.person_2,
              isDark,
            )
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                return _buildMemberItem(_members[index], isDark);
              },
            ),

        // About tab
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin nhóm', style: AppTextStyles.heading3),
                    const SizedBox(height: 16),
                    _buildInfoRow('Danh mục', _group?.category.label ?? ''),
                    _buildInfoRow(
                      'Quyền riêng tư',
                      _group?.visibility.label ?? '',
                    ),
                    _buildInfoRow(
                      'Số thành viên',
                      '${_group?.memberCount ?? 0}',
                    ),
                    if (_group?.maxMembers != null)
                      _buildInfoRow('Giới hạn', '${_group!.maxMembers} người'),
                    _buildInfoRow('Ngày tạo', _formatDate(_group?.createdAt)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTab(String message, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
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

  Widget _buildMemberItem(GroupMember member, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child:
                member.avatarUrl != null
                    ? CachedNetworkImage(
                      imageUrl: member.avatarUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person,
                        color: AppColors.primaryBlue,
                      ),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName ?? member.username ?? 'Thành viên',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (member.role != GroupMemberRole.member)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: member.role.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      member.role.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: member.role.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
