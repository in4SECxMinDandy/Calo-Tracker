// Group Chat Screen
// Demo group chat for community groups
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/group_chat_service.dart';
import '../../models/group_message.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/time_formatter.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupCoverUrl;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupCoverUrl,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final GroupChatService _chatService = GroupChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<GroupMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.unsubscribeFromGroup(widget.groupId);
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _chatService.getMessages(widget.groupId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
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
    _chatService.subscribeToGroup(widget.groupId).listen((message) {
      if (!mounted) return;

      final existingIndex = _messages.indexWhere((m) => m.id == message.id);
      setState(() {
        if (existingIndex >= 0) {
          _messages[existingIndex] = message;
        } else {
          _messages.add(message);
        }
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        groupId: widget.groupId,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        _messageController.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
            backgroundImage:
                widget.groupCoverUrl != null
                    ? CachedNetworkImageProvider(widget.groupCoverUrl!)
                    : null,
            child:
                widget.groupCoverUrl == null
                    ? Text(
                      widget.groupName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Group Chat (Demo)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn trong nhóm',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy bắt đầu trò chuyện với mọi người',
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.isMine ?? false;

        final showDate =
            index == 0 ||
            !_isSameDay(_messages[index - 1].createdAt, message.createdAt);

        return Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            _buildMessageBubble(message, isMine),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = toLocalTime(a);
    final localB = toLocalTime(b);
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formatChatHeader(date),
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage message, bool isMine) {
    final senderLabel = message.senderDisplayName ?? message.senderUsername;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine && senderLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Text(
                senderLabel,
                style: AppTextStyles.caption.copyWith(color: Colors.grey),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color:
                  isMine ? AppColors.primaryBlue : Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : null,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatHHmm(message.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon:
                  _isSending
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                      : Icon(
                        CupertinoIcons.paperplane_fill,
                        color: Colors.white,
                        size: 20,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
