// Group Detail Screen
// View group info, members, and posts
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/unified_community_service.dart';
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
  final _communityService = UnifiedCommunityService();
  late TabController _tabController;

  CommunityGroup? _group;
  List<Post> _posts = [];
  List<GroupMember> _members = [];
  List<GroupMember> _pendingMembers = [];
  bool _isLoading = true;
  bool _isMember = false;
  bool _isJoining = false;
  bool _isOwner = false;

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

      // Check if current user is a member and owner
      final myGroups = await _communityService.getMyGroups();
      _isOwner = await _communityService.isGroupOwner(widget.groupId);
      _isMember = myGroups.any((g) => g.id == widget.groupId);

      // Load pending members (for owner/admin only)
      if (_isOwner) {
        _pendingMembers = await _communityService.getPendingMembers(widget.groupId);
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

  Future<void> _joinGroup() async {
    setState(() => _isJoining = true);

    try {
      final status = await _communityService.joinGroup(widget.groupId);

      if (mounted) {
        if (status == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(CupertinoIcons.clock, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu tham gia đã được gửi!\nChờ quản trị viên phê duyệt.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() => _isMember = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(CupertinoIcons.checkmark_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Đã tham gia nhóm thành công!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadGroup();
      }
    } catch (e) {
      // Error is handled via SnackBar below
      if (mounted) {
        final errorMsg = _getErrorMessage(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('permission') || errorLower.contains('rls')) {
      return 'Không có quyền tham gia nhóm. Vui lòng đăng nhập lại.';
    }
    if (errorLower.contains('duplicate') || errorLower.contains('already')) {
      // User is already a member - update UI state
      setState(() => _isMember = true);
      return 'Bạn đã là thành viên của nhóm này.';
    }
    if (errorLower.contains('full') || errorLower.contains('max_members')) {
      return 'Nhóm đã đầy. Không thể tham gia.';
    }
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Lỗi kết nối. Vui lòng kiểm tra internet.';
    }

    return 'Không thể tham gia nhóm. Vui lòng thử lại sau.';
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

  /// Show edit group dialog (for owner only)
  void _editGroup() {
    if (_group == null) return;

    final nameController = TextEditingController(text: _group!.name);
    final descController = TextEditingController(
      text: _group!.description ?? '',
    );
    GroupCategory selectedCategory = _group!.category;
    GroupVisibility selectedVisibility = _group!.visibility;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              return Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.pencil_circle_fill,
                            color: AppColors.primaryBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Chỉnh sửa nhóm',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Name field
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên nhóm',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown
                      DropdownButtonFormField<GroupCategory>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items:
                            GroupCategory.values
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat.label),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                setSheetState(() => selectedCategory = val!),
                      ),
                      const SizedBox(height: 16),

                      // Visibility dropdown
                      DropdownButtonFormField<GroupVisibility>(
                        initialValue: selectedVisibility,
                        decoration: InputDecoration(
                          labelText: 'Quyền riêng tư',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items:
                            GroupVisibility.values
                                .map(
                                  (vis) => DropdownMenuItem(
                                    value: vis,
                                    child: Text(
                                      vis == GroupVisibility.public
                                          ? 'Công khai'
                                          : 'Riêng tư',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                setSheetState(() => selectedVisibility = val!),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _saveGroupChanges(
                                  nameController.text.trim(),
                                  descController.text.trim(),
                                  selectedCategory,
                                  selectedVisibility,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Lưu thay đổi'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _saveGroupChanges(
    String name,
    String description,
    GroupCategory category,
    GroupVisibility visibility,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên nhóm không được để trống')),
      );
      return;
    }

    try {
      await _communityService.updateGroup(
        groupId: widget.groupId,
        name: name,
        description: description.isNotEmpty ? description : null,
        category: category,
        visibility: visibility,
      );

      await _loadGroup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật nhóm thành công!'),
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

  /// Delete group (for owner only)
  Future<void> _deleteGroup() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Xóa nhóm'),
            content: Text(
              'Bạn có chắc chắn muốn xóa nhóm "${_group?.name}"?\n\n'
              'Hành động này không thể hoàn tác. Tất cả bài viết và thành viên sẽ bị xóa.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _communityService.deleteGroup(widget.groupId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa nhóm thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa nhóm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                heroTag: 'group_detail_fab',
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
              if (value == 'edit') _editGroup();
              if (value == 'delete') _deleteGroup();
            },
            itemBuilder:
                (context) => [
                  // Show edit/delete options only for owner
                  if (_isOwner) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.pencil, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa nhóm'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.trash, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa nhóm', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                  ],
                  // Leave option for all members (except owner)
                  if (!_isOwner)
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.xmark_circle,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Rời nhóm',
                            style: TextStyle(color: Colors.orange),
                          ),
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
              child: ElevatedButton(
                onPressed: _isJoining ? null : _joinGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryBlue.withValues(
                    alpha: 0.5,
                  ),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shadowColor: AppColors.primaryBlue.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isJoining)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else
                      const Icon(CupertinoIcons.person_badge_plus, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isJoining ? 'Đang tham gia...' : 'Tham gia nhóm',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
        RefreshIndicator(
          onRefresh: _loadGroup,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pending requests section (owner only)
              if (_isOwner && _pendingMembers.isNotEmpty) ...[
                _buildSectionHeader(
                  '⏳ Yêu cầu chờ duyệt (${_pendingMembers.length})',
                  isDark,
                  color: AppColors.warningOrange,
                ),
                const SizedBox(height: 8),
                ..._pendingMembers.map(
                  (m) => _buildPendingMemberItem(m, isDark),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(
                  '👥 Thành viên (${_members.length})',
                  isDark,
                ),
                const SizedBox(height: 8),
              ],
              // Active members
              if (_members.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.person_2,
                          size: 48,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có thành viên',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._members.map((m) => _buildMemberItem(m, isDark)),
            ],
          ),
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

  Widget _buildSectionHeader(String title, bool isDark, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color ??
            (isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
      ),
    );
  }

  Widget _buildPendingMemberItem(GroupMember member, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.person,
              color: AppColors.warningOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName ?? member.username ?? 'Người dùng',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Đang chờ phê duyệt',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warningOrange,
                  ),
                ),
              ],
            ),
          ),
          // Approve/Reject buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _approveMember(member),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark,
                    size: 16,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _rejectMember(member),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 16,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveMember(GroupMember member) async {
    try {
      await _communityService.approveMember(widget.groupId, member.userId);
      _showSnackBar('✅ Đã chấp nhận ${member.displayName ?? 'thành viên'}');
      _loadGroup();
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  Future<void> _rejectMember(GroupMember member) async {
    try {
      await _communityService.rejectMember(widget.groupId, member.userId);
      _showSnackBar('Đã từ chối ${member.displayName ?? 'thành viên'}');
      _loadGroup();
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  Widget _buildMemberItem(GroupMember member, bool isDark) {
    final canManage = _isOwner && member.role != GroupMemberRole.owner;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: member.role == GroupMemberRole.owner
            ? Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              )
            : null,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: member.avatarUrl != null
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
                const SizedBox(height: 2),
                Container(
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

          // Owner management actions
          if (canManage)
            PopupMenuButton<String>(
              icon: Icon(
                CupertinoIcons.ellipsis,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              onSelected: (value) => _handleMemberAction(value, member),
              itemBuilder: (_) => [
                if (member.role == GroupMemberRole.member)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.arrow_up_circle,
                            color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text('Thăng cấp Admin'),
                      ],
                    ),
                  )
                else if (member.role == GroupMemberRole.admin)
                  const PopupMenuItem(
                    value: 'demote',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.arrow_down_circle,
                            color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text('Hạ cấp thành viên'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'kick',
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.person_badge_minus,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Xóa khỏi nhóm',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleMemberAction(String action, GroupMember member) async {
    try {
      switch (action) {
        case 'promote':
          await _communityService.updateMemberRole(
            widget.groupId,
            member.userId,
            'admin',
          );
          _showSnackBar('✅ Đã thăng cấp ${member.displayName ?? 'thành viên'} lên Admin');
          break;
        case 'demote':
          await _communityService.updateMemberRole(
            widget.groupId,
            member.userId,
            'member',
          );
          _showSnackBar('Đã hạ cấp ${member.displayName ?? 'thành viên'} xuống thành viên');
          break;
        case 'kick':
          final confirm = await showCupertinoDialog<bool>(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Xóa thành viên'),
              content: Text(
                'Bạn có chắc muốn xóa ${member.displayName ?? 'thành viên'} khỏi nhóm?',
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xóa'),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _communityService.removeMember(
              widget.groupId,
              member.userId,
            );
            _showSnackBar('Đã xóa ${member.displayName ?? 'thành viên'} khỏi nhóm');
          }
          break;
      }
      _loadGroup();
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
