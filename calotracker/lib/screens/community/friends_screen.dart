// Friends Screen - Complete Redesign
// Modern social features with friend management, suggestions, and online status
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/friends_service.dart';
import '../../services/presence_service.dart';
import '../../models/friendship.dart';
import '../../models/user_presence.dart';
import '../../theme/colors.dart';
import '../../widgets/online_indicator.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  final PresenceService _presenceService = PresenceService();
  late TabController _tabController;

  List<Friendship> _friends = [];
  List<FriendRequest> _requests = [];
  Map<String, UserPresence> _presenceMap = {};
  bool _isLoading = true;
  int _selectedTab = 0;
  StreamSubscription? _presenceSubscription;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    _loadData();
    _subscribeToRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _friendsService.unsubscribeFromFriendRequests();
    _presenceSubscription?.cancel();
    _presenceService.unsubscribeFromPresence();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendsService.getFriends();
      final requests = await _friendsService.getPendingRequests();

      if (mounted) {
        setState(() {
          _friends = friends;
          _requests = requests;
          _isLoading = false;
        });

        if (_friends.isNotEmpty) {
          final friendIds = _friends.map((f) => f.friendId).toList();
          _presenceMap = await _presenceService.getBatchPresence(friendIds);

          _presenceSubscription?.cancel();
          _presenceSubscription = _presenceService.presenceStream.listen(
            (presence) {
              if (mounted) {
                setState(() => _presenceMap[presence.userId] = presence);
              }
            },
          );
          _presenceService.subscribeToPresence(friendIds);
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Lỗi: $e', isError: true);
      }
    }
  }

  void _subscribeToRequests() {
    _friendsService.subscribeToFriendRequests((request) {
      if (mounted) {
        setState(() => _requests.insert(0, request));
        _showSnackBar('${request.displayName} đã gửi lời mời kết bạn');
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<Friendship> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends.where((f) {
      final name = f.displayName.toLowerCase();
      final username = (f.friendUsername ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          username.contains(_searchQuery.toLowerCase());
    }).toList();
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
            // Header
            _buildHeader(isDark),

            // Tab Bar
            _buildTabBar(isDark),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 0
                      ? _buildFriendsTab(isDark)
                      : _buildRequestsTab(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final onlineFriends = _friends.where((f) {
      final presence = _presenceMap[f.friendId];
      return presence?.isOnline ?? false;
    }).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.back,
                    size: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn bè',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${_friends.length} bạn bè • $onlineFriends đang online',
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
              // Requests badge
              if (_requests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_requests.length} lời mời',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 48,
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Row(
        children: [
          _buildTabItem('Bạn bè', 0, _friends.length, isDark),
          _buildTabItem('Lời mời', 1, _requests.length, isDark,
              isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    String label,
    int index,
    int count,
    bool isDark, {
    bool isHighlight = false,
  }) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _selectedTab = index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primaryBlue : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryBlue
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlight
                        ? AppColors.errorRed
                        : (isActive
                            ? AppColors.primaryBlue
                            : Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: (isHighlight || isActive)
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FRIENDS TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildFriendsTab(bool isDark) {
    final filtered = _filteredFriends;

    if (_friends.isEmpty) {
      return _buildEmptyFriends(isDark);
    }

    // Group by online status
    final onlineFriends = filtered.where((f) {
      final presence = _presenceMap[f.friendId];
      return presence?.isOnline ?? false;
    }).toList();
    final offlineFriends = filtered.where((f) {
      final presence = _presenceMap[f.friendId];
      return !(presence?.isOnline ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Online friends section
          if (onlineFriends.isNotEmpty) ...[
            _buildSectionHeader(
              '🟢 Đang online (${onlineFriends.length})',
              isDark,
            ),
            const SizedBox(height: 8),
            ...onlineFriends.map((f) => _buildFriendCard(f, isDark)),
            const SizedBox(height: 16),
          ],

          // Offline friends section
          if (offlineFriends.isNotEmpty) ...[
            _buildSectionHeader(
              '⚫ Offline (${offlineFriends.length})',
              isDark,
            ),
            const SizedBox(height: 8),
            ...offlineFriends.map((f) => _buildFriendCard(f, isDark)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
      ),
    );
  }

  Widget _buildFriendCard(Friendship friendship, bool isDark) {
    final presence = _presenceMap[friendship.friendId];
    final isOnline = presence?.isOnline ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) =>
                UserProfileScreen(userId: friendship.friendId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with online indicator
              AvatarWithPresence(
                imageUrl: friendship.friendAvatarUrl,
                displayName: friendship.displayName,
                presence: presence,
                radius: 26,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendship.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.successGreen
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline
                              ? 'Đang online'
                              : _getLastSeenText(presence),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOnline
                                ? AppColors.successGreen
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message button
                  GestureDetector(
                    onTap: () => _openChat(friendship),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.chat_bubble_fill,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // More options
                  GestureDetector(
                    onTap: () => _showFriendOptions(friendship, isDark),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.ellipsis,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastSeenText(UserPresence? presence) {
    if (presence == null) return 'Offline';
    return presence.lastSeenText;
  }

  void _showFriendOptions(Friendship friendship, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.person,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                ),
                title: const Text('Xem hồ sơ'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) =>
                          UserProfileScreen(userId: friendship.friendId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_badge_minus,
                    size: 18,
                    color: AppColors.errorRed,
                  ),
                ),
                title: const Text('Hủy kết bạn'),
                onTap: () {
                  Navigator.pop(context);
                  _unfriend(friendship);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unfriend(Friendship friendship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text(
          'Bạn có chắc muốn hủy kết bạn với ${friendship.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Hủy kết bạn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _friendsService.removeFriend(friendship.id);
        setState(() {
          _friends.removeWhere((f) => f.id == friendship.id);
        });
        _showSnackBar('Đã hủy kết bạn với ${friendship.displayName}');
      } catch (e) {
        _showSnackBar('Lỗi: $e', isError: true);
      }
    }
  }

  Widget _buildEmptyFriends(bool isDark) {
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
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.person_2_fill,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có bạn bè',
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
              'Tìm kiếm và kết bạn với những\nngười dùng CaloTracker khác',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // REQUESTS TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildRequestsTab(bool isDark) {
    if (_requests.isEmpty) {
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
                  CupertinoIcons.bell_slash,
                  size: 48,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Không có lời mời kết bạn',
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
                'Khi có người gửi lời mời kết bạn,\nbạn sẽ thấy ở đây',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, index) =>
            _buildRequestCard(_requests[index], isDark),
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
            backgroundImage: request.senderAvatarUrl != null
                ? CachedNetworkImageProvider(request.senderAvatarUrl!)
                : null,
            child: request.senderAvatarUrl == null
                ? Text(
                    request.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đã gửi lời mời kết bạn',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Accept/Reject buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _acceptRequest(request),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Chấp nhận',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _rejectRequest(request),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Từ chối',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
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

  Future<void> _acceptRequest(FriendRequest request) async {
    try {
      HapticFeedback.lightImpact();
      await _friendsService.acceptFriendRequest(request.id);
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      await _loadData();
      if (mounted) {
        _showSnackBar('✅ Đã chấp nhận lời mời từ ${request.displayName}');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      await _friendsService.rejectFriendRequest(request.id);
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      if (mounted) _showSnackBar('Đã từ chối lời mời kết bạn');
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi: $e', isError: true);
    }
  }

  void _openChat(Friendship friendship) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: friendship.friendId,
          otherUsername: friendship.friendUsername ?? 'user',
          otherDisplayName: friendship.friendDisplayName,
          otherAvatarUrl: friendship.friendAvatarUrl,
        ),
      ),
    );
  }
}
