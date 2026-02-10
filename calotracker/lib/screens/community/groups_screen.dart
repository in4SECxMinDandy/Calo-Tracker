// Groups Screen
// Browse and explore community groups
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/community_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../models/community_group.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import '../auth/login_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  final GroupCategory? initialCategory;

  const GroupsScreen({super.key, this.initialCategory});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _communityService = CommunityService();
  final _authService = SupabaseAuthService();
  final _searchController = TextEditingController();

  List<CommunityGroup> _groups = [];
  Set<String> _myGroupIds = {};
  bool _isLoading = true;
  GroupCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    try {
      final groups = await _communityService.getPublicGroups(
        category: _selectedCategory,
      );

      // Load user's joined groups to know membership status
      if (_authService.isAuthenticated) {
        final myGroups = await _communityService.getMyGroups();
        _myGroupIds = myGroups.map((g) => g.id).toSet();
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<CommunityGroup> get _filteredGroups {
    if (_searchQuery.isEmpty) return _groups;

    return _groups
        .where(
          (g) =>
              g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (g.description?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  void _openLogin() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => LoginScreen(onLoginSuccess: _loadGroups),
      ),
    );
  }

  Future<void> _joinGroup(CommunityGroup group) async {
    if (!_authService.isAuthenticated) {
      _openLogin();
      return;
    }

    try {
      await _communityService.joinGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tham gia ${group.name}'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        _loadGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tham gia: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showCreateGroupSheet() {
    if (!_authService.isAuthenticated) {
      _openLogin();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _CreateGroupSheet(
            onGroupCreated: (group) {
              setState(() {
                _groups.insert(0, group);
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
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        title: const Text('Nhóm'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: _showCreateGroupSheet,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nhóm...',
                  prefixIcon: const Icon(CupertinoIcons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
          ),

          // Category filter
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(null, 'Tất cả', isDark),
                  ...GroupCategory.values.map(
                    (c) => _buildCategoryChip(c, c.label, isDark),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Groups list
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredGroups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.group,
                      size: 64,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text('Không tìm thấy nhóm', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy tạo nhóm đầu tiên!',
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showCreateGroupSheet,
                      child: const Text('Tạo nhóm'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildGroupCard(_filteredGroups[index], isDark),
                );
              }, childCount: _filteredGroups.length),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    GroupCategory? category,
    String label,
    bool isDark,
  ) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          _loadGroups();
        },
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color:
              isSelected
                  ? AppColors.primaryBlue
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
        ),
      ),
    );
  }

  void _openGroupDetail(CommunityGroup group) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => GroupDetailScreen(
          groupId: group.id,
          initialGroup: group,
        ),
      ),
    ).then((_) => _loadGroups()); // Reload when returning
  }

  Widget _buildGroupCard(CommunityGroup group, bool isDark) {
    final isMember = _myGroupIds.contains(group.id);

    return GestureDetector(
      onTap: () {
        if (isMember) {
          _openGroupDetail(group);
        }
      },
      child: GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Group cover
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      group.category.color,
                      group.category.color.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(group.category.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),

              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!group.isPublic)
                          Icon(
                            group.visibility.icon,
                            size: 16,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.category.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: group.category.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_2,
                          size: 14,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} thành viên',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          CupertinoIcons.doc_text,
                          size: 14,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.postCount} bài viết',
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
            ],
          ),

          if (group.description != null) ...[
            const SizedBox(height: 12),
            Text(
              group.description!,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: isMember
                ? ElevatedButton.icon(
                    onPressed: () => _openGroupDetail(group),
                    icon: const Icon(CupertinoIcons.arrow_right_circle, size: 18),
                    label: const Text('Vào nhóm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _joinGroup(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: group.category.color,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      group.requireApproval ? 'Yêu cầu tham gia' : 'Tham gia',
                    ),
                  ),
          ),
        ],
      ),
    ),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  final Function(CommunityGroup) onGroupCreated;

  const _CreateGroupSheet({required this.onGroupCreated});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _communityService = CommunityService();

  GroupCategory _category = GroupCategory.general;
  GroupVisibility _visibility = GroupVisibility.public;
  bool _requireApproval = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final group = await _communityService.createGroup(
        name: _nameController.text.trim(),
        slug: _generateSlug(_nameController.text),
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        category: _category,
        visibility: _visibility,
        requireApproval: _requireApproval,
      );

      widget.onGroupCreated(group);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo nhóm thành công!'),
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
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tạo nhóm mới', style: AppTextStyles.heading2),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Group name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên nhóm *',
                  hintText: 'VD: Giảm cân 30 ngày',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên nhóm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả ngắn về nhóm...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Text(
                'Danh mục',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    GroupCategory.values.map((c) {
                      final isSelected = _category == c;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.icon,
                              size: 16,
                              color: isSelected ? Colors.white : c.color,
                            ),
                            const SizedBox(width: 4),
                            Text(c.label),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: c.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Visibility
              Text(
                'Quyền riêng tư',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...GroupVisibility.values.map((v) {
                return RadioListTile<GroupVisibility>(
                  title: Row(
                    children: [
                      Icon(v.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(v.label),
                    ],
                  ),
                  value: v,
                  // ignore: deprecated_member_use
                  groupValue: _visibility,
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => _visibility = val!),
                  contentPadding: EdgeInsets.zero,
                );
              }),

              // Require approval
              SwitchListTile(
                title: const Text('Yêu cầu phê duyệt thành viên'),
                value: _requireApproval,
                onChanged: (val) => setState(() => _requireApproval = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
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
                          : const Text('Tạo nhóm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
