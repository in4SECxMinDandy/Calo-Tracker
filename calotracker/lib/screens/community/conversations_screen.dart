// Conversations Screen (Inbox)
// List of all conversations with unread indicators
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/messaging_service.dart';
import '../../models/message.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import 'chat_screen.dart';
import 'friends_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessagingService _messagingService = MessagingService();

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  int _totalUnread = 0;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messagingService.unsubscribeFromAllMessages();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _messagingService.getConversations();
      final unreadCount = await _messagingService.getUnreadCount();

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _totalUnread = unreadCount;
          _isLoading = false;
        });
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

  void _subscribeToMessages() {
    _messagingService.subscribeToAllMessages((message) {
      // Reload conversations when new message arrives
      _loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Tin nhắn'),
            if (_totalUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _totalUnread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _openFriends,
            tooltip: 'Bạn bè',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'conversations_fab',
        onPressed: _openFriends,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn',
            style: AppTextStyles.heading3.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Kết bạn và bắt đầu trò chuyện',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openFriends,
            icon: const Icon(Icons.people),
            label: const Text('Tìm bạn bè'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        itemBuilder:
            (context, index) => _buildConversationItem(_conversations[index]),
      ),
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
            backgroundImage:
                conversation.otherAvatarUrl != null
                    ? CachedNetworkImageProvider(conversation.otherAvatarUrl!)
                    : null,
            child:
                conversation.otherAvatarUrl == null
                    ? Text(
                      (conversation.otherDisplayName ??
                              conversation.otherUsername)[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    )
                    : null,
          ),
          // Online indicator
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: conversation.isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherDisplayName ?? conversation.otherUsername,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessage != null)
            Text(
              _formatTime(conversation.lastMessage!.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? AppColors.primaryBlue : Colors.grey,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage?.content ?? '',
              style: TextStyle(
                color: hasUnread ? Colors.white : Colors.grey,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount > 9
                    ? '9+'
                    : conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _openChat(conversation),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}p';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              otherUserId: conversation.oderId,
              otherUsername: conversation.otherUsername,
              otherDisplayName: conversation.otherDisplayName,
              otherAvatarUrl: conversation.otherAvatarUrl,
            ),
      ),
    ).then((_) => _loadConversations());
  }

  void _openFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
  }
}
