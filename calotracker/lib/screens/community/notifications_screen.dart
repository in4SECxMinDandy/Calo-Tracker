// Notifications Screen
// View and manage in-app notifications
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/community_service.dart';
import '../../models/app_notification.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _communityService = CommunityService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _communityService.getNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    await _communityService.markAllNotificationsRead();
    _loadNotifications();
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (!notification.isRead) {
      await _communityService.markNotificationRead(notification.id);
    }

    // Navigate based on notification type
    _handleNotificationTap(notification);
  }

  void _handleNotificationTap(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.mention:
        if (notification.relatedPostId != null) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => PostDetailScreen(
                postId: notification.relatedPostId!,
              ),
            ),
          );
        }
        break;
      case NotificationType.follow:
        if (notification.actorId != null) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => UserProfileScreen(userId: notification.actorId!),
            ),
          );
        }
        break;
      default:
        break;
    }

    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        title: const Text('Thông báo'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(
                      _notifications[index],
                      isDark,
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.bell_slash,
            size: 64,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text('Không có thông báo', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Bạn sẽ nhận thông báo khi có hoạt động mới',
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification, bool isDark) {
    return GlassCard(
      onTap: () => _markAsRead(notification),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor avatar or icon
          Stack(
            children: [
              if (notification.actorAvatarUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: notification.actorAvatarUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => Container(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        ),
                    errorWidget:
                        (_, __, ___) => Container(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          child: const Icon(CupertinoIcons.person),
                        ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.type.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.type.icon,
                    color: notification.type.color,
                    size: 24,
                  ),
                ),

              // Type badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: notification.type.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    notification.type.icon,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight:
                        notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (notification.body != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.body!,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
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
          ),

          // Unread indicator
          if (!notification.isRead)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
