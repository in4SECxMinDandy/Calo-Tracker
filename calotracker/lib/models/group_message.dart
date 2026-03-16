// Group Message Model
// Messages posted inside a community group chat

import 'package:calotracker/utils/time_formatter.dart';
class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  // Loaded relations
  final String? senderUsername;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final bool? isMine;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderUsername,
    this.senderDisplayName,
    this.senderAvatarUrl,
    this.isMine,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;

    return GroupMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderUsername: sender?['username'] as String?,
      senderDisplayName: sender?['display_name'] as String?,
      senderAvatarUrl: sender?['avatar_url'] as String?,
      isMine: json['is_mine'] as bool?,
    );
  }

  GroupMessage copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    String? senderUsername,
    String? senderDisplayName,
    String? senderAvatarUrl,
    bool? isMine,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      senderUsername: senderUsername ?? this.senderUsername,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      isMine: isMine ?? this.isMine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
    };
  }

  String get timeAgo {
    return formatTimeAgoShort(createdAt);
  }
}
