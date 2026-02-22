// Friends Screen
// Display friends list with online status and friend requests
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;
import '../../services/friends_service.dart';
import '../../services/presence_service.dart';
import '../../models/friendship.dart';
import '../../models/user_presence.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../theme/animated_app_icons.dart';
import '../../widgets/online_indicator.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  final PresenceService _presenceService = PresenceService();
  late TabController _tabController;

  List<Friendship> _friends = [];
  List<FriendRequest> _requests = [];
  Map<String, UserPresence> _presenceMap = {};
  bool _isLoading = true;
  StreamSubscription? _presenceSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _subscribeToRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

        // Load presence for all friends
        if (_friends.isNotEmpty) {
          final friendIds = _friends.map((f) => f.friendId).toList();
          _presenceMap = await _presenceService.getBatchPresence(friendIds);

          // Subscribe to presence updates
          _presenceSubscription?.cancel();
          _presenceSubscription = _presenceService.presenceStream.listen((
            presence,
          ) {
            if (mounted) {
              setState(() {
                _presenceMap[presence.userId] = presence;
              });
            }
          });
          _presenceService.subscribeToPresence(friendIds);

          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _subscribeToRequests() {
    _friendsService.subscribeToFriendRequests((request) {
      if (mounted) {
        setState(() {
          _requests.insert(0, request);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.displayName} đã gửi lời mời kết bạn'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bạn bè'),
                  if (_friends.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildBadge(_friends.length.toString()),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lời mời'),
                  if (_requests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildBadge(_requests.length.toString(), isHighlight: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildFriendsList(), _buildRequestsList()],
              ),
    );
  }

  Widget _buildBadge(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.red : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isHighlight ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedAppIcons.community(
              size: 64,
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              trigger: lucide.AnimationTrigger.onTap,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bạn bè',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Tìm kiếm và kết bạn với những người dùng khác',
              style: AppTextStyles.caption.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) => _buildFriendItem(_friends[index]),
      ),
    );
  }

  Widget _buildFriendItem(Friendship friendship) {
    final presence = _presenceMap[friendship.friendId];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openProfile(friendship.friendId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with online indicator
              AvatarWithPresence(
                imageUrl: friendship.friendAvatarUrl,
                displayName: friendship.displayName,
                presence: presence,
                radius: 28,
              ),
              const SizedBox(width: 12),

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendship.displayName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friendship.onlineStatusText,
                      style: AppTextStyles.caption.copyWith(
                        color: friendship.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Message button
              IconButton(
                onPressed: () => _openChat(friendship),
                icon: Icon(CupertinoIcons.chat_bubble, size: 24),
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedAppIcons.bell(
              size: 64,
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              trigger: lucide.AnimationTrigger.onTap,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có lời mời kết bạn',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) => _buildRequestItem(_requests[index]),
      ),
    );
  }

  Widget _buildRequestItem(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              backgroundImage:
                  request.senderAvatarUrl != null
                      ? CachedNetworkImageProvider(request.senderAvatarUrl!)
                      : null,
              child:
                  request.senderAvatarUrl == null
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

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.displayName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã gửi lời mời kết bạn',
                    style: AppTextStyles.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Accept/Reject buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _acceptRequest(request),
                  icon: Icon(CupertinoIcons.check_mark_circled, size: 28),
                  color: Colors.green,
                  tooltip: 'Chấp nhận',
                ),
                IconButton(
                  onPressed: () => _rejectRequest(request),
                  icon: Icon(CupertinoIcons.xmark_circle, size: 28),
                  color: Colors.red,
                  tooltip: 'Từ chối',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    try {
      await _friendsService.acceptFriendRequest(request.id);
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
      await _loadData(); // Reload friends list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chấp nhận lời mời từ ${request.displayName}'),
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

  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      await _friendsService.rejectFriendRequest(request.id);
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối lời mời kết bạn'),
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

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  void _openChat(Friendship friendship) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              otherUserId: friendship.friendId,
              otherUsername: friendship.friendUsername ?? 'user',
              otherDisplayName: friendship.friendDisplayName,
              otherAvatarUrl: friendship.friendAvatarUrl,
            ),
      ),
    );
  }
}
