// Message Model
// Private messages between users
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  // Loaded relations
  final String? senderUsername;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final bool? isMine;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.senderUsername,
    this.senderDisplayName,
    this.senderAvatarUrl,
    this.isMine,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;

    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      readAt:
          json['read_at'] != null
              ? DateTime.parse(json['read_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderUsername: sender?['username'] as String?,
      senderDisplayName: sender?['display_name'] as String?,
      senderAvatarUrl: sender?['avatar_url'] as String?,
      isMine: json['is_mine'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Vừa xong';
    }
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    bool? isMine,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      senderUsername: senderUsername,
      senderDisplayName: senderDisplayName,
      senderAvatarUrl: senderAvatarUrl,
      isMine: isMine ?? this.isMine,
    );
  }
}

// Conversation summary for inbox list
class Conversation {
  final String oderId;
  final String otherUsername;
  final String? otherDisplayName;
  final String? otherAvatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final Message? lastMessage;
  final int unreadCount;

  const Conversation({
    required this.oderId,
    required this.otherUsername,
    this.otherDisplayName,
    this.otherAvatarUrl,
    this.isOnline = false,
    this.lastSeen,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      oderId: json['other_user_id'] as String,
      otherUsername: json['username'] as String,
      otherDisplayName: json['display_name'] as String?,
      otherAvatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen:
          json['last_seen'] != null
              ? DateTime.parse(json['last_seen'] as String)
              : null,
      lastMessage:
          json['last_message'] != null
              ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
              : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
